import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/scan_controller.dart';
import '../../controllers/wallet_controller.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Task> _tasks = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMockTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMockTasks() {
    _tasks.addAll([
      // Daily Tasks
      Task(
        id: '1',
        title: 'Water the Mango plant',
        description: 'Water thoroughly until soil is moist',
        category: TaskCategory.daily,
        priority: TaskPriority.high,
        dueDate: DateTime.now(),
        isCompleted: false,
        plantName: 'Mango Tree',
        points: 10,
      ),
      Task(
        id: '2',
        title: 'Check soil moisture',
        description: 'Test soil moisture levels for all plants',
        category: TaskCategory.daily,
        priority: TaskPriority.medium,
        dueDate: DateTime.now(),
        isCompleted: false,
        plantName: 'All Plants',
        points: 5,
      ),
      Task(
        id: '3',
        title: 'Scan Golden Pothos',
        description: 'Daily health check using AI scanner',
        category: TaskCategory.daily,
        priority: TaskPriority.low,
        dueDate: DateTime.now(),
        isCompleted: true,
        plantName: 'Golden Pothos',
        points: 15,
      ),
      // Weekly Tasks
      Task(
        id: '4',
        title: 'Fertilize Neem plant',
        description: 'Apply organic fertilizer as per schedule',
        category: TaskCategory.weekly,
        priority: TaskPriority.high,
        dueDate: DateTime.now().add(const Duration(days: 2)),
        isCompleted: false,
        plantName: 'Neem Tree',
        points: 25,
      ),
      Task(
        id: '5',
        title: 'Trim Rose plant',
        description: 'Remove dead leaves and prune overgrowth',
        category: TaskCategory.weekly,
        priority: TaskPriority.medium,
        dueDate: DateTime.now().add(const Duration(days: 3)),
        isCompleted: false,
        plantName: 'Rose Garden',
        points: 20,
      ),
      Task(
        id: '6',
        title: 'Pest inspection',
        description: 'Check all plants for pests and diseases',
        category: TaskCategory.weekly,
        priority: TaskPriority.high,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        isCompleted: true,
        plantName: 'All Plants',
        points: 30,
      ),
      // Monthly Tasks
      Task(
        id: '7',
        title: 'Repot Fiddle Leaf Fig',
        description: 'Transfer to larger pot with fresh soil',
        category: TaskCategory.monthly,
        priority: TaskPriority.high,
        dueDate: DateTime.now().add(const Duration(days: 15)),
        isCompleted: false,
        plantName: 'Fiddle Leaf Fig',
        points: 50,
      ),
      Task(
        id: '8',
        title: 'Deep clean plant area',
        description: 'Clean pots, trays, and surrounding area',
        category: TaskCategory.monthly,
        priority: TaskPriority.low,
        dueDate: DateTime.now().add(const Duration(days: 20)),
        isCompleted: false,
        plantName: 'Garden Area',
        points: 40,
      ),
    ]);
  }

  void _toggleTaskCompletion(Task task) async {
    if (task.isCompleted) {
      // If already completed, just toggle back
      setState(() {
        task.isCompleted = false;
      });
      return;
    }

    // Show verification dialog
    await _showTaskVerificationDialog(task);
  }

  Future<void> _showTaskVerificationDialog(Task task) async {
    final cs = Theme.of(context).colorScheme;
    final scanController = Provider.of<ScanController>(context, listen: false);
    
    // Find the plant associated with this task
    PlantModel? plant;
    try {
      plant = scanController
          .getMyPlants()
          .firstWhere((p) => p.name == task.plantName);
    } catch (e) {
      // If no specific plant found, use first available plant or skip location check
      if (scanController.getMyPlants().isNotEmpty) {
        plant = scanController.getMyPlants().first;
      }
    }

    String? capturedImagePath;
    Position? currentPosition;
    bool isLocationVerified = false;
    bool isPhotoTaken = false;
    bool skipLocationCheck = (plant == null || plant.latitude == null);

    if (skipLocationCheck) {
      isLocationVerified = true; // Auto-verify if no plant location
    }

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
                child: Text(
                  'Complete Task',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${task.plantName} • ${task.points} points',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Requirements Section
                Text(
                  'Requirements for +${task.points} points:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // Location Verification
                if (!skipLocationCheck)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLocationVerified
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLocationVerified ? Colors.green : Colors.grey,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLocationVerified
                              ? LucideIcons.checkCircle2
                              : LucideIcons.mapPin,
                          color:
                              isLocationVerified ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '1. Location Match',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (currentPosition != null)
                                Text(
                                  isLocationVerified
                                      ? 'Location verified ✓'
                                      : 'Location: ${currentPosition!.latitude.toStringAsFixed(4)}, ${currentPosition!.longitude.toStringAsFixed(4)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                )
                              else
                                Text(
                                  'Click to verify location',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!isLocationVerified)
                          TextButton(
                            onPressed: () async {
                              try {
                                final position =
                                    await _getCurrentLocation(context);
                                if (position != null) {
                                  final distance = _calculateDistance(
                                    position.latitude,
                                    position.longitude,
                                    plant?.latitude,
                                    plant?.longitude,
                                  );

                                  setDialogState(() {
                                    currentPosition = position;
                                    // Allow up to 100 meters tolerance
                                    isLocationVerified = distance <= 100;
                                  });

                                  if (!isLocationVerified) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'You are ${distance.toStringAsFixed(0)}m away from the plant. Please get closer (within 100m).',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error getting location: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text('Verify'),
                          ),
                      ],
                    ),
                  ),
                if (!skipLocationCheck) const SizedBox(height: 12),

                // Photo Requirement
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPhotoTaken
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPhotoTaken ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPhotoTaken
                                ? LucideIcons.checkCircle2
                                : LucideIcons.camera,
                            color: isPhotoTaken ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              skipLocationCheck ? '1. Take Photo' : '2. Take Photo',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (capturedImagePath != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(capturedImagePath!),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      if (!isPhotoTaken) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final image = await _picker.pickImage(
                                    source: ImageSource.camera,
                                  );
                                  if (image != null) {
                                    setDialogState(() {
                                      capturedImagePath = image.path;
                                      isPhotoTaken = true;
                                    });
                                  }
                                },
                                icon: const Icon(LucideIcons.camera, size: 16),
                                label: const Text('Camera'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final image = await _picker.pickImage(
                                    source: ImageSource.gallery,
                                  );
                                  if (image != null) {
                                    setDialogState(() {
                                      capturedImagePath = image.path;
                                      isPhotoTaken = true;
                                    });
                                  }
                                },
                                icon: const Icon(LucideIcons.image, size: 16),
                                label: const Text('Gallery'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Caution Message
                if (!isLocationVerified || !isPhotoTaken)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertTriangle,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Complete both requirements to earn +${task.points} points',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            // Skip button (no points)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  task.isCompleted = true;
                });
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${task.title} marked as done (no points)'),
                    backgroundColor: Colors.grey,
                  ),
                );

                // Remove task after a short delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _tasks.removeWhere((t) => t.id == task.id);
                    });
                  }
                });
              },
              icon: const Icon(LucideIcons.skipForward, size: 16),
              label: const Text('Skip (No Points)'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
            ),
            // Complete button (with points)
            ElevatedButton.icon(
              onPressed: (isLocationVerified && isPhotoTaken)
                  ? () {
                      setState(() {
                        task.isCompleted = true;
                      });
                      final wallet =
                          Provider.of<WalletController>(context, listen: false);
                      wallet.earnPoints(task.points, task.title);
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Task completed! +${task.points} points earned 🎉',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Remove task after a short delay
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() {
                            _tasks.removeWhere((t) => t.id == task.id);
                          });
                        }
                      });
                    }
                  : null,
              icon: const Icon(LucideIcons.checkCircle2, size: 16),
              label: Text('Complete (+${task.points} pts)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Position?> _getCurrentLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double? lat2,
    double? lon2,
  ) {
    if (lat2 == null || lon2 == null) {
      return double.infinity; // Cannot verify without plant location
    }
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TaskCategory selectedCategory = TaskCategory.daily;
    TaskPriority selectedPriority = TaskPriority.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(LucideIcons.plus,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Add New Task',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'e.g., Water the plants',
                    prefixIcon: const Icon(LucideIcons.text),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add details...',
                    prefixIcon: const Icon(LucideIcons.fileText),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskCategory>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(LucideIcons.tag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: TaskCategory.values
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(_getCategoryName(cat)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedCategory = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskPriority>(
                  value: selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: const Icon(LucideIcons.flag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: TaskPriority.values
                      .map((pri) => DropdownMenuItem(
                            value: pri,
                            child: Text(_getPriorityName(pri)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedPriority = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a task title',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() {
                  _tasks.add(
                    Task(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      category: selectedCategory,
                      priority: selectedPriority,
                      dueDate: DateTime.now(),
                      isCompleted: false,
                      plantName: 'Custom',
                      points: selectedPriority == TaskPriority.high
                          ? 30
                          : selectedPriority == TaskPriority.medium
                              ? 20
                              : 10,
                    ),
                  );
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Task added successfully!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  List<Task> _getFilteredTasks(TaskCategory category) {
    return _tasks.where((task) => task.category == category).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.dueDate.compareTo(b.dueDate);
      });
  }

  String _getCategoryName(TaskCategory category) {
    switch (category) {
      case TaskCategory.daily:
        return 'Daily';
      case TaskCategory.weekly:
        return 'Weekly';
      case TaskCategory.monthly:
        return 'Monthly';
    }
  }

  String _getPriorityName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low Priority';
      case TaskPriority.medium:
        return 'Medium Priority';
      case TaskPriority.high:
        return 'High Priority';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final totalPoints = _tasks
        .where((t) => t.isCompleted)
        .fold(0, (sum, task) => sum + task.points);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Stats
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0B6E4F),
                      const Color(0xFF159A6E),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.checkSquare,
                              color: Colors.white.withOpacity(0.9),
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'My Tasks',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatsChip(
                                icon: LucideIcons.listTodo,
                                label: 'Total',
                                value: '${_tasks.length}',
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatsChip(
                                icon: LucideIcons.checkCircle,
                                label: 'Done',
                                value: '$completedCount',
                                color: Colors.green.shade300,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatsChip(
                                icon: LucideIcons.award,
                                label: 'Points',
                                value: '$totalPoints',
                                color: Colors.amber.shade300,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: cs.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: cs.primary,
                  unselectedLabelColor: cs.onSurface.withOpacity(0.6),
                  indicatorColor: cs.primary,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Daily'),
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                  ],
                ),
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TasksList(
                  tasks: _getFilteredTasks(TaskCategory.daily),
                  onToggle: _toggleTaskCompletion,
                  emptyMessage: 'No daily tasks yet',
                ),
                _TasksList(
                  tasks: _getFilteredTasks(TaskCategory.weekly),
                  onToggle: _toggleTaskCompletion,
                  emptyMessage: 'No weekly tasks yet',
                ),
                _TasksList(
                  tasks: _getFilteredTasks(TaskCategory.monthly),
                  onToggle: _toggleTaskCompletion,
                  emptyMessage: 'No monthly tasks yet',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const Icon(LucideIcons.plus),
        label: Text(
          'Add Task',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0B6E4F),
      ),
    );
  }
}

// Stats Chip Widget
class _StatsChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatsChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// Tasks List Widget
class _TasksList extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onToggle;
  final String emptyMessage;

  const _TasksList({
    required this.tasks,
    required this.onToggle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.clipboardList,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(
          task: task,
          onToggle: () => onToggle(task),
        );
      },
    );
  }
}

// Task Card Widget
class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;

  const _TaskCard({
    required this.task,
    required this.onToggle,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.blue;
    }
  }

  IconData _getPriorityIcon() {
    switch (task.priority) {
      case TaskPriority.high:
        return LucideIcons.alertCircle;
      case TaskPriority.medium:
        return LucideIcons.alertTriangle;
      case TaskPriority.low:
        return LucideIcons.info;
    }
  }

  String _getTimeRemaining() {
    final now = DateTime.now();
    final difference = task.dueDate.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h left';
    } else {
      return 'Due soon';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final priorityColor = _getPriorityColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: task.isCompleted ? 1 : 3,
      shadowColor: priorityColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: task.isCompleted
              ? cs.outlineVariant.withOpacity(0.5)
              : priorityColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: Icon(
                  task.isCompleted
                      ? LucideIcons.checkCircle2
                      : LucideIcons.circle,
                  color: task.isCompleted ? Colors.green : priorityColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: task.isCompleted
                                  ? cs.onSurface.withOpacity(0.4)
                                  : null,
                              decorationThickness: 2,
                              color: task.isCompleted
                                  ? cs.onSurface.withOpacity(0.4)
                                  : cs.onSurface,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.award,
                                size: 12,
                                color: Colors.amber.shade900,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${task.points}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: task.isCompleted
                              ? cs.onSurface.withOpacity(0.35)
                              : cs.onSurface.withOpacity(0.7),
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: task.isCompleted
                              ? cs.onSurface.withOpacity(0.3)
                              : null,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.leaf,
                              size: 14,
                              color: const Color(0xFF0B6E4F),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.plantName,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0B6E4F),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: priorityColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getPriorityIcon(),
                                size: 13,
                                color: priorityColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getTimeRemaining(),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: priorityColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Data Models
enum TaskCategory { daily, weekly, monthly }

enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime dueDate;
  bool isCompleted;
  final String plantName;
  final int points;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.isCompleted,
    required this.plantName,
    required this.points,
  });
}
