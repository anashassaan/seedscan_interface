import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/scan_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../controllers/community_controller.dart';
import '../notifications/notifications_view.dart';
import '../../appwrite_constants.dart';

// REAL SCREENS
import '../home/my_garden_screen.dart';
import '../home/wallet_screen.dart';
import '../home/tasks_screen.dart';
import '../home/watering_screen.dart';

class HomeView extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = Provider.of<AuthController>(context);
    final notificationController = Provider.of<NotificationController>(context);
    final scanController = Provider.of<ScanController>(context);
    final walletController = Provider.of<WalletController>(context);
    final communityController = Provider.of<CommunityController>(context);
    
    // Count unique plants (Personal + Community)
    final personalPlants = scanController.getMyPlants();
    final communityPlants = communityController.getAllCommunityPlants();
    final uniquePlantIds = {
      ...personalPlants.map((p) => p.id),
      ...communityPlants.map((p) => p.id),
    };
    final plantsCount = uniquePlantIds.length;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello,',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              auth.userName,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: cs.primaryContainer,
                        backgroundImage: auth.profileImageUrl != null
                            ? NetworkImage(auth.profileImageUrl!)
                            : null,
                        child: auth.profileImageUrl == null
                            ? Text(
                                auth.userInitials,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _statCardStatic(
                          'Plants',
                          '$plantsCount',
                          Icons.eco_outlined,
                          cs,
                          Colors.green.shade50,
                          Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _statCard(
                          'Wallet Points',
                          '${walletController.points}',
                          Icons.account_balance_wallet_outlined,
                          cs,
                          Colors.amber.shade50,
                          Colors.amber.shade800,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WalletScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Tasks',
                          '5 Due',
                          Icons.event_available,
                          cs,
                          Colors.blue.shade50,
                          Colors.blue.shade700,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TasksScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _quickActionWithBadge(
                        context,
                        Icons.water_drop,
                        'Watering',
                        notificationController.notifications
                            .where((n) =>
                                n.type == NotificationType.watering &&
                                !n.isRead)
                            .length,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WateringScreen(),
                            ),
                          );
                        },
                      ),
                      _quickAction(context, Icons.document_scanner_outlined,
                          'Diagnosis', 2),
                      _quickAction(
                          context, Icons.yard_outlined, 'My Garden', 0),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // My Plants
                  Text(
                    'My Plants',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _plantsPreview(scanController, communityController),
                ],
              ),
            ),
          ),

          // Notification Floating Button
          Positioned(
            right: 20,
            top: 20,
            child: SafeArea(
              child: FloatingActionButton(
                heroTag: 'home_notification_fab',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsView(),
                    ),
                  );
                },
                backgroundColor: cs.primaryContainer,
                child: badges.Badge(
                  showBadge: notificationController.unreadCount > 0,
                  badgeContent: Text(
                    '${notificationController.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: Icon(Icons.notifications_outlined,
                      color: cs.onPrimaryContainer),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Stat Card
  Widget _statCard(String title, String value, IconData icon, ColorScheme cs,
      Color bgColor, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: iconColor.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Static Stat Card (no onTap)
  Widget _statCardStatic(String title, String value, IconData icon,
      ColorScheme cs, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: iconColor.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Quick Action Button
  Widget _quickAction(
      BuildContext context, IconData icon, String label, int index) {
    return InkWell(
      onTap: () {
        if (label == 'My Garden') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyGardenScreen(),
            ),
          );
        } else {
          onNavigate(index);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 30, child: Icon(icon, size: 28)),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Quick Action with Badge
  Widget _quickActionWithBadge(
    BuildContext context,
    IconData icon,
    String label,
    int badgeCount,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          badges.Badge(
            showBadge: badgeCount > 0,
            badgeContent: Text(
              '$badgeCount',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: Icon(icon, size: 28, color: Colors.blue.shade700),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Plants Preview — loaded from Appwrite via ScanController & CommunityController
  Widget _plantsPreview(
      ScanController scanController, CommunityController communityController) {
    if (scanController.isLoadingPlants ||
        communityController.isLoadingCommunityPlants) {
      return SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    // Merge personal plants and community plants
    final List<PlantModel> unifiedPlants = [];
    unifiedPlants.addAll(scanController.getMyPlants());

    final communityPlants = communityController.getAllCommunityPlants();
    for (final cp in communityPlants) {
      if (!unifiedPlants.any((p) => p.id == cp.id)) {
        unifiedPlants.add(PlantModel(
          id: cp.id,
          name: cp.plantName,
          scientificName: cp.scientificName,
          image: cp.imageUrl ?? '',
          status: cp.status,
          statusColor: cp.statusColor,
          lastScan:
              '${cp.plantedDate.day}/${cp.plantedDate.month}/${cp.plantedDate.year}',
          location: cp.location,
          driveId: cp.communityId,
          latitude: cp.latitude,
          longitude: cp.longitude,
        ));
      }
    }

    final plants = unifiedPlants;

    if (plants.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco_outlined, color: Colors.green.shade300, size: 40),
              const SizedBox(height: 8),
              Text(
                'No plants yet',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Scan a QR code to add your first plant',
                style: TextStyle(
                  color: Colors.green.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      // Card width = 35% of available width, clamped between 110 and 170 dp
      final cardW = (constraints.maxWidth * 0.35).clamp(110.0, 170.0);
      return SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: plants.length,
          itemBuilder: (context, index) {
            final plant = plants[index];
            return _plantBox(plant.name, plant.status, plant.image,
                plant.statusColor, plant.lastScan, cardW);
          },
        ),
      );
    });
  }

  // Plant card — real data
  Widget _plantBox(
      String name, String status, String img, Color statusColor, String date,
      [double width = 140]) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: img.isNotEmpty && img.startsWith('http')
                  ? Image.network(img,
                      headers: const {
                        'X-Appwrite-Project': AppwriteConstants.projectId
                      },
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: Colors.green.shade50,
                            child: Icon(Icons.eco,
                                size: 40, color: Colors.green.shade300),
                          ))
                  : Container(
                      color: Colors.green.shade50,
                      child: Icon(Icons.eco,
                          size: 40, color: Colors.green.shade300),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12)),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, color: statusColor)),
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
