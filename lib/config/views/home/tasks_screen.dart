import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/scan_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../../services/database_service.dart';
import '../../../models/custom_task_model.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class PlantTaskInstance {
  final CustomTaskModel task;
  final PlantModel? plant;
  final String uniqueId; // TaskID + PlantID (or TaskID + 'global')

  PlantTaskInstance({required this.task, this.plant})
      : uniqueId =
            plant != null ? '${task.id}_${plant.id}' : '${task.id}_global';
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  List<PlantTaskInstance> _allTasks = [];
  final Set<String> _completedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRealTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRealTasks() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final comm = Provider.of<CommunityController>(context, listen: false);
      final scan = Provider.of<ScanController>(context, listen: false);

      final userId = auth.userId ?? '';

      // 1. Fetch live global tasks from custom_tasks collection
      final broadcasts = await _db.listCustomTasks();

      // 2. Fetch User's Plants
      final myPlants = scan.getMyPlants();
      final myCommunities = comm.getCommunities();

      // 3. Create Plant-Specific Task Instances
      final instances = <PlantTaskInstance>[];

      for (final t in broadcasts) {
        if (t.targetType == 'all') {
          // Global task: Show once regardless of plants
          instances.add(PlantTaskInstance(task: t, plant: null));
        } else if (t.targetType == 'community' && t.targetValue != null) {
          // Community task: Show once if user is in that community
          final isMember = myCommunities.any((c) =>
              c.id == t.targetValue ||
              c.name.toLowerCase() == t.targetValue!.toLowerCase());
          if (isMember) {
            instances.add(PlantTaskInstance(task: t, plant: null));
          }
        } else {
          // Plant-specific or Disease-specific filtering
          final matchedPlants = myPlants.where((p) {
            if (t.targetType == 'disease' && t.targetValue != null) {
              return p.status.toLowerCase() != 'healthy';
            }
            if (t.targetType == 'plant' && t.targetValue != null) {
              return p.name.toLowerCase() == t.targetValue!.toLowerCase() ||
                  p.scientificName.toLowerCase() ==
                      t.targetValue!.toLowerCase();
            }
            return false;
          }).toList();

          for (final p in matchedPlants) {
            instances.add(PlantTaskInstance(task: t, plant: p));
          }
        }
      }

      // 4. Check completion statuses via activity logs
      final logs = await _db.listActivityLogs(queries: []);
      final completedIds = <String>{};

      for (final log in logs) {
        if (log.actionType == 'custom_task_proof' && log.userId == userId) {
          try {
            final meta = jsonDecode(log.rejectionReason ?? '{}');
            if (meta['instance_id'] != null) {
              completedIds.add(meta['instance_id'].toString());
            }
          } catch (e) {}
        }
      }

      if (mounted) {
        setState(() {
          _allTasks = instances;
          // Merge server logs with local session completions to avoid flicker
          _completedTaskIds.addAll(completedIds);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading custom tasks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleTaskCompletion(PlantTaskInstance instance) async {
    if (_completedTaskIds.contains(instance.uniqueId)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Task already completed!'),
          backgroundColor: Colors.orange));
      return;
    }
    await _showTaskVerificationDialog(instance);
  }

  Future<void> _showTaskVerificationDialog(PlantTaskInstance instance) async {
    final task = instance.task;
    final plant = instance.plant;
    final cs = Theme.of(context).colorScheme;

    String? capturedImagePath;
    bool isPhotoTaken = false;
    bool isLocationVerified = false;
    double? currentLat;
    double? currentLng;
    bool isVerifyingLocation = false;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(LucideIcons.clipboardCheck, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Verify Complete',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title,
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(task.description,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: cs.onSurface.withOpacity(0.7))),
                      const SizedBox(height: 8),
                      Text('+${task.points} points',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: cs.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Proof Requirements:',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.primary)),
                const SizedBox(height: 12),

                // 1. Photo Proof
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isPhotoTaken
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isPhotoTaken
                            ? Colors.green
                            : Colors.grey.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                              isPhotoTaken
                                  ? LucideIcons.checkCircle2
                                  : LucideIcons.camera,
                              color: isPhotoTaken ? Colors.green : Colors.grey,
                              size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  '1. Take Photo of ${plant?.name ?? 'Task Target'}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600))),
                        ],
                      ),
                      if (capturedImagePath != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(capturedImagePath!),
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover),
                        ),
                      ],
                      if (!isPhotoTaken) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: OutlinedButton.icon(
                              onPressed: () async {
                                final image = await _picker.pickImage(
                                    source: ImageSource.camera);
                                if (image != null)
                                  setDialogState(() {
                                    capturedImagePath = image.path;
                                    isPhotoTaken = true;
                                  });
                              },
                              icon: const Icon(LucideIcons.camera, size: 16),
                              label: const Text('Camera'),
                            )),
                            const SizedBox(width: 8),
                            Expanded(
                                child: OutlinedButton.icon(
                              onPressed: () async {
                                final image = await _picker.pickImage(
                                    source: ImageSource.gallery);
                                if (image != null)
                                  setDialogState(() {
                                    capturedImagePath = image.path;
                                    isPhotoTaken = true;
                                  });
                              },
                              icon: const Icon(LucideIcons.image, size: 16),
                              label: const Text('Gallery'),
                            )),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // 2. GPS Proof (Only if plant has location)
                if (plant != null && plant.latitude != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLocationVerified
                          ? Colors.green.withOpacity(0.1)
                          : Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isLocationVerified
                              ? Colors.green
                              : Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                                isLocationVerified
                                    ? LucideIcons.mapPin
                                    : LucideIcons.locateFixed,
                                color: isLocationVerified
                                    ? Colors.green
                                    : Colors.amber,
                                size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('2. GPS Verification (2m Radius)',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    'Target: ${plant.latitude!.toStringAsFixed(6)}, ${plant.longitude!.toStringAsFixed(6)}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: cs.onSurface.withOpacity(0.5))),
                              ],
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!isLocationVerified)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0),
                              onPressed: isVerifyingLocation
                                  ? null
                                  : () async {
                                      setDialogState(
                                          () => isVerifyingLocation = true);
                                      final scan = Provider.of<ScanController>(
                                          context,
                                          listen: false);
                                      final pos =
                                          await scan.getCurrentLocation();

                                      if (pos != null) {
                                        final distance =
                                            Geolocator.distanceBetween(
                                                pos.latitude,
                                                pos.longitude,
                                                plant.latitude!,
                                                plant.longitude!);

                                        if (distance <= 2.0) {
                                          setDialogState(() {
                                            isLocationVerified = true;
                                            currentLat = pos.latitude;
                                            currentLng = pos.longitude;
                                            isVerifyingLocation = false;
                                          });
                                        } else {
                                          setDialogState(() =>
                                              isVerifyingLocation = false);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                                'Verification Failed: You are ${distance.toStringAsFixed(1)}m away. Move closer (Target: 2m).'),
                                            backgroundColor: Colors.red,
                                          ));
                                        }
                                      } else {
                                        setDialogState(
                                            () => isVerifyingLocation = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Could not get GPS signal.'),
                                                backgroundColor: Colors.red));
                                      }
                                    },
                              icon: isVerifyingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(LucideIcons.mapPin, size: 16),
                              label: Text(isVerifyingLocation
                                  ? 'Checking GPS...'
                                  : 'Verify Proximity'),
                            ),
                          )
                        else
                          Row(
                            children: [
                              const Icon(LucideIcons.checkCircle2,
                                  color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Text('Location Verified!',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton.icon(
              onPressed: (!isPhotoTaken ||
                      (plant?.latitude != null && !isLocationVerified) ||
                      isSubmitting)
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      try {
                        final auth =
                            Provider.of<AuthController>(context, listen: false);
                        String proofUrl = '';
                        if (capturedImagePath != null) {
                          final fileId =
                              await _db.uploadPlantImage(capturedImagePath!);
                          proofUrl = _db.getPlantImageUrl(fileId);
                        }

                        String resolvedPlantId = 'global';
                        if (plant != null) {
                          resolvedPlantId = await _db.resolveCanonicalPlantId(
                            userId: auth.userId ?? '',
                            localGardenId: plant.id,
                            speciesName: plant.name,
                            latitude: plant.latitude,
                            longitude: plant.longitude,
                          );
                        }

                        final meta = jsonEncode({
                          'type': 'custom_task_proof',
                          'task_id': task.id,
                          'instance_id': instance.uniqueId,
                          'title': task.title,
                          'plant_id': plant?.id ?? 'global',
                          'resolved_plant_id': resolvedPlantId,
                          'plant_name': plant?.name ?? 'Global Task',
                          'user_lat': currentLat,
                          'user_lng': currentLng,
                          'plant_lat': plant?.latitude,
                          'plant_lng': plant?.longitude,
                        });

                        await _db.createActivityLog(
                          userId: auth.userId ?? '',
                          plantId: resolvedPlantId,
                          communityId: plant?.driveId, // Link to the community
                          actionType: 'custom_task_proof',
                          coinsAwarded: task.points,
                          verificationStatus: 'verified',
                          proofImageId: proofUrl,
                          rejectionReason: meta,
                        );

                        Provider.of<WalletController>(context, listen: false)
                            .earnPoints(task.points, 'Missions: ${task.title}');

                        setState(() {
                          _completedTaskIds.add(instance.uniqueId);
                        });
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('Task Verified! +${task.points} Coins'),
                            backgroundColor: Colors.green));
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red));
                      }
                    },
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(LucideIcons.checkCheck, size: 16),
              label: Text(isSubmitting
                  ? 'Uploading Proof...'
                  : 'Complete & Earn +${task.points}'),
            )
          ],
        ),
      ),
    );
  }

  List<PlantTaskInstance> _getFilteredTasks(String category) {
    // Optimization: Filter out completed tasks so they disappear automatically
    return _allTasks.where((ti) {
      final isDone = _completedTaskIds.contains(ti.uniqueId);
      final isMatch = ti.task.category.toLowerCase() == category.toLowerCase();
      return isMatch && !isDone;
    }).toList()
      ..sort((a, b) => b.task.createdAt.compareTo(a.task.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _buildHeader(cs),
          const SizedBox(height: 8),
          _buildTabs(cs),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskList(_getFilteredTasks('daily'), cs),
                      _buildTaskList(_getFilteredTasks('weekly'), cs),
                      _buildTaskList(_getFilteredTasks('monthly'), cs),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onPressed: _loadRealTasks,
        icon: const Icon(LucideIcons.refreshCw, size: 18),
        label: Text('Refresh',
            style:
                GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.chevronLeft),
                style: IconButton.styleFrom(
                    backgroundColor:
                        cs.surfaceContainerHighest.withOpacity(0.5)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Missions & Tasks',
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface)),
                    Text('Earn rewards for plant care',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              Consumer<WalletController>(
                builder: (_, wallet, __) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.coins,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(wallet.points.toString(),
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.amber.shade900)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: cs.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        labelColor: cs.onPrimary,
        unselectedLabelColor: cs.onSurface.withOpacity(0.5),
        labelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Daily'),
          Tab(text: 'Weekly'),
          Tab(text: 'Monthly')
        ],
      ),
    );
  }

  Widget _buildTaskList(List<PlantTaskInstance> instances, ColorScheme cs) {
    final activeInstances = instances
        .where((i) => !_completedTaskIds.contains(i.uniqueId))
        .toList();

    if (activeInstances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(LucideIcons.clipboardList,
                  size: 48, color: cs.primary.withOpacity(0.2)),
            ),
            const SizedBox(height: 20),
            Text('No active missions',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withOpacity(0.7))),
            const SizedBox(height: 8),
            Text('Check back later for new tasks!',
                style: TextStyle(color: cs.onSurface.withOpacity(0.4))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: activeInstances.length,
      itemBuilder: (context, index) {
        final instance = activeInstances[index];
        final task = instance.task;
        final plant = instance.plant;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.onSurface.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleTaskCompletion(instance),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.primary.withOpacity(0.12),
                            cs.primary.withOpacity(0.05)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        LucideIcons.calendarClock,
                        color: cs.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                  plant != null
                                      ? LucideIcons.sprout
                                      : LucideIcons.globe,
                                  size: 12,
                                  color: cs.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                    plant != null
                                        ? '${plant.name} • ${plant.scientificName}'
                                        : 'Global Mission • All Users',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface.withOpacity(0.6)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(LucideIcons.mapPin,
                                  size: 10,
                                  color: cs.onSurface.withOpacity(0.4)),
                              const SizedBox(width: 4),
                              Text(
                                  plant?.latitude != null
                                      ? '${plant!.latitude!.toStringAsFixed(6)}, ${plant.longitude!.toStringAsFixed(6)}'
                                      : 'No location required',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurface.withOpacity(0.4))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade400,
                                Colors.amber.shade600
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.coins,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('+${task.points}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
