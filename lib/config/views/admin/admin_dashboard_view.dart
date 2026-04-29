import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_controller.dart';

import 'manage_users_view.dart';
import 'ai_model_updates_view.dart';
import 'system_logs_view.dart';
import 'manage_communities_view.dart';
import 'coin_analytics_view.dart';
import 'admin_stats_details_view.dart';
import 'admin_profile_view.dart';
import 'community_details_view.dart';
import 'admin_tasks_manager_view.dart';
import 'admin_withdrawals_view.dart';

class AdminDashboardView extends StatefulWidget {
  final String
      adminId; // Used to force widget recreation when admin user changes

  const AdminDashboardView({required this.adminId, super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _currentIndex = 0;
  String? _loadedForAdminId; // Track which admin user's data is loaded

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _HomeTab(),
      const ManageCommunitiesView(),
      const CoinAnalyticsView(),
      const AdminProfileView(),
    ];
    // Initialize admin data from Appwrite backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeAdmin();
    });
  }

  /// Ensure AdminController data belongs to the current logged-in admin.
  /// Reset and reload if the admin user changed. This is called on every init since
  /// the widget is recreated with a new ValueKey when the admin ID changes.
  void _initializeAdmin() {
    final auth = Provider.of<AuthController>(context, listen: false);
    final admin = Provider.of<AdminController>(context, listen: false);
    final currentAdminId = auth.userId;

    // Always reset on init since widget is recreated for each admin
    if (currentAdminId != null) {
      debugPrint(
          '[AdminDashboardView] Initializing admin dashboard for $currentAdminId');
      admin.reset();
      _loadedForAdminId = currentAdminId;
    }

    // Now initialize/load data for the current admin
    admin.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        shadowColor: cs.shadow.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(cs, 0, LucideIcons.layoutDashboard,
                LucideIcons.layoutDashboard, 'Home'),
            _buildNavItem(
                cs, 1, LucideIcons.users, LucideIcons.users, 'Community'),
            _buildNavItem(cs, 2, LucideIcons.barChart2, LucideIcons.barChart2,
                'Analytics'),
            _buildNavItem(cs, 3, LucideIcons.userCircle, LucideIcons.userCircle,
                'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(ColorScheme cs, int index, IconData icon,
      IconData selectedIcon, String label) {
    final isActive = _currentIndex == index;
    final color = isActive ? cs.primary : cs.onSurface.withOpacity(0.6);
    final screenW = MediaQuery.of(context).size.width;
    final itemPadding = screenW < 360 ? 4.0 : 6.0;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: EdgeInsets.all(itemPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HOME TAB — Full dashboard redesign
// ═══════════════════════════════════════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // ── Static Green Header ──
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0BA360),
                Color(0xFF3CBA92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0BA360).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminProfileView()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      child: Consumer<AuthController>(
                        builder: (_, auth, __) {
                          if (auth.profileImage != null) {
                            return CircleAvatar(
                              radius: 18,
                              backgroundImage:
                                  FileImage(File(auth.profileImage!)),
                            );
                          }
                          return CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(LucideIcons.user,
                                color: Colors.white, size: 18),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13)),
                        const Text('Admin Panel',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: admin.serverStatus == 'Online'
                          ? Colors.greenAccent.withOpacity(0.25)
                          : Colors.redAccent.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: admin.serverStatus == 'Online'
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(admin.serverStatus,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick stats row inside header
              Row(
                children: [
                  _headerStat(
                      admin.totalUsers.toString(), 'Users', LucideIcons.users),
                  const SizedBox(width: 12),
                  _headerStat(admin.communities.length.toString(),
                      'Communities', LucideIcons.treeDeciduous),
                  const SizedBox(width: 12),
                  _headerStat(admin.totalQrCodes.toString(), 'QR Codes',
                      LucideIcons.qrCode),
                ],
              ),
            ],
          ),
        ),

        // ── Scrollable Content Below ──
        Expanded(
          child: RefreshIndicator(
            color: cs.primary,
            onRefresh: () => admin.refreshStats(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // ── Overview Stats Grid ──
                    _sectionHeader(cs, 'Overview', LucideIcons.activity),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            cs,
                            title: 'Trees Planted',
                            value: _formatNum(admin.totalPlants),
                            icon: LucideIcons.treeDeciduous,
                            color: const Color(0xFF0BA360),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const TreeScansStatsPage())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            cs,
                            title: 'Disease Alerts',
                            value: _formatNum(admin.diseasesDetected),
                            icon: LucideIcons.alertTriangle,
                            color: const Color(0xFFE53935),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DiseaseStatsPage())),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            cs,
                            title: 'Auto Notify',
                            value: 'Water',
                            icon: LucideIcons.bellRing,
                            color: const Color(0xFF0BA360),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AutoNotificationSenderPage())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            cs,
                            title: 'Custom',
                            value: 'Notify',
                            icon: LucideIcons.megaphone,
                            color: const Color(0xFF6366F1),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const CustomNotificationSenderPage())),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            cs,
                            title: 'Broadcast',
                            value: 'Tasks',
                            icon: LucideIcons.clipboardCheck,
                            color: Colors.amber.shade700,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminTasksManagerView())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            cs,
                            title: 'Withdrawals',
                            value: 'Payouts',
                            icon: LucideIcons.coins,
                            color: const Color(
                                0xFFF59E0B), // Amber color for coins
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminWithdrawalsView())),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Recent Communities ──
                    _sectionHeader(cs, 'Recent Communities', LucideIcons.globe),
                    const SizedBox(height: 14),
                    if (admin.communities.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text('No communities yet',
                              style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.4))),
                        ),
                      )
                    else
                      ...admin.communities.take(3).map((c) {
                        final index = admin.communities.indexOf(c);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _communityTile(
                            cs,
                            c,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CommunityDetailsView(communityIndex: index),
                              ),
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper: Greeting ──
  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  // ── Header stat pill ──
  static Widget _headerStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section header ──
  static Widget _sectionHeader(ColorScheme cs, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: cs.onSurface)),
      ],
    );
  }

  // ── Health status mini-card ──
  static Widget _healthCard({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.30), width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toString(),
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Metric card ──
  static Widget _metricCard(
    ColorScheme cs, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cs.surfaceContainerHighest.withOpacity(0.35),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        letterSpacing: -0.5)),
              ),
              const SizedBox(height: 2),
              Text(title.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: cs.onSurface.withOpacity(0.5)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quick action tile ──
  // ignore: unused_element
  static Widget _quickAction(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cs.surfaceContainerHighest.withOpacity(0.25),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 18, color: cs.onSurface.withOpacity(0.25)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Community tile ──
  static Widget _communityTile(ColorScheme cs, AdminCommunity c,
      {VoidCallback? onTap}) {
    return Material(
      color: cs.surfaceContainerHighest.withOpacity(0.25),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.treeDeciduous,
                    color: cs.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('${c.members.length} members  ·  ${c.location}',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurface.withOpacity(0.5)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(c.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: c.isActive ? Colors.green : Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SETTINGS TAB — Complete redesign with full features
// ═══════════════════════════════════════════════════════════════════════════
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _darkMode = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _maintenanceMode = false;
  bool _analyticsTracking = true;
  bool _twoFactorAuth = false;
  String _selectedLanguage = 'English';
  String _dataRetention = '90 Days';

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);
    final auth = Provider.of<AuthController>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════ HEADER ═══════════
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, topPad + 14, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(LucideIcons.settings,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Settings',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          Text('Configure & manage your platform',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Admin avatar
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminProfileView()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5), width: 2),
                        ),
                        child: Consumer<AuthController>(
                          builder: (_, a, __) {
                            if (a.profileImage != null) {
                              return CircleAvatar(
                                radius: 18,
                                backgroundImage:
                                    FileImage(File(a.profileImage!)),
                              );
                            }
                            return CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: const Icon(LucideIcons.user,
                                  color: Colors.white, size: 18),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Quick info pills
                Row(
                  children: [
                    _headerPill(
                        LucideIcons.server, admin.serverStatus, Colors.white),
                    const SizedBox(width: 8),
                    _headerPill(LucideIcons.shield, 'Admin', Colors.white),
                    const SizedBox(width: 8),
                    _headerPill(LucideIcons.globe, 'v1.0.0', Colors.white),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════ ACCOUNT ═══════════
                _sectionLabel(cs, 'Account', LucideIcons.user),
                const SizedBox(height: 12),
                _settingsCard(cs, [
                  _navTile(cs,
                      icon: LucideIcons.userCircle,
                      title: 'My Profile',
                      subtitle: auth.userEmail ?? 'admin@seedscan.com',
                      color: cs.primary,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminProfileView()))),
                  _tileDivider(cs),
                  _navTile(cs,
                      icon: LucideIcons.lock,
                      title: 'Change Password',
                      subtitle: 'Last changed 30 days ago',
                      color: const Color(0xFF5C6BC0),
                      onTap: () => _showChangePasswordDialog()),
                  _tileDivider(cs),
                  _toggleTile(cs,
                      icon: LucideIcons.smartphone,
                      title: 'Two-Factor Auth',
                      subtitle: _twoFactorAuth ? 'Enabled' : 'Disabled',
                      color: const Color(0xFF00897B),
                      value: _twoFactorAuth, onChanged: (v) {
                    setState(() => _twoFactorAuth = v);
                    _showSnack(v ? '2FA enabled' : '2FA disabled', v);
                  }),
                ]),

                const SizedBox(height: 24),

                // ═══════════ NOTIFICATIONS ═══════════
                _sectionLabel(cs, 'Notifications', LucideIcons.bell),
                const SizedBox(height: 12),
                _settingsCard(cs, [
                  _toggleTile(cs,
                      icon: LucideIcons.calendarClock,
                      title: 'Auto-Care Reminders',
                      subtitle: '24h cycle nudges to water plants',
                      color: cs.primary,
                      value: admin.isAutoReminderEnabled, onChanged: (v) async {
                    await admin.toggleAutoReminder(v);
                    _showSnack(
                        v ? 'Reminders enabled' : 'Reminders disabled', v);
                  }),
                  _tileDivider(cs),
                  _toggleTile(cs,
                      icon: LucideIcons.mail,
                      title: 'Email Notifications',
                      subtitle: 'Alerts, reports & weekly digest',
                      color: const Color(0xFFE53935),
                      value: _emailNotifications,
                      onChanged: (v) =>
                          setState(() => _emailNotifications = v)),
                  _tileDivider(cs),
                  _toggleTile(cs,
                      icon: LucideIcons.bellRing,
                      title: 'Push Notifications',
                      subtitle: 'Real-time system alerts',
                      color: const Color(0xFFFF8F00),
                      value: _pushNotifications,
                      onChanged: (v) => setState(() => _pushNotifications = v)),
                  _tileDivider(cs),
                  _navTile(cs,
                      icon: LucideIcons.megaphone,
                      title: 'Send Notification',
                      subtitle: 'Broadcast to all users',
                      color: const Color(0xFF5C6BC0),
                      onTap: () => _showNotificationDialog(context)),
                ]),

                const SizedBox(height: 24),

                // ═══════════ SYSTEM MANAGEMENT ═══════════
                _sectionLabel(cs, 'System Management', LucideIcons.wrench),
                const SizedBox(height: 12),
                _settingsCard(cs, [
                  _navTile(cs,
                      icon: LucideIcons.userCheck,
                      title: 'User Management',
                      subtitle: 'Roles, permissions & accounts',
                      color: const Color(0xFF5C6BC0),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ManageUsersView()))),
                  _tileDivider(cs),
                  _navTile(cs,
                      icon: LucideIcons.brainCircuit,
                      title: 'AI Model Updates',
                      subtitle: 'Deploy & manage ML models',
                      color: const Color(0xFF00897B),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AIModelUpdatesView()))),
                  _tileDivider(cs),
                  _navTile(cs,
                      icon: LucideIcons.fileText,
                      title: 'System Logs',
                      subtitle: 'Activity & error logs',
                      color: const Color(0xFF546E7A),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SystemLogsView()))),
                  _tileDivider(cs),
                  _navTile(cs,
                      icon: LucideIcons.megaphone,
                      title: 'Custom Notifications',
                      subtitle: 'Send targeted notifications',
                      color: const Color(0xFF6366F1),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const CustomNotificationSenderPage()))),
                ]),

                const SizedBox(height: 24),

                // ═══════════ APPEARANCE ═══════════
                _sectionLabel(cs, 'Appearance', LucideIcons.palette),
                const SizedBox(height: 12),
                _settingsCard(cs, [
                  _toggleTile(cs,
                      icon: LucideIcons.moon,
                      title: 'Dark Mode',
                      subtitle: _darkMode
                          ? 'Dark theme active'
                          : 'Light theme active',
                      color: const Color(0xFF5C6BC0),
                      value: _darkMode,
                      onChanged: (v) => setState(() => _darkMode = v)),
                  _tileDivider(cs),
                  _dropdownTile(cs,
                      icon: LucideIcons.languages,
                      title: 'Language',
                      color: const Color(0xFFFF8F00),
                      value: _selectedLanguage,
                      options: [
                        'English',
                        'Spanish',
                        'French',
                        'Arabic',
                        'Urdu'
                      ],
                      onChanged: (v) => setState(() => _selectedLanguage = v)),
                ]),

                const SizedBox(height: 24),

                // ═══════════ DATA & PRIVACY ═══════════
                _sectionLabel(cs, 'Data & Privacy', LucideIcons.database),
                const SizedBox(height: 12),
                _settingsCard(cs, [
                  _toggleTile(cs,
                      icon: LucideIcons.activity,
                      title: 'Analytics Tracking',
                      subtitle: 'Collect usage data for insights',
                      color: const Color(0xFF0BA360),
                      value: _analyticsTracking,
                      onChanged: (v) => setState(() => _analyticsTracking = v)),
                  _tileDivider(cs),
                  _dropdownTile(cs,
                      icon: LucideIcons.clock,
                      title: 'Data Retention',
                      color: const Color(0xFF546E7A),
                      value: _dataRetention,
                      options: [
                        '30 Days',
                        '60 Days',
                        '90 Days',
                        '180 Days',
                        '1 Year'
                      ],
                      onChanged: (v) => setState(() => _dataRetention = v)),
                  _tileDivider(cs),
                  _navTile(cs,
                      icon: LucideIcons.download,
                      title: 'Export Data',
                      subtitle: 'Download platform data as CSV',
                      color: const Color(0xFF5C6BC0),
                      onTap: () => _showExportDialog()),
                  _tileDivider(cs),
                  _navTile(cs,
                      icon: LucideIcons.trash2,
                      title: 'Clear Cache',
                      subtitle: 'Free up storage space',
                      color: Colors.redAccent,
                      onTap: () => _showClearCacheDialog()),
                ]),

                const SizedBox(height: 24),

                // ═══════════ PLATFORM ═══════════
                _sectionLabel(cs, 'Platform', LucideIcons.settings2),
                const SizedBox(height: 12),
                _settingsCard(cs, [
                  _toggleTile(cs,
                      icon: LucideIcons.construction,
                      title: 'Maintenance Mode',
                      subtitle: _maintenanceMode
                          ? 'Platform is under maintenance'
                          : 'Platform is live',
                      color: Colors.orange,
                      value: _maintenanceMode, onChanged: (v) {
                    if (v) {
                      _showMaintenanceConfirm(v);
                    } else {
                      setState(() => _maintenanceMode = false);
                      _showSnack('Platform is live', true);
                    }
                  }),
                  _tileDivider(cs),
                  _navTile(cs,
                      icon: LucideIcons.refreshCw,
                      title: 'Refresh Platform Stats',
                      subtitle: 'Reload all data from server',
                      color: cs.primary, onTap: () async {
                    await admin.refreshStats();
                    if (mounted) {
                      _showSnack('Stats refreshed', true);
                    }
                  }),
                  _tileDivider(cs),
                  _navTile(cs,
                      icon: LucideIcons.helpCircle,
                      title: 'Help & Support',
                      subtitle: 'Documentation & contact',
                      color: const Color(0xFF00897B),
                      onTap: () => _showHelpDialog()),
                ]),

                const SizedBox(height: 24),

                // ═══════════ DANGER ZONE ═══════════
                _sectionLabel(cs, 'Danger Zone', LucideIcons.alertTriangle),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.12), width: 1),
                  ),
                  child: Column(
                    children: [
                      _navTile(cs,
                          icon: LucideIcons.logOut,
                          title: 'Sign Out',
                          subtitle: 'Log out of admin account',
                          color: Colors.redAccent,
                          onTap: () => _showSignOutDialog(auth)),
                      Divider(
                          height: 1,
                          color: Colors.redAccent.withOpacity(0.08),
                          indent: 56,
                          endIndent: 16),
                      _navTile(cs,
                          icon: LucideIcons.trash2,
                          title: 'Deactivate Account',
                          subtitle: 'Permanently disable this account',
                          color: Colors.redAccent,
                          onTap: () => _showDeactivateDialog()),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // App info footer
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.leaf,
                                size: 14, color: cs.primary.withOpacity(0.5)),
                            const SizedBox(width: 6),
                            Text('SeedScan Admin',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface.withOpacity(0.35))),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('v1.0.0',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Made with Flutter',
                          style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withOpacity(0.2))),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ BUILDING BLOCKS ═══════════════════

  Widget _headerPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(text,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _sectionLabel(ColorScheme cs, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Text(title.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: cs.onSurface.withOpacity(0.4))),
      ],
    );
  }

  Widget _settingsCard(ColorScheme cs, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _tileDivider(ColorScheme cs) {
    return Divider(
      height: 1,
      color: cs.onSurface.withOpacity(0.05),
      indent: 56,
      endIndent: 16,
    );
  }

  // Navigation tile with chevron
  Widget _navTile(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.45))),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 18, color: cs.onSurface.withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );
  }

  // Toggle tile with switch
  Widget _toggleTile(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withOpacity(0.45))),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Dropdown tile
  Widget _dropdownTile(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required Color color,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                borderRadius: BorderRadius.circular(14),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface),
                icon: Icon(LucideIcons.chevronDown,
                    size: 14, color: cs.onSurface.withOpacity(0.4)),
                items: options
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ DIALOGS ═══════════════════

  void _showSnack(String msg, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final cs = Theme.of(context).colorScheme;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool oc = true, on = true, occ = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.lock, color: cs.primary, size: 24),
          ),
          title: const Text('Change Password',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pwdField(cs, currentCtrl, 'Current Password', oc,
                  () => setDlg(() => oc = !oc)),
              const SizedBox(height: 12),
              _pwdField(cs, newCtrl, 'New Password', on,
                  () => setDlg(() => on = !on)),
              const SizedBox(height: 12),
              _pwdField(cs, confirmCtrl, 'Confirm Password', occ,
                  () => setDlg(() => occ = !occ)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.info, size: 12, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Min 8 characters with letters & numbers',
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(0.5))),
                  ),
                ],
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
            ),
            FilledButton.icon(
              onPressed: () {
                if (newCtrl.text.length >= 8 &&
                    newCtrl.text == confirmCtrl.text) {
                  Navigator.pop(ctx);
                  _showSnack('Password changed successfully', true);
                } else {
                  _showSnack('Passwords must match (min 8 chars)', false);
                }
              },
              icon: const Icon(LucideIcons.check, size: 16),
              label: const Text('Update',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwdField(ColorScheme cs, TextEditingController ctrl, String label,
      bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary, width: 1.5)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
          onPressed: toggle,
        ),
      ),
    );
  }

  void _showExportDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.download, color: cs.primary, size: 24),
        ),
        title: const Text('Export Data',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select data to export',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface.withOpacity(0.6))),
            const SizedBox(height: 16),
            _exportOption(cs, LucideIcons.users, 'User Data', true),
            const SizedBox(height: 8),
            _exportOption(
                cs, LucideIcons.treeDeciduous, 'Community Data', true),
            const SizedBox(height: 8),
            _exportOption(cs, LucideIcons.scan, 'Scan Reports', false),
            const SizedBox(height: 8),
            _exportOption(cs, LucideIcons.coins, 'Coin Transactions', false),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('Export started - download will begin shortly', true);
            },
            icon: const Icon(LucideIcons.download, size: 16),
            label: const Text('Export CSV',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _exportOption(
      ColorScheme cs, IconData icon, String title, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? cs.primary.withOpacity(0.08)
            : cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? cs.primary.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: selected ? cs.primary : cs.onSurface.withOpacity(0.4)),
          const SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const Spacer(),
          Icon(
            selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 18,
            color: selected ? cs.primary : cs.onSurface.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child:
              const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 24),
        ),
        title: const Text('Clear Cache',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This will clear all cached images and temporary files. The app may take longer to load data afterwards.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('Cache cleared (24 MB freed)', true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceConfirm(bool enable) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.construction,
              color: Colors.orange, size: 24),
        ),
        title: const Text('Enable Maintenance Mode',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Users will see a maintenance page and be unable to access the platform. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _maintenanceMode = true);
              _showSnack('Maintenance mode enabled', false);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.helpCircle, color: cs.primary, size: 24),
        ),
        title: const Text('Help & Support',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _helpItem(
                cs, LucideIcons.book, 'Documentation', 'docs.seedscan.io'),
            const SizedBox(height: 8),
            _helpItem(
                cs, LucideIcons.mail, 'Email Support', 'admin@seedscan.com'),
            const SizedBox(height: 8),
            _helpItem(cs, LucideIcons.messageCircle, 'Live Chat',
                'Available 9AM-5PM'),
            const SizedBox(height: 8),
            _helpItem(cs, LucideIcons.github, 'GitHub', 'github.com/seedscan'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _helpItem(ColorScheme cs, IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                Text(value,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurface.withOpacity(0.45))),
              ],
            ),
          ),
          Icon(LucideIcons.externalLink,
              size: 14, color: cs.onSurface.withOpacity(0.25)),
        ],
      ),
    );
  }

  void _showSignOutDialog(AuthController auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            const Text('Are you sure you want to sign out of the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.alertTriangle,
              color: Colors.redAccent, size: 24),
        ),
        title: const Text('Deactivate Account',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This action is irreversible. Your admin account will be permanently deactivated and you will lose all access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('Deactivation request submitted', false);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GLOBAL NOTIFICATION DIALOG
// ═══════════════════════════════════════════════════════════════════════════
void _showNotificationDialog(BuildContext context) {
  final admin = Provider.of<AdminController>(context, listen: false);
  final cs = Theme.of(context).colorScheme;
  final titleCtrl = TextEditingController();
  final messageCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(LucideIcons.megaphone, color: cs.primary, size: 24),
      ),
      title: const Text('Global Notification',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtrl,
            decoration: InputDecoration(
              labelText: 'Title',
              filled: true,
              fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: messageCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Message',
              filled: true,
              fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.primary, width: 1.5)),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel',
              style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
        ),
        FilledButton.icon(
          onPressed: () async {
            if (titleCtrl.text.isNotEmpty && messageCtrl.text.isNotEmpty) {
              await admin.sendGlobalNotification(
                  titleCtrl.text, messageCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            }
          },
          icon: const Icon(LucideIcons.send, size: 16),
          label:
              const Text('Send', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
