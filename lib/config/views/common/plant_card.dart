// lib/views/common/plant_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlantCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String scientificName;
  final String id;
  final String status; // "Healthy", "Needs Water", etc.
  final String lastScanned; // e.g., "2 days ago"

  const PlantCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.scientificName,
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

  Color _statusBackgroundColor(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green.shade50;
      case 'needs water':
        return Colors.orange.shade50;
      case 'disease':
        return Colors.red.shade50;
      default:
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation:
          0, // Reference looks flat with subtle border or shadow, but elevation 0 with border is cleaner or low elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  width: 72,
                  height: 72,
                  color: cs.surfaceVariant,
                  child: Icon(Icons.local_florist,
                      size: 32, color: cs.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBackgroundColor(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _statusColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scientificName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.center_focus_weak, // Scan icon
                        size: 14,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Scanned $lastScanned',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.4),
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
    );
  }
}
