import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/plant_model.dart';
import '../../../models/transaction_model.dart';
import '../../../config/appwrite_constants.dart';
import '../../controllers/admin_controller.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PlantDetailAdminView extends StatefulWidget {
  final PlantModel plant;

  const PlantDetailAdminView({
    Key? key,
    required this.plant,
  }) : super(key: key);

  @override
  State<PlantDetailAdminView> createState() => _PlantDetailAdminViewState();
}

class _PlantDetailAdminViewState extends State<PlantDetailAdminView> {
  bool _isLoading = true;
  List<ActivityLog> _logs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final admin = Provider.of<AdminController>(context, listen: false);
      final logs = await admin.getPlantHistoryLogs(widget.plant.id);

      if (mounted) {
        setState(() {
          // Sort newest to oldest so we see the latest picture at top
          _logs = logs..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load history: \$e";
          _isLoading = false;
        });
      }
    }
  }

  Color _getHealthColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'diseased':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      case 'dead':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  /// Converts a proof image ID to a displayable URL.
  /// If it's already an HTTP URL it's returned as-is;
  /// otherwise it's treated as an Appwrite storage file ID.
  String _proofImageUrl(String proofImageId) {
    if (proofImageId.isEmpty) return '';
    if (proofImageId.startsWith('http')) return proofImageId;
    return '${AppwriteConstants.endpoint}/storage/buckets/'
        '${AppwriteConstants.plantImagesBucket}/files/$proofImageId/preview'
        '?project=${AppwriteConstants.projectId}&width=800';
  }

  Map<String, dynamic>? _historyMeta(ActivityLog log) {
    final raw = log.rejectionReason;
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plant = widget.plant;
    final hasLocation = plant.locationLat != 0.0 || plant.locationLong != 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.nickname ?? plant.species),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHistory,
            tooltip: 'Refresh history',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.alertCircle, size: 48, color: cs.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: cs.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchHistory,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Plant Info Card ───────────────────────────
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: cs.primaryContainer,
                                        backgroundImage:
                                            plant.imageUrl.isNotEmpty
                                                ? CachedNetworkImageProvider(
                                                    plant.imageUrl)
                                                : null,
                                        child: plant.imageUrl.isEmpty
                                            ? Icon(LucideIcons.leaf,
                                                color: cs.onPrimaryContainer)
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plant.species,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            if (plant.nickname != null &&
                                                plant.nickname!.isNotEmpty)
                                              Text(
                                                plant.nickname!,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: cs.onSurface
                                                        .withOpacity(0.6)),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _getHealthColor(
                                                  plant.healthStatus)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          plant.healthStatus.toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: _getHealthColor(
                                                plant.healthStatus),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Location row
                                  if (hasLocation) ...[
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(LucideIcons.mapPin,
                                            size: 16,
                                            color:
                                                cs.onSurface.withOpacity(0.5)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${plant.locationLat.toStringAsFixed(5)}, '
                                            '${plant.locationLong.toStringAsFixed(5)}',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: cs.onSurface
                                                    .withOpacity(0.7)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (plant.lastWatered != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(LucideIcons.droplets,
                                            size: 16,
                                            color:
                                                cs.onSurface.withOpacity(0.5)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Last watered: ${DateFormat('MMM d, yyyy').format(plant.lastWatered!)}',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: cs.onSurface
                                                  .withOpacity(0.7)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Icon(LucideIcons.clock,
                                    size: 18, color: cs.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Plant History (${_logs.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Timeline of images, health scans & activity.',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_logs.isEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(LucideIcons.clock,
                                    size: 48,
                                    color: cs.onSurface.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text('No history available yet.',
                                    style: TextStyle(
                                        color: cs.onSurface.withOpacity(0.5))),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final log = _logs[index];
                              final imageUrl = _proofImageUrl(log.proofImageId);
                              final meta = _historyMeta(log);
                              final metaHealth = meta?['health']?.toString();
                              final metaLocation =
                                  meta?['location']?.toString();
                              final isFirst = index == _logs.length - 1;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Timeline indicator
                                  Column(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: cs.primaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _actionIcon(meta?['type'] ==
                                                  'image_update_meta'
                                              ? 'image_update'
                                              : log.actionType),
                                          size: 16,
                                          color: cs.primary,
                                        ),
                                      ),
                                      if (!isFirst)
                                        Container(
                                          width: 2,
                                          height:
                                              imageUrl.isNotEmpty ? 280 : 70,
                                          color: cs.outlineVariant,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Card(
                                      margin: const EdgeInsets.only(
                                          bottom: 16, top: 0),
                                      clipBehavior: Clip.antiAlias,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                            color: cs.outlineVariant
                                                .withOpacity(0.5)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (imageUrl.isNotEmpty)
                                            CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              width: double.infinity,
                                              height: 200,
                                              fit: BoxFit.cover,
                                              placeholder: (ctx, url) =>
                                                  Container(
                                                height: 200,
                                                color: cs.surfaceVariant,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                ),
                                              ),
                                              errorWidget: (ctx, url, err) =>
                                                  Container(
                                                height: 120,
                                                color: cs.surfaceVariant,
                                                child: Center(
                                                  child: Icon(
                                                      LucideIcons.imageOff,
                                                      size: 32,
                                                      color:
                                                          cs.onSurfaceVariant),
                                                ),
                                              ),
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        _formatActionType(meta?[
                                                                    'type'] ==
                                                                'image_update_meta'
                                                            ? 'image_update'
                                                            : log.actionType),
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 15),
                                                      ),
                                                    ),
                                                    if (log.verificationStatus
                                                        .isNotEmpty)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: _getStatusColor(log
                                                                  .verificationStatus)
                                                              .withOpacity(
                                                                  0.15),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          log.verificationStatus
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: _getStatusColor(
                                                                log.verificationStatus),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(LucideIcons.clock,
                                                        size: 12,
                                                        color: cs.onSurface
                                                            .withOpacity(0.5)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      DateFormat(
                                                              'MMM d, yyyy • h:mm a')
                                                          .format(
                                                              log.createdAt),
                                                      style: TextStyle(
                                                        color: cs.onSurface
                                                            .withOpacity(0.6),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (log.coinsAwarded > 0) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          Icons.monetization_on,
                                                          size: 13,
                                                          color: Colors.amber),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '+${log.coinsAwarded} coins',
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.amber,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                if (metaHealth != null &&
                                                    metaHealth.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                          LucideIcons
                                                              .heartPulse,
                                                          size: 12,
                                                          color: cs.onSurface
                                                              .withOpacity(
                                                                  0.6)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Health: $metaHealth',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: cs.onSurface
                                                              .withOpacity(
                                                                  0.75),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                if (meta?['type'] == 'custom_task_proof') ...[
                                                  const SizedBox(height: 8),
                                                  if (meta?['title'] != null)
                                                    Text(
                                                      'Mission: ${meta?['title']}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: cs.primary,
                                                      ),
                                                    ),
                                                  if (meta?['user_lat'] != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: InkWell(
                                                        onTap: () async {
                                                          final lat = meta?['user_lat'];
                                                          final lng = meta?['user_lng'];
                                                          if (lat != null && lng != null) {
                                                            final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                                            if (await canLaunchUrl(url)) {
                                                              await launchUrl(url, mode: LaunchMode.externalApplication);
                                                            }
                                                          }
                                                        },
                                                        child: Row(
                                                          children: [
                                                            Icon(LucideIcons.mapPin, size: 12, color: cs.primary),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              'User location at completion: ${meta?['user_lat'].toStringAsFixed(4)}, ${meta?['user_lng'].toStringAsFixed(4)}',
                                                              style: TextStyle(fontSize: 11, color: cs.primary, decoration: TextDecoration.underline),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                                if (metaLocation != null &&
                                                    metaLocation
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(LucideIcons.mapPin,
                                                          size: 12,
                                                          color: cs.onSurface
                                                              .withOpacity(
                                                                  0.6)),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          'Location: $metaLocation',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: cs.onSurface
                                                                .withOpacity(
                                                                    0.75),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                            childCount: _logs.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40))
                  ],
                ),
    );
  }

  String _formatActionType(String type) {
    switch (type.toLowerCase()) {
      case 'water':
        return 'Watered Plant';
      case 'scan_disease':
        return 'Health Scan';
      case 'register':
        return 'Initial Planting';
      case 'image_update':
        return 'Image Updated';
      case 'custom_task_proof':
        return 'Mission Completed';
      default:
        if (type.isEmpty) return 'Activity';
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  IconData _actionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'water':
        return LucideIcons.droplets;
      case 'scan_disease':
        return LucideIcons.stethoscope;
      case 'register':
        return LucideIcons.leaf;
      case 'image_update':
        return LucideIcons.camera;
      case 'custom_task_proof':
        return LucideIcons.clipboardCheck;
      default:
        return LucideIcons.activity;
    }
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'verified') return Colors.green;
    if (status.toLowerCase() == 'rejected') return Colors.red;
    return Colors.orange;
  }
}
