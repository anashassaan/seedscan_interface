// lib/views/common/plant_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlantCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String id;
  final String status; // "Healthy", "Needs Water", etc.
  final DateTime lastScanned;

  const PlantCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.id,
    required this.status,
    required this.lastScanned,
  });

  Color _statusColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green.shade600;
      case 'needs water':
        return Colors.orange.shade700;
      case 'disease':
        return Colors.red.shade600;
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: 92,
                height: 92,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  width: 92,
                  height: 92,
                  color: cs.surfaceVariant,
                  child: const Icon(Icons.local_florist, size: 36),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(context).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _statusColor(context),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '#$id',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Scanned: ${DateFormat.yMMMd().format(lastScanned)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
