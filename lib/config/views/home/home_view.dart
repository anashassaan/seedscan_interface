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
                  _plantsPreview(),
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

  // Plants Preview
  Widget _plantsPreview() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // TODO: DUMMY DATA - Replace these placeholder images with user-uploaded photos
          _plantBox(
            'Neem Tree',
            'Healthy',
            'https://images.unsplash.com/photo-1597262975002-c5c3b14bbd62?auto=format&fit=crop&w=400', // PLACEHOLDER
          ),
          _plantBox(
            'Mango',
            'Needs Water',
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=400',
          ),
          _plantBox(
            'Rose',
            'Healthy',
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=400',
          ),
        ],
      ),
    );
  }

  // Plant card
  Widget _plantBox(String name, String status, String img) {
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
              child:
                  Image.network(img, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(status, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
