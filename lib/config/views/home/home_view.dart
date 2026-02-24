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

// REAL SCREENS
import '../home/my_plants_screen.dart';
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
    final plantsCount = scanController.getMyPlants().length +
        communityController.getTotalCommunityPlantsCount();

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            auth.userName,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: auth.profileImage != null
                            ? FileImage(File(auth.profileImage!))
                            : const NetworkImage(
                                'https://randomuser.me/api/portraits/men/45.jpg',
                              ) as ImageProvider,
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
                  _plantsPreview(scanController),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: iconColor.withOpacity(0.8),
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: iconColor.withOpacity(0.8),
            ),
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
        // Special handling for My Garden button
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
        children: [
          CircleAvatar(radius: 32, child: Icon(icon, size: 32)),
          const SizedBox(height: 6),
          Text(label),
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
        children: [
          badges.Badge(
            showBadge: badgeCount > 0,
            badgeContent: Text(
              '$badgeCount',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.blue.shade100,
              child: Icon(icon, size: 32, color: Colors.blue.shade700),
            ),
          ),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
    );
  }

  // Plants Preview — loaded from Appwrite via ScanController
  Widget _plantsPreview(ScanController scanController) {
    if (scanController.isLoadingPlants) {
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

    final plants = scanController.getMyPlants();

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

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: plants.length,
        itemBuilder: (context, index) {
          final plant = plants[index];
          return _plantBox(plant.name, plant.status, plant.image,
              plant.statusColor, plant.lastScan);
        },
      ),
    );
  }

  // Plant card — real data
  Widget _plantBox(
      String name, String status, String img, Color statusColor, String date) {
    return Container(
      width: 140,
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
