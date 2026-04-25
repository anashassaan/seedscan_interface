// lib/config/views/social/community_plants_view.dart
import 'dart:convert';

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
                      .surfaceContainerHighest
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
                _formatNumber(community.memberCount),
                cs,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                LucideIcons.leaf,
                'Plants',
                _formatNumber(community.plantCount),
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
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                      Flexible(
                        fit: FlexFit.loose,
                        child: Container(
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                                color: cs.surfaceContainerHighest,
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
                                Flexible(
                                  child: Text(
                                    plant.status,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: plant.statusColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                        color: cs.surfaceContainerHighest.withOpacity(0.3),
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

    // Declared OUTSIDE the builder so it is never reset on rebuild
    bool isUpdating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B6E4F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF0B6E4F),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Update Location',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter a name for this location:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  enabled: !isUpdating,
                  decoration: InputDecoration(
                    hintText: 'e.g., Near table, In garden, Under tree',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(Icons.edit_location_alt,
                        color: Color(0xFF0B6E4F)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0B6E4F),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(height: 10),
                // FIX: Flexible prevents overflow of long GPS hint text
                Row(
                  children: [
                    const Icon(Icons.gps_fixed, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'GPS coordinates captured automatically',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                // Loading status line shown while spinner is active
                if (isUpdating) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0B6E4F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Fetching GPS & saving…',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF0B6E4F),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    isUpdating ? null : () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        final locationName = locationController.text.trim();
                        if (locationName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Please enter a location name',
                                      style: GoogleFonts.inter(
                                          color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.orange.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          return;
                        }

                        // Mark as loading — triggers spinner in button + status line
                        setState(() => isUpdating = true);

                        try {
                          final result = await scanController
                              .getLocationWithName(locationName);

                          if (ctx.mounted) {
                            if (result['success'] == true) {
                              // Write to DB (both collections)
                              await communityController.updatePlantLocation(
                                communityId,
                                plant.id,
                                locationName,
                                (result['latitude'] as num).toDouble(),
                                (result['longitude'] as num).toDouble(),
                              );

                              // Sync in-memory for My Garden tab
                              try {
                                scanController.syncPlantLocationLocal(
                                  plant.id,
                                  locationName,
                                  (result['latitude'] as num).toDouble(),
                                  (result['longitude'] as num).toDouble(),
                                );
                              } catch (e) {
                                debugPrint('ScanController sync failed: $e');
                              }

                              // Close dialog then show rich success SnackBar
                              if (ctx.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.white24,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Location Updated!',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                '$locationName  •  ${(result['latitude'] as num).toStringAsFixed(4)}, ${(result['longitude'] as num).toStringAsFixed(4)}',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF0B6E4F),
                                    duration: const Duration(seconds: 4),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                );
                              }
                            } else {
                              // GPS failed — reset button so user can retry
                              setState(() => isUpdating = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.location_off,
                                            color: Colors.white, size: 20),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            result['error'] ??
                                                'Failed to get GPS location',
                                            style: GoogleFonts.inter(
                                                color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setState(() => isUpdating = false);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error: ${e.toString()}',
                                  style:
                                      GoogleFonts.inter(color: Colors.white),
                                ),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B6E4F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF0B6E4F).withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Update',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
              ),
            ],
          );
        },
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
                    Navigator.pop(sheetContext);
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
                    Navigator.pop(sheetContext);
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

/// Uploads [imagePath] to Appwrite Storage and writes an activity-log entry
/// with actionType = 'image_update' so the admin Plant History timeline shows
/// a new dynamic card with the photo, camera icon, timestamp, health, and
/// VERIFIED status badge.
///
/// IMPORTANT: this intentionally does NOT overwrite plant.image_url — the
/// plant's profile image in the card header stays unchanged.
Future<void> _uploadAndLogPlantImage({
  required BuildContext context,
  required String imagePath,
  required CommunityPlant plant,
  required String communityId,
  required CommunityController communityController,
}) async {
  final db = DatabaseService();

  // ── Step 1: Upload photo to Appwrite Storage ─────────────────────────────
  late final String fileId;
  late final String imageUrl;
  try {
    fileId = await db.uploadPlantImage(imagePath);
    // Build a full preview URL — the admin panel uses this to render the image.
    imageUrl = db.getPlantImageUrl(fileId);
  } catch (e) {
    debugPrint('CommunityPlants: upload failed: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to upload image: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  // ── Step 2: Write activity-log entry for admin history timeline ──────────
  // actionType = 'image_update'  →  Admin panel shows:
  //   • Camera icon (🎥) on the timeline dot
  //   • "Image Updated" as the card title
  //   • VERIFIED badge
  //   • Uploaded photo rendered above the card text
  //   • Health + Location metadata below the text
  //
  // NOTE: We do NOT call db.updatePlant() here — profile image stays as-is.
  try {
    if (context.mounted) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final userId = auth.userId ?? '';
      final nowIso = DateTime.now().toIso8601String();

      final historyMeta = jsonEncode({
        'type': 'image_update_meta', // triggers 'image_update' branch in admin
        'updated_at': nowIso,
        'health': plant.status,
        'location': plant.location,
        'latitude': plant.latitude,
        'longitude': plant.longitude,
        'source_plant_id': plant.id,
        'resolved_plant_id': plant.id,
      });

      await db.createActivityLog(
        userId: userId,
        plantId: plant.id, // correct plant doc ID — no fuzzy match
        // 'scan_disease' is used because the Appwrite schema enum only accepts
        // ['water', 'scan_disease', 'register']. The admin history panel
        // detects image-update entries via meta['type'] == 'image_update_meta'
        // (stored in rejectionReason) and overrides the display to show
        // camera icon + "Image Updated" title automatically.
        actionType: 'scan_disease',
        coinsAwarded: 0,
        verificationStatus: 'verified',
        proofImageId:
            imageUrl, // full URL → admin CachedNetworkImage renders it
        rejectionReason: historyMeta,
      );
    }
  } catch (e) {
    debugPrint('CommunityPlants: createActivityLog failed: $e');
    // Non-fatal — the image is safely in Appwrite Storage.
  }

  // ── Step 3: Refresh the in-memory plant card (no profile image change) ───
  // Update in-memory only for visual feedback in the community list; the
  // plant document's image_url field itself is NOT modified.
  communityController.updatePlantImage(communityId, plant.id, imageUrl);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Plant image added to history!', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
    );
  }
}
