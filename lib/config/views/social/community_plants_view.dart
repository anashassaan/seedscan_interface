// lib/config/views/social/community_plants_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/community_controller.dart';
import '../../controllers/scan_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../models/community_model.dart';
import '../../../services/database_service.dart';
import '../../appwrite_constants.dart';

class CommunityPlantsView extends StatefulWidget {
  final Community community;

  const CommunityPlantsView({super.key, required this.community});

  @override
  State<CommunityPlantsView> createState() => _CommunityPlantsViewState();
}

class _CommunityPlantsViewState extends State<CommunityPlantsView> {
  @override
  void initState() {
    super.initState();
    // Trigger Appwrite fetch every time this screen mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<CommunityController>(context, listen: false)
          .loadCommunityPlantsFromServer(widget.community.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final community = widget.community;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                title: Text(
                  community.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: cs.onPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (community.imageUrl != null)
                      Image.network(
                        community.imageUrl!,
                        headers: const {
                          'X-Appwrite-Project': AppwriteConstants.projectId
                        },
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: cs.primary,
                            child: Icon(
                              LucideIcons.users,
                              size: 80,
                              color: cs.onPrimary.withOpacity(0.3),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: cs.primary,
                        child: Icon(
                          LucideIcons.users,
                          size: 80,
                          color: cs.onPrimary.withOpacity(0.3),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            cs.primary.withOpacity(0.8),
                            cs.primary,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Consumer<CommunityController>(
          builder: (context, communityController, _) {
            final plants = communityController.getCommunityPlants(community.id);

            if (communityController.isLoadingCommunityPlants &&
                plants.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (plants.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => communityController
                    .loadCommunityPlantsFromServer(community.id),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [_buildEmptyState(context)],
                ),
              );
            }

            return Column(
              children: [
                // Community Info Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatNumber(community.memberCount)} members',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        LucideIcons.leaf,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatNumber(plants.length)} plants',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Plants List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => communityController
                        .loadCommunityPlantsFromServer(community.id),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: plants.length,
                      itemBuilder: (context, index) {
                        final plant = plants[index];
                        return _CommunityPlantCard(
                          plant: plant,
                          communityId: community.id,
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'community_plants_fab',
        onPressed: () {
          _showCommunityInfo(context);
        },
        icon: const Icon(LucideIcons.info),
        label: const Text('Community Info'),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.flower2,
              size: 80,
              color: cs.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Plants Yet',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to add a plant to ${widget.community.name}!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _showCommunityInfo(context);
              },
              icon: const Icon(LucideIcons.info),
              label: const Text('Learn More'),
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

  void _showCommunityInfo(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final community = widget.community;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.info, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                community.name,
                style: GoogleFonts.poppins(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                community.description ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: cs.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                LucideIcons.users,
                'Members',
                '${_formatNumber(community.memberCount)}',
                cs,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                LucideIcons.leaf,
                'Plants',
                '${_formatNumber(community.plantCount)}',
                cs,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                LucideIcons.tag,
                'Category',
                community.category,
                cs,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                LucideIcons.calendar,
                'Created',
                DateFormat('MMM dd, yyyy').format(community.createdAt),
                cs,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, ColorScheme cs) {
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// Community Plant Card
class _CommunityPlantCard extends StatelessWidget {
  final CommunityPlant plant;
  final String communityId;

  const _CommunityPlantCard({
    required this.plant,
    required this.communityId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showPlantDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Image
            if (plant.imageUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  plant.imageUrl!,
                  headers: const {
                    'X-Appwrite-Project': AppwriteConstants.projectId
                  },
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: cs.surfaceVariant,
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

            // Content Section
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
                              plant.plantName,
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
                        LucideIcons.mapPin,
                        size: 16,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          plant.location,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Plant Image
                    if (plant.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          plant.imageUrl!,
                          headers: const {
                            'X-Appwrite-Project': AppwriteConstants.projectId
                          },
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: cs.surfaceVariant,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                LucideIcons.leaf,
                                size: 80,
                                color: cs.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Plant Name
                    Text(
                      plant.plantName,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Scientific Name
                    Text(
                      plant.scientificName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Status & Category Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: plant.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: plant.statusColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getStatusIcon(plant.status),
                                  size: 18,
                                  color: plant.statusColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  plant.status,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: plant.statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              plant.category,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onPrimaryContainer,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Location Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 18,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Location',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plant.location,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: cs.onSurface.withOpacity(0.8),
                            ),
                          ),
                          if (plant.latitude != null &&
                              plant.longitude != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openMap(context, plant),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(LucideIcons.navigation,
                                    size: 18),
                                label: Text(
                                  'View on Map',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Description Section
                    if (plant.description != null &&
                        plant.description!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Description',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plant.description!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: cs.onSurface.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Update Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showImageSourcePicker(context, plant);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(LucideIcons.camera, size: 20),
                        label: Text(
                          'Update Plant Image',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showLocationInputDialog(context, plant);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(LucideIcons.mapPin, size: 20),
                        label: Text(
                          'Update Location',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return LucideIcons.checkCircle;
      case 'growing':
        return LucideIcons.trendingUp;
      case 'needs care':
        return LucideIcons.alertCircle;
      case 'flowering':
        return LucideIcons.flower2;
      case 'dormant':
        return LucideIcons.moon;
      default:
        return LucideIcons.leaf;
    }
  }

  void _openMap(BuildContext context, CommunityPlant plant) async {
    if (plant.latitude != null && plant.longitude != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${plant.latitude},${plant.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showLocationInputDialog(BuildContext context, CommunityPlant plant) {
    final TextEditingController locationController = TextEditingController();
    final communityController =
        Provider.of<CommunityController>(context, listen: false);
    final scanController = Provider.of<ScanController>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
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

              Navigator.pop(context);

              try {
                // Use ScanController's helper method to get location with GPS
                final result =
                    await scanController.getLocationWithName(locationName);

                if (context.mounted) {
                  if (result['success']) {
                    // Update plant location in community
                    communityController.updatePlantLocation(
                      communityId,
                      plant.id,
                      locationName,
                      result['latitude'],
                      result['longitude'],
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Location updated successfully!\n$locationName\nLat: ${result['latitude'].toStringAsFixed(4)}, Lng: ${result['longitude'].toStringAsFixed(4)}',
                          style: GoogleFonts.inter(),
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
                          style: GoogleFonts.inter(),
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
                        style: GoogleFonts.inter(),
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

  void _showImageSourcePicker(BuildContext context, CommunityPlant plant) {
    final communityController =
        Provider.of<CommunityController>(context, listen: false);
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
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
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    LucideIcons.image,
                    color: Color(0xFF0B6E4F),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      await _uploadAndLogPlantImage(
                        context: context,
                        imagePath: image.path,
                        plant: plant,
                        communityId: communityId,
                        communityController: communityController,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    LucideIcons.camera,
                    color: Color(0xFF0B6E4F),
                  ),
                  title: Text(
                    'Take Photo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      await _uploadAndLogPlantImage(
                        context: context,
                        imagePath: image.path,
                        plant: plant,
                        communityId: communityId,
                        communityController: communityController,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Uploads [imagePath] to Appwrite Storage, updates the plant document's
/// image_url, creates an activity_log entry so admin history is populated,
/// then refreshes the in-memory community plant list.
Future<void> _uploadAndLogPlantImage({
  required BuildContext context,
  required String imagePath,
  required CommunityPlant plant,
  required String communityId,
  required CommunityController communityController,
}) async {
  try {
    final db = DatabaseService();
    final fileId = await db.uploadPlantImage(imagePath);
    final imageUrl = db.getPlantImageUrl(fileId);

    // 1. Optimistically update in-memory list so the card refreshes immediately.
    communityController.updatePlantImage(communityId, plant.id, imageUrl);

    // 2. Persist updated image URL on the plant document in Appwrite.
    try {
      await db.updatePlant(plant.id, {'image_url': imageUrl});
    } catch (e) {
      debugPrint('CommunityPlants: updatePlant image_url failed: $e');
    }

    // 3. Write an activity log so the admin history timeline shows this change.
    try {
      if (context.mounted) {
        final auth = Provider.of<AuthController>(context, listen: false);
        await db.createActivityLog(
          userId: auth.userId ?? '',
          plantId: plant.id,
          actionType: 'image_update',
          coinsAwarded: 0,
          verificationStatus: 'verified',
          proofImageId: fileId,
        );
      }
    } catch (e) {
      debugPrint('CommunityPlants: createActivityLog failed: $e');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plant image updated successfully!',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    debugPrint('CommunityPlants: uploadPlantImage failed: $e');
    // Fall back to showing the local file path so the card still updates.
    communityController.updatePlantImage(communityId, plant.id, imagePath);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image saved locally.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
