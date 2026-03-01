import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/plant_model.dart';
import '../../../models/transaction_model.dart';
import '../../controllers/admin_controller.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plant = widget.plant;

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.nickname ?? plant.species),
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
                            // Main Plant Info Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: cs.primaryContainer,
                                    backgroundImage: plant.imageUrl.isNotEmpty
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
                                          'Current Status',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                cs.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getHealthColor(
                                                    plant.healthStatus)
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            plant.healthStatus.toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: _getHealthColor(
                                                  plant.healthStatus),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Visual History',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Track the plant\'s health and changes over time.',
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
                              final hasImage = log.proofImageId.isNotEmpty;

                              // Create URL for proofImageId. Assuming Appwrite formatting for now,
                              // we will need the full URL or we just use it if it's already an HTTP URL.
                              // If it's a file ID, we need to convert it via Appwrite storage.
                              // For MVP: if it doesn't start with HTTP assume our AppwriteStorage URL logic.
                              // We'll just display the action if there is no image.

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                      color:
                                          cs.outlineVariant.withOpacity(0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (hasImage &&
                                        log.proofImageId.startsWith('http'))
                                      CachedNetworkImage(
                                        imageUrl: log.proofImageId,
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          height: 220,
                                          color: cs.surfaceVariant,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        errorWidget: (context, url, err) =>
                                            Container(
                                          height: 140,
                                          color: cs.surfaceVariant,
                                          child: Icon(LucideIcons.imageOff,
                                              size: 32,
                                              color: cs.onSurfaceVariant),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _formatActionType(
                                                    log.actionType),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat(
                                                        'MMM d, yyyy • h:mm a')
                                                    .format(log.createdAt),
                                                style: TextStyle(
                                                  color: cs.onSurface
                                                      .withOpacity(0.6),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (log.verificationStatus.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                        log.verificationStatus)
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                log.verificationStatus
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusColor(
                                                      log.verificationStatus),
                                                ),
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
      default:
        if (type.isEmpty) return 'Activity';
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'verified') return Colors.green;
    if (status.toLowerCase() == 'rejected') return Colors.red;
    return Colors.orange;
  }
}
