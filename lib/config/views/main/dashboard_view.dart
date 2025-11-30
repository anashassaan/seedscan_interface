import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/scan_controller.dart';
import '../../controllers/auth_controller.dart';
import '../common/plant_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ScanController scanController = ScanController();

  @override
  Widget build(BuildContext context) {
    final plants = scanController.getMyPlants();
    final auth = Provider.of<AuthController>(context);
    final userName = auth.userName;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hi, $userName 👋",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                ],
              ),

              const SizedBox(height: 8),
              Text(
                "Let's check on your plants.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 20),

              /// STATS
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildStatCard(
                      context,
                      title: "Trees Planted",
                      value: "12",
                      icon: Icons.forest_rounded,
                      backgroundColor: Colors.green.shade50,
                      iconColor: Colors.green.shade700,
                      textColor: Colors.green.shade900,
                    ),
                    _buildStatCard(
                      context,
                      title: "Carbon Offset",
                      value: "45.2kg",
                      icon: Icons.eco_rounded,
                      backgroundColor: Colors.blue.shade50,
                      iconColor: Colors.blue.shade700,
                      textColor: Colors.blue.shade900,
                    ),
                    _buildStatCard(
                      context,
                      title: "Wallet Points",
                      value: "1250",
                      icon: Icons.wallet_rounded,
                      backgroundColor: Colors.amber.shade50,
                      iconColor: Colors.amber.shade700,
                      textColor: Colors.amber.shade900,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "My Plants",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              /// PLANTS LIST
              Expanded(
                child: ListView.builder(
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
                    final plant = plants[index];
                    return PlantCard(
                      imageUrl: plant.image,
                      name: plant.name,
                      scientificName: plant.scientificName,
                      id: plant.id,
                      status: plant.status,
                      lastScanned: plant.lastScan,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
