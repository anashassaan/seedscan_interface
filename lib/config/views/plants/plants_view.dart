// lib/views/plants/plants_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/scan_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../../models/community_model.dart';
import '../home/qr_scanner_screen.dart';
import '../social/community_plants_view.dart';
import '../../appwrite_constants.dart';

class PlantsView extends StatefulWidget {
  const PlantsView({super.key});

  @override
  State<PlantsView> createState() => _PlantsViewState();
}

class _PlantsViewState extends State<PlantsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 60),
                title: Text(
                  'My Plants',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    color: cs.onPrimary,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary,
                        cs.primaryContainer,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Icon(
                          LucideIcons.leaf,
                          size: 150,
                          color: cs.onPrimary.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.search),
                  onPressed: () {
                    // TODO: Implement search
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  controller: _tabController,
                  labelColor: cs.onPrimary,
                  unselectedLabelColor: cs.onPrimary.withOpacity(0.6),
                  indicatorColor: cs.onPrimary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(LucideIcons.sprout, size: 20),
                      text: 'My Garden',
                      height: 48,
                    ),
                    Tab(
                      icon: Icon(LucideIcons.users, size: 20),
                      text: 'Community',
                      height: 48,
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: const [
            _MyGardenTab(),
            _CommunityPlantsTab(),
          ],
        ),
      ),
    );
  }
}

// My Garden Tab - Shows user's personal plants
class _MyGardenTab extends StatelessWidget {
  const _MyGardenTab();

  @override
  Widget build(BuildContext context) {
    final scanController = Provider.of<ScanController>(context);
    final plants = scanController.getMyPlants();

    if (plants.isEmpty) {
      return _buildEmptyState(
        context,
        icon: LucideIcons.flower2,
        title: 'No Plants in Your Garden',
        subtitle: 'Start by scanning QR codes\nto add plants to your garden',
        actionLabel: 'Scan QR Code',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QRScannerScreen(),
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plants.length,
      itemBuilder: (context, index) {
        final plant = plants[index];
        return _MyGardenPlantCard(plant: plant);
      },
    );
  }
}

// Community Tab - Shows communities the user has joined
class _CommunityPlantsTab extends StatefulWidget {
  const _CommunityPlantsTab();

  @override
  State<_CommunityPlantsTab> createState() => _CommunityPlantsTabState();
}

class _CommunityPlantsTabState extends State<_CommunityPlantsTab> {
  @override
  void initState() {
    super.initState();
    // Always reload from Appwrite when this tab is shown
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final auth = context.read<AuthController>();
    final ctrl = context.read<CommunityController>();
    final uid = auth.userId ?? '';
    if (uid.isNotEmpty) {
      await ctrl.loadUserCommunities(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final communities = controller.getCommunities();

        if (communities.isEmpty) {
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              children: [
                const SizedBox(height: 80),
                _buildEmptyState(
                  context,
                  icon: LucideIcons.users,
                  title: 'No Communities Yet',
                  subtitle:
                      'Scan a community plant QR code\nto join a community automatically',
                  actionLabel: 'Refresh',
                  onAction: _reload,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return _CommunityCard(community: community);
            },
          ),
        );
      },
    );
  }
}

// Community Card
class _CommunityCard extends StatelessWidget {
  final Community community;

  const _CommunityCard({required this.community});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityPlantsView(community: community),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: community.imageUrl != null
                      ? Image.network(
                          community.imageUrl!,
                          headers: const {
                            'X-Appwrite-Project': AppwriteConstants.projectId
                          },
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 160,
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                LucideIcons.image,
                                size: 64,
                                color: cs.onSurfaceVariant,
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 160,
                          color: cs.surfaceContainerHighest,
                          child: Icon(
                            LucideIcons.users,
                            size: 64,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                ),
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                // Category Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(community.category),
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          community.category,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Community Name
                  Text(
                    community.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    community.description ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatNumber(community.memberCount)} members',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        LucideIcons.leaf,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatNumber(community.plantCount)} plants',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 20,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'education':
      case 'learning':
        return LucideIcons.graduationCap;
      case 'university':
        return LucideIcons.school;
      case 'official':
        return LucideIcons.megaphone;
      case 'urban':
        return LucideIcons.building;
      default:
        return LucideIcons.tag;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

// My Garden Plant Card
class _MyGardenPlantCard extends StatelessWidget {
  final PlantModel plant;

  const _MyGardenPlantCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _showPlantDetails(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                plant.image,
                headers: const {
                  'X-Appwrite-Project': AppwriteConstants.projectId
                },
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        LucideIcons.flower2,
                        size: 60,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.name,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              plant.scientificName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: plant.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          plant.status,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: plant.statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.scanLine,
                        size: 16,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last scanned ${plant.lastScan}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: cs.onSurface.withOpacity(0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlantDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      plant.image,
                      headers: const {
                        'X-Appwrite-Project': AppwriteConstants.projectId
                      },
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              LucideIcons.flower2,
                              size: 60,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    plant.name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    plant.scientificName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: LucideIcons.info,
                          label: 'Status',
                          value: plant.status,
                          color: plant.statusColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoChip(
                          icon: LucideIcons.clock,
                          label: 'Last Scan',
                          value: plant.lastScan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Location Information
                  if (plant.location != null)
                    InkWell(
                      onTap: () async {
                        if (plant.latitude != null && plant.longitude != null) {
                          final url = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${plant.latitude},${plant.longitude}',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not open Google Maps',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Location',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    plant.location!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  if (plant.latitude != null &&
                                      plant.longitude != null)
                                    Text(
                                      'Lat: ${plant.latitude!.toStringAsFixed(4)}, Lng: ${plant.longitude!.toStringAsFixed(4)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to open in Google Maps',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.blue.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.externalLink,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showImageSourcePicker(context, plant);
                    },
                    icon: const Icon(LucideIcons.upload),
                    label: const Text('Update Plant Image'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showLocationInputDialog(context, plant);
                    },
                    icon: const Icon(LucideIcons.mapPin),
                    label: const Text('Update Location'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLocationInputDialog(BuildContext context, PlantModel plant) {
    final TextEditingController locationController = TextEditingController();
    final scanController = Provider.of<ScanController>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Update Location',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a custom location name:',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                hintText: 'e.g., Near table, In garden, Under tree',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'GPS coordinates will be captured automatically',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final locationName = locationController.text.trim();
              if (locationName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter a location name',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              try {
                final result = await scanController.updatePlantLocationWithName(
                  plant.id,
                  locationName,
                );

                if (context.mounted) {
                  if (result['success']) {
                    try {
                      Provider.of<CommunityController>(context, listen: false)
                          .syncPlantLocationLocal(
                        plant.id,
                        locationName,
                        result['latitude'] ?? 0.0,
                        result['longitude'] ?? 0.0,
                      );
                    } catch (e) {
                      debugPrint('Sync to CommunityController failed: $e');
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Location updated successfully!\n$locationName\nLat: ${result['latitude'].toStringAsFixed(4)}, Lng: ${result['longitude'].toStringAsFixed(4)}',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['error'] ?? 'Failed to update location',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString()}',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B6E4F),
            ),
            child: Text(
              'Update',
              style: GoogleFonts.inter(),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourcePicker(BuildContext context, PlantModel plant) {
    final scanController = Provider.of<ScanController>(context, listen: false);
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Update Plant Image',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a source to update the plant image',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _ImageSourceButton(
                        icon: LucideIcons.camera,
                        label: 'Camera',
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 1200,
                            maxHeight: 1200,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            final result = await scanController
                                .updatePlantImage(plant.id, image.path);
                            if (context.mounted) {
                              final now = DateTime.now();
                              final timeStr =
                                  '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['success'] == true
                                        ? 'Plant image updated & saved to database at $timeStr'
                                        : 'Image updated locally (upload failed: ${result['error']})',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: result['success'] == true
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _ImageSourceButton(
                        icon: LucideIcons.image,
                        label: 'Gallery',
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            final result = await scanController
                                .updatePlantImage(plant.id, image.path);
                            if (context.mounted) {
                              final now = DateTime.now();
                              final timeStr =
                                  '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['success'] == true
                                        ? 'Plant image updated & saved to database at $timeStr'
                                        : 'Image updated locally (upload failed: ${result['error']})',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: result['success'] == true
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Image Source Button Widget
class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5F1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF0B6E4F).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B6E4F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B6E4F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Community Plant Card
class _CommunityPlantCard extends StatefulWidget {
  final CommunityPlant plant;

  const _CommunityPlantCard({required this.plant});

  @override
  State<_CommunityPlantCard> createState() => _CommunityPlantCardState();
}

class _CommunityPlantCardState extends State<_CommunityPlantCard> {
  bool _isLiked = false;
  late int _likes;

  @override
  void initState() {
    super.initState();
    _likes = widget.plant.likes;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likes += _isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plant Image
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  widget.plant.imageUrl,
                  headers: const {
                    'X-Appwrite-Project': AppwriteConstants.projectId
                  },
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: cs.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          LucideIcons.flower2,
                          size: 60,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.plant.category,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plant.name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.plant.scientificName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.plant.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(
                        LucideIcons.user,
                        size: 16,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.plant.owner,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 12,
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.plant.location,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: cs.onSurface.withOpacity(0.5),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleLike,
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : cs.onSurface,
                      ),
                    ),
                    Text(
                      '$_likes',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Info Chip Widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chipColor = color ?? cs.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: chipColor, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Empty State Widget
Widget _buildEmptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required String actionLabel,
  required VoidCallback onAction,
}) {
  final cs = Theme.of(context).colorScheme;

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: cs.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(LucideIcons.scanLine),
            label: Text(actionLabel),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Community Plant Model
class CommunityPlant {
  final String id;
  final String name;
  final String scientificName;
  final String owner;
  final String location;
  final String imageUrl;
  final int likes;
  final String category;
  final String description;

  CommunityPlant({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.owner,
    required this.location,
    required this.imageUrl,
    required this.likes,
    required this.category,
    required this.description,
  });
}
