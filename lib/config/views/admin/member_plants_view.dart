import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/admin_controller.dart';
import '../../../models/plant_model.dart';
import 'plant_detail_admin_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MemberPlantsView extends StatefulWidget {
  final String userId;
  final String userName;

  const MemberPlantsView({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<MemberPlantsView> createState() => _MemberPlantsViewState();
}

class _MemberPlantsViewState extends State<MemberPlantsView> {
  bool _isLoading = true;
  List<PlantModel> _plants = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlants();
  }

  Future<void> _fetchPlants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final admin = Provider.of<AdminController>(context, listen: false);
      final plants = await admin.getUserPlants(widget.userId);
      if (mounted) {
        setState(() {
          _plants = plants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load plants: \$e";
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

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName}\'s Plants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchPlants(),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.alertTriangle,
                          size: 48, color: cs.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: cs.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPlants,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : _plants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.leaf,
                              size: 64, color: cs.onSurface.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text('No plants found for this member.',
                              style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.6))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPlants,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _plants.length,
                        itemBuilder: (context, index) {
                          final plant = _plants[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                  color: cs.outlineVariant.withOpacity(0.4)),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlantDetailAdminView(
                                      plant: plant,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  // Plant Image
                                  Container(
                                    width: 100,
                                    height: 100,
                                    color: cs.surfaceVariant,
                                    child: plant.imageUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: plant.imageUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Center(
                                                    child:
                                                        CircularProgressIndicator()),
                                            errorWidget:
                                                (context, url, error) => Icon(
                                                    LucideIcons.imageOff,
                                                    color: cs.onSurfaceVariant),
                                          )
                                        : Icon(LucideIcons.leaf,
                                            size: 32, color: cs.primary),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plant.nickname?.isNotEmpty == true
                                                ? plant.nickname!
                                                : plant.species,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (plant.nickname?.isNotEmpty ==
                                              true)
                                            Text(
                                              plant.species,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: cs.onSurface
                                                    .withOpacity(0.6),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getHealthColor(
                                                          plant.healthStatus)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  plant.healthStatus
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getHealthColor(
                                                        plant.healthStatus),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Icon(LucideIcons.chevronRight,
                                      color: cs.onSurface.withOpacity(0.3)),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
