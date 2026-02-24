import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/scan_controller.dart';

class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scanCtrl = Provider.of<ScanController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Plants',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
      body: _buildBody(context, cs, scanCtrl),
    );
  }

  Widget _buildBody(
      BuildContext context, ColorScheme cs, ScanController scanCtrl) {
    // Loading state
    if (scanCtrl.isLoadingPlants) {
      return const Center(child: CircularProgressIndicator());
    }

    final plants = scanCtrl.getMyPlants();

    // Empty state
    if (plants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco_outlined,
                  size: 72, color: cs.primary.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text(
                'No plants yet',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan a garden QR code to add your first plant.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Real plant list
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plants.length,
      itemBuilder: (context, index) => _plantTile(context, cs, plants[index]),
    );
  }

  Widget _plantTile(BuildContext context, ColorScheme cs, PlantModel plant) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Plant image
          SizedBox(
            height: 90,
            width: 90,
            child: plant.image.isNotEmpty && plant.image.startsWith('http')
                ? Image.network(
                    plant.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(cs),
                  )
                : _imagePlaceholder(cs),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (plant.scientificName.isNotEmpty)
                    Text(
                      plant.scientificName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: plant.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        plant.status,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: plant.statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (plant.location != null && plant.location!.isNotEmpty)
                    Text(
                      '📍 ${plant.location}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: cs.onSurface.withOpacity(0.45),
                      ),
                    ),
                  Text(
                    'Planted: ${plant.lastScan}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme cs) {
    return Container(
      color: cs.primaryContainer.withOpacity(0.3),
      child: Icon(Icons.eco, size: 36, color: cs.primary.withOpacity(0.5)),
    );
  }
}
