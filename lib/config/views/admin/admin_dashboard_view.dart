import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_controller.dart';

import 'manage_users_view.dart';
import 'ai_model_updates_view.dart';
import 'system_logs_view.dart';
import 'manage_communities_view.dart';
import 'my_garden_view.dart';
import 'coin_analytics_view.dart';
import 'admin_stats_details_view.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _HomeTab(),
      const ManageCommunitiesView(),
      const CoinAnalyticsView(),
      const _SettingsTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => auth.signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(LucideIcons.users), label: 'Community'),
          BottomNavigationBarItem(
              icon: Icon(LucideIcons.barChart2), label: 'Analytics'),
          BottomNavigationBarItem(
              icon: Icon(LucideIcons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// --- SUB-WIDGET: HOME TAB ---
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  Future<void> _handleCsvUpload(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 20),
            const Icon(LucideIcons.fileSpreadsheet,
                size: 50, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Database Import',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Select a CSV file to sync system records',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Select CSV File",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => admin.refreshStats(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System Health',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface)),
                    Text('Real-time infrastructure monitoring',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
                IconButton.filledTonal(
                  icon: const Icon(LucideIcons.fileUp, size: 20),
                  onPressed: () => _handleCsvUpload(context),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // PROFESSIONAL GRID LAYOUT
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard(
                  context,
                  'Total Users',
                  admin.totalUsers.toString(),
                  LucideIcons.users,
                  [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TotalUsersStatsPage())),
                ),
                _buildStatCard(
                  context,
                  'Tree Scans',
                  admin.totalScans.toString(),
                  LucideIcons.scan,
                  [const Color(0xFF0BA360), const Color(0xFF3CBA92)],
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TreeScansStatsPage())),
                ),
                _buildStatCard(
                  context,
                  'Disease Alerts',
                  admin.diseasesDetected.toString(),
                  LucideIcons.alertTriangle,
                  [const Color(0xFFFF512F), const Color(0xFFDD2476)],
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DiseaseStatsPage())),
                ),
                _buildStatCard(
                  context,
                  'Server Health',
                  admin.serverStatus,
                  LucideIcons.server,
                  [const Color(0xFF434343), const Color(0xFF000000)],
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ServerHealthPage())),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Administrative Controls',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildAdminTile(context, 'Global Notification',
                LucideIcons.megaphone, () => _showNotificationDialog(context)),
            _buildAdminTile(
                context,
                'My Garden',
                LucideIcons.flower2,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MyGardenView()))),
          ],
        ),
      ),
    );
  }

  // --- PREMIUM STAT CARD DESIGN ---
  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, List<Color> gradientColors, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5),
                    ),
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- SUB-WIDGET: SETTINGS TAB ---
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Automations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: cs.primaryContainer.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.primary.withOpacity(0.2)),
          ),
          child: SwitchListTile(
            secondary: Icon(LucideIcons.calendarClock, color: cs.primary),
            title: const Text('24h Auto-Care Reminders',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Automatically nudge users to water plants.'),
            value: admin.isAutoReminderEnabled,
            onChanged: (bool value) async {
              await admin.toggleAutoReminder(value);

              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value
                        ? 'Background care reminders enabled'
                        : 'Background care reminders disabled'),
                    backgroundColor: value ? Colors.green : Colors.redAccent,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text('System Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        _buildAdminTile(
            context,
            'User Management',
            LucideIcons.userCheck,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ManageUsersView()))),
        _buildAdminTile(
            context,
            'AI Model Updates',
            LucideIcons.brainCircuit,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AIModelUpdatesView()))),
        _buildAdminTile(
            context,
            'System Logs',
            LucideIcons.fileText,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SystemLogsView()))),
      ],
    );
  }
}

// --- SHARED HELPER WIDGETS ---

Widget _buildAdminTile(
    BuildContext context, String title, IconData icon, VoidCallback onTap) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8, top: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

void _showNotificationDialog(BuildContext context) {
  final admin = Provider.of<AdminController>(context, listen: false);
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Send Global Notification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message')),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (titleController.text.isNotEmpty &&
                messageController.text.isNotEmpty) {
              await admin.sendGlobalNotification(
                  titleController.text, messageController.text);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Send'),
        ),
      ],
    ),
  );
}
