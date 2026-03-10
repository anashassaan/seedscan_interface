import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/admin_controller.dart';
import 'admin_stats_details_view.dart';

class CoinAnalyticsView extends StatefulWidget {
  const CoinAnalyticsView({super.key});

  @override
  State<CoinAnalyticsView> createState() => _CoinAnalyticsViewState();
}

class _CoinAnalyticsViewState extends State<CoinAnalyticsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedPeriod = 'This Week';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // ═══════════ STATIC GREEN HEADER ═══════════
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0BA360),
                  const Color(0xFF3CBA92),
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(LucideIcons.barChart2,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Analytics',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          Text('Platform insights & performance',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Period picker
                    _PeriodChip(
                      value: _selectedPeriod,
                      onChanged: (v) => setState(() => _selectedPeriod = v),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // KPI Row
                Row(
                  children: [
                    _kpiPill(
                      value: admin.totalUsers.toString(),
                      label: 'Total Users',
                      icon: LucideIcons.users,
                      trend: '',
                      up: true,
                    ),
                    const SizedBox(width: 12),
                    _kpiPill(
                      value: _formatNum(admin.allUsers
                          .fold<int>(0, (s, u) => s + u.totalCoins)),
                      label: 'Total Coins',
                      icon: LucideIcons.coins,
                      trend: '',
                      up: true,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ═══════════ TABS ═══════════
          Container(
            color: cs.surface,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurface.withOpacity(0.45),
              indicatorColor: cs.primary,
              indicatorWeight: 3,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Users'),
                Tab(text: 'Coins'),
              ],
            ),
          ),

          // ═══════════ TAB CONTENT ═══════════
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              physics: const ClampingScrollPhysics(),
              children: [
                _UsersTab(admin: admin, period: _selectedPeriod),
                _CoinsTab(admin: admin, period: _selectedPeriod),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiPill({
    required String value,
    required String label,
    required IconData icon,
    required String trend,
    required bool up,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 13),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (up ? Colors.greenAccent : Colors.redAccent)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    up ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 10,
                    color: up ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const SizedBox(width: 2),
                  Text(trend,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: up ? Colors.greenAccent : Colors.redAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ═══════════════════════════════════════════════════════════════
// PERIOD PICKER CHIP
// ═══════════════════════════════════════════════════════════════
class _PeriodChip extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _PeriodChip({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 40),
      itemBuilder: (_) => ['Today', 'This Week', 'This Month', 'All Time']
          .map((e) => PopupMenuItem(
                value: e,
                child: Text(e,
                    style: TextStyle(
                        fontWeight:
                            e == value ? FontWeight.w700 : FontWeight.w400)),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronDown,
                color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1) OVERVIEW TAB (Not used anymore - kept for reference)
// ═══════════════════════════════════════════════════════════════
// ignore: unused_element
class _OverviewTab extends StatelessWidget {
  final AdminController admin;
  final String period;
  const _OverviewTab({required this.admin, required this.period});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Compute some data from admin
    final totalCoins = admin.allUsers.fold<int>(0, (s, u) => s + u.totalCoins);
    final avgCoinsPerUser =
        admin.totalUsers > 0 ? (totalCoins / admin.totalUsers).round() : 0;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // ── Scan Activity Chart ──
        _sectionHeader(cs, 'Scan Activity', LucideIcons.activity),
        const SizedBox(height: 14),
        _ChartCard(
          cs: cs,
          title: 'Daily Scans',
          subtitle: 'Average ${(admin.totalScans / 30).round()} scans/day',
          barColor: const Color(0xFF0BA360),
          data: _generateBarData(7, 80, 350),
        ),

        const SizedBox(height: 24),

        // ── Platform Health ──
        _sectionHeader(cs, 'Platform Health', LucideIcons.heartPulse),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.bellRing,
                  title: 'Auto Notify',
                  value: 'Water',
                  color: const Color(0xFF0BA360),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AutoNotificationSenderPage()))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.zap,
                  title: 'API Latency',
                  value: '—',
                  color: const Color(0xFFFF8F00)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.database,
                  title: 'DB Queries',
                  value: '—',
                  color: const Color(0xFF5C6BC0)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.hardDrive,
                  title: 'Storage',
                  value: '—',
                  color: const Color(0xFF00897B)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Disease Detection Stats ──
        _sectionHeader(cs, 'Disease Detection', LucideIcons.alertTriangle),
        const SizedBox(height: 14),
        _ChartCard(
          cs: cs,
          title: 'Weekly Detections',
          subtitle: '${admin.diseasesDetected} total alerts',
          barColor: const Color(0xFFE53935),
          data: _generateBarData(7, 20, 180),
        ),
        const SizedBox(height: 14),
        _diseaseBreakdown(cs),

        const SizedBox(height: 24),

        // ── Coin Economy ──
        _sectionHeader(cs, 'Coin Economy', LucideIcons.coins),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.coins,
                  title: 'Total Minted',
                  value: '$totalCoins',
                  color: const Color(0xFFFF8F00)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.piggyBank,
                  title: 'Avg / User',
                  value: '$avgCoinsPerUser',
                  color: const Color(0xFF0BA360)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Quick Navigation ──
        _sectionHeader(cs, 'Detailed Reports', LucideIcons.fileBarChart),
        const SizedBox(height: 14),
        _reportTile(cs,
            icon: LucideIcons.scan,
            title: 'Scan Activity Report',
            subtitle: 'Full scan history & AI accuracy',
            color: const Color(0xFF0BA360),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TreeScansStatsPage()))),
        const SizedBox(height: 8),
        _reportTile(cs,
            icon: LucideIcons.alertTriangle,
            title: 'Disease Report',
            subtitle: 'Detection trends & alerts',
            color: const Color(0xFFE53935),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DiseaseStatsPage()))),
        const SizedBox(height: 8),
        _reportTile(cs,
            icon: LucideIcons.bellRing,
            title: 'Auto Watering Notifications',
            subtitle: 'Send watering reminders to all',
            color: const Color(0xFF0BA360),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AutoNotificationSenderPage()))),
        const SizedBox(height: 8),
        _reportTile(cs,
            icon: LucideIcons.megaphone,
            title: 'Custom Notifications',
            subtitle: 'Send targeted notifications',
            color: const Color(0xFF6366F1),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CustomNotificationSenderPage()))),
      ],
    );
  }

  Widget _diseaseBreakdown(ColorScheme cs) {
    // Use real scan data from admin controller
    // If no disease data, show empty state
    final diseases = [
      _DiseaseEntry('Apple Scab', 0, const Color(0xFFE53935)),
      _DiseaseEntry('Black Rot', 0, const Color(0xFFFF8F00)),
      _DiseaseEntry('Cedar Rust', 0, const Color(0xFFFF6F00)),
      _DiseaseEntry('Powdery Mildew', 0, const Color(0xFF5C6BC0)),
      _DiseaseEntry('Healthy', 0, const Color(0xFF2E7D32)),
    ];
    final total = diseases.fold<int>(0, (s, d) => s + d.count);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detection Breakdown',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          Text('Top identified conditions',
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
          const SizedBox(height: 16),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: diseases.map((d) {
                  return Expanded(
                    flex: d.count,
                    child: Container(color: d.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...diseases.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: d.color,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(d.name,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface)),
                    ),
                    Text('${((d.count / total) * 100).round()}%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface.withOpacity(0.6))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<double> _generateBarData(int count, int minVal, int maxVal) {
    // Return zeros when no real data available
    return List.generate(count, (_) => 0.0);
  }
}

class _DiseaseEntry {
  final String name;
  final int count;
  final Color color;
  const _DiseaseEntry(this.name, this.count, this.color);
}

// ═══════════════════════════════════════════════════════════════
// 2) USERS TAB
// ═══════════════════════════════════════════════════════════════
class _UsersTab extends StatelessWidget {
  final AdminController admin;
  final String period;
  const _UsersTab({required this.admin, required this.period});

  // ignore: unused_element
  double get _periodMultiplier {
    switch (period) {
      case 'Today':
        return 0.15;
      case 'This Week':
        return 1.0;
      case 'This Month':
        return 4.0;
      case 'All Time':
        return 12.0;
      default:
        return 1.0;
    }
  }

  int get _chartBarCount {
    switch (period) {
      case 'Today':
        return 6; // hours
      case 'This Week':
        return 7; // days
      case 'This Month':
        return 4; // weeks
      case 'All Time':
        return 6; // months
      default:
        return 7;
    }
  }

  String get _chartSubtitleLabel {
    switch (period) {
      case 'Today':
        return 'today';
      case 'This Week':
        return 'this week';
      case 'This Month':
        return 'this month';
      case 'All Time':
        return 'all time';
      default:
        return 'this week';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final users = admin.allUsers;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Active Today: users with at least one activity stat dated today
    final activeToday = users
        .where((u) => u.stats.any((s) {
              final d = s.date;
              return d != null &&
                  d.year == today.year &&
                  d.month == today.month &&
                  d.day == today.day;
            }))
        .length;

    // Avg Session: average activity count per user (total stats / total users)
    final totalStats = users.fold<int>(0, (s, u) => s + u.stats.length);
    final avgSession = users.isEmpty
        ? '—'
        : '${(totalStats / users.length).toStringAsFixed(1)}';

    // New registrations in the selected period
    DateTime periodStart;
    switch (period) {
      case 'Today':
        periodStart = today;
        break;
      case 'This Week':
        periodStart = today.subtract(Duration(days: today.weekday - 1));
        break;
      case 'This Month':
        periodStart = DateTime(today.year, today.month, 1);
        break;
      case 'All Time':
      default:
        periodStart = DateTime(2000);
        break;
    }
    final newInPeriod =
        users.where((u) => !u.createdAt.isBefore(periodStart)).length;

    // Compute per-period registration counts for growth chart
    final totalCoins = users.fold<int>(0, (s, u) => s + u.totalCoins);

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // ── User Metrics ──
        _sectionHeader(cs, 'User Metrics', LucideIcons.barChart2),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.users,
                  title: 'Total Users',
                  value: users.length.toString(),
                  color: const Color(0xFF5C6BC0)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.userCheck,
                  title: 'Active Today',
                  value: activeToday.toString(),
                  color: const Color(0xFF0BA360)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.coins,
                  title: 'Coins Earned',
                  value: totalCoins.toString(),
                  color: const Color(0xFFFF8F00)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.clock,
                  title: 'Avg Session',
                  value: avgSession,
                  color: const Color(0xFF00897B)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── User Growth Chart ──
        _sectionHeader(cs, 'User Growth', LucideIcons.trendingUp),
        const SizedBox(height: 14),
        _ChartCard(
          cs: cs,
          title: 'New Registrations',
          subtitle: '$newInPeriod users $_chartSubtitleLabel',
          barColor: const Color(0xFF5C6BC0),
          data: _generateGrowthData(_chartBarCount),
          period: period,
        ),

        const SizedBox(height: 24),

        // ── Role Distribution ──
        _sectionHeader(cs, 'Role Distribution', LucideIcons.pieChart),
        const SizedBox(height: 14),
        _roleDistribution(cs, users),

        const SizedBox(height: 24),

        // ── Community Engagement ──
        _sectionHeader(cs, 'Community Engagement', LucideIcons.treeDeciduous),
        const SizedBox(height: 14),
        ...admin.communities.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _communityEngagement(cs, c),
            )),
      ],
    );
  }

  Widget _roleDistribution(ColorScheme cs, List<AppUser> users) {
    final roles = <String, int>{};
    for (final u in users) {
      roles[u.role] = (roles[u.role] ?? 0) + 1;
    }
    final total = users.length;
    final roleColors = {
      'Admin': const Color(0xFFE53935),
      'Moderator': const Color(0xFFFF8F00),
      'User': const Color(0xFF0BA360),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          // Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: roles.entries.map((e) {
                  return Expanded(
                    flex: e.value,
                    child: Container(color: roleColors[e.key] ?? cs.primary),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...roles.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: roleColors[e.key] ?? cs.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.key,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface)),
                    ),
                    Text('${e.value}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                    const SizedBox(width: 6),
                    Text(
                        '(${total > 0 ? ((e.value / total) * 100).round() : 0}%)',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _topEarnersList(ColorScheme cs, List<AppUser> users) {
    final sorted = [...users]
      ..sort((a, b) => b.totalCoins.compareTo(a.totalCoins));
    final top = sorted.take(5).toList();

    if (top.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text('No user data available',
              style: TextStyle(color: cs.onSurface.withOpacity(0.4))),
        ),
      );
    }

    final medals = ['🥇', '🥈', '🥉', '4', '5'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: List.generate(top.length, (i) {
          final u = top[i];
          final community = admin.getCommunityNameForUser(u.email);
          return Column(
            children: [
              if (i > 0)
                Divider(
                    height: 1,
                    color: cs.onSurface.withOpacity(0.06),
                    indent: 56,
                    endIndent: 16),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: i < 3
                          ? Text(medals[i],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18))
                          : CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  cs.surfaceContainerHighest.withOpacity(0.5),
                              child: Text(medals[i],
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface.withOpacity(0.5))),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface)),
                          Text(community,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withOpacity(0.45))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8F00).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.coins,
                              size: 13, color: Color(0xFFFF8F00)),
                          const SizedBox(width: 4),
                          Text('${u.totalCoins}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF8F00))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _communityEngagement(ColorScheme cs, AdminCommunity c) {
    final memberCoins = c.members.fold<int>(0, (s, m) => s + m.totalCoins);
    final totalActivities =
        c.members.fold<int>(0, (s, m) => s + m.stats.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.treeDeciduous,
                    color: cs.primary, size: 18),
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
                            color: cs.onSurface)),
                    Text(c.location,
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(0.45))),
                  ],
                ),
              ),
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
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat(
                  cs, LucideIcons.users, '${c.members.length}', 'Members'),
              const SizedBox(width: 16),
              _miniStat(cs, LucideIcons.coins, '$memberCoins', 'Coins'),
              const SizedBox(width: 16),
              _miniStat(
                  cs, LucideIcons.activity, '$totalActivities', 'Activities'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(ColorScheme cs, IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: cs.primary.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
        const SizedBox(width: 3),
        Text(label,
            style:
                TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.4))),
      ],
    );
  }

  List<double> _generateGrowthData(int count) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final users = admin.allUsers;
    final result = List<double>.filled(count, 0);

    for (final u in users) {
      int bucket;
      switch (period) {
        case 'Today':
          if (u.createdAt.year == today.year &&
              u.createdAt.month == today.month &&
              u.createdAt.day == today.day) {
            bucket = (u.createdAt.hour ~/ 3).clamp(0, count - 1);
            result[bucket]++;
          }
          break;
        case 'This Week':
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          if (!u.createdAt.isBefore(weekStart)) {
            bucket = (u.createdAt.weekday - 1).clamp(0, count - 1);
            result[bucket]++;
          }
          break;
        case 'This Month':
          if (u.createdAt.year == today.year &&
              u.createdAt.month == today.month) {
            bucket = ((u.createdAt.day - 1) ~/ 7).clamp(0, count - 1);
            result[bucket]++;
          }
          break;
        case 'All Time':
        default:
          for (int i = 0; i < count; i++) {
            final m = DateTime(today.year, today.month - (count - 1) + i);
            if (u.createdAt.year == m.year && u.createdAt.month == m.month) {
              result[i]++;
              break;
            }
          }
          break;
      }
    }
    return result;
  }
}

// ═══════════════════════════════════════════════════════════════
// 3) COINS TAB
// ═══════════════════════════════════════════════════════════════
class _CoinsTab extends StatelessWidget {
  final AdminController admin;
  final String period;
  const _CoinsTab({required this.admin, required this.period});

  /// Returns the start DateTime for the current period, or null for All Time.
  DateTime? get _periodStart {
    final now = DateTime.now();
    switch (period) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This Week':
        final ws = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(ws.year, ws.month, ws.day);
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      default:
        return null; // All Time
    }
  }

  /// Sum of coins earned by [user] within the current period.
  int _userCoinsInPeriod(AppUser user) {
    final start = _periodStart;
    if (start == null) return user.totalCoins;
    return user.stats
        .where((s) => s.date != null && !s.date!.isBefore(start))
        .fold<int>(0, (sum, s) => sum + (s.coinsEarned ?? 0));
  }

  int get _chartBarCount {
    switch (period) {
      case 'Today':
        return 6; // hours
      case 'This Week':
        return 7; // days
      case 'This Month':
        return 4; // weeks
      case 'All Time':
        return 6; // months
      default:
        return 7;
    }
  }

  String get _chartSubtitleLabel {
    switch (period) {
      case 'Today':
        return 'today';
      case 'This Week':
        return 'this week';
      case 'This Month':
        return 'this month';
      case 'All Time':
        return 'all time';
      default:
        return 'this week';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final users = admin.allUsers;

    // Compute period-filtered coin metrics from real activity data
    final userCoinsList = users.map(_userCoinsInPeriod).toList();
    final totalCoins = userCoinsList.fold<int>(0, (s, c) => s + c);
    final avgCoinsPerUser =
        users.isNotEmpty ? (totalCoins / users.length).round() : 0;
    final maxCoins = userCoinsList.isEmpty
        ? 0
        : userCoinsList.reduce((a, b) => a > b ? a : b);

    // Top earners sorted by period-filtered coins
    final sortedUsers = List<AppUser>.from(users)
      ..sort((a, b) => _userCoinsInPeriod(b).compareTo(_userCoinsInPeriod(a)));
    final topEarners = sortedUsers.take(5).toList();

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // ── Coin Overview ──
        _sectionHeader(cs, 'Coin Overview', LucideIcons.coins),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.coins,
                  title: 'Total Minted',
                  value: _formatNum(totalCoins),
                  color: const Color(0xFFFF8F00)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.piggyBank,
                  title: 'Avg / User',
                  value: avgCoinsPerUser.toString(),
                  color: const Color(0xFF0BA360)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.trophy,
                  title: 'Highest',
                  value: maxCoins.toString(),
                  color: const Color(0xFF5C6BC0)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.users,
                  title: 'Earners',
                  value: users.where((u) => u.totalCoins > 0).length.toString(),
                  color: const Color(0xFF00897B)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Coin Distribution Chart ──
        _sectionHeader(cs, 'Coin Distribution', LucideIcons.barChart2),
        const SizedBox(height: 14),
        _ChartCard(
          cs: cs,
          title: 'Earnings Trend',
          subtitle: 'Coins earned $_chartSubtitleLabel',
          barColor: const Color(0xFFFF8F00),
          data: _generateCoinData(_chartBarCount),
          period: period,
        ),

        const SizedBox(height: 24),

        // ── Top Earners ──
        _sectionHeader(cs, 'Top Earners', LucideIcons.trophy),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: topEarners.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              final colors = [
                const Color(0xFFFFD700),
                const Color(0xFFC0C0C0),
                const Color(0xFFCD7F32),
                cs.primary,
                cs.primary.withOpacity(0.7),
              ];
              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: colors[index].withOpacity(0.2),
                  child: Text('${index + 1}',
                      style: TextStyle(
                          color: colors[index], fontWeight: FontWeight.bold)),
                ),
                title: Text(user.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(user.email,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8F00).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.coins,
                          size: 14, color: Color(0xFFFF8F00)),
                      const SizedBox(width: 4),
                      Text('${_userCoinsInPeriod(user)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF8F00))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // ── Coin by Community ──
        _sectionHeader(cs, 'Coins by Community', LucideIcons.treeDeciduous),
        const SizedBox(height: 14),
        ...admin.communities.map((c) {
          final communityCoins =
              c.members.fold<int>(0, (s, u) => s + u.totalCoins);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8F00).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.treeDeciduous,
                        color: Color(0xFF0BA360), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${c.members.length} members',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8F00).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.coins,
                            size: 16, color: Color(0xFFFF8F00)),
                        const SizedBox(width: 6),
                        Text('$communityCoins',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF8F00))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  List<double> _generateCoinData(int count) {
    final now = DateTime.now();
    final allStats = admin.allUsers.expand((u) => u.stats).toList();

    if (period == 'Today') {
      final today = DateTime(now.year, now.month, now.day);
      return List.generate(count, (i) {
        final start = today.add(Duration(hours: i * 4));
        final end = start.add(const Duration(hours: 4));
        return allStats
            .where((s) =>
                s.date != null &&
                !s.date!.isBefore(start) &&
                s.date!.isBefore(end))
            .fold<double>(0, (sum, s) => sum + (s.coinsEarned ?? 0));
      });
    } else if (period == 'This Week') {
      final ws = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(ws.year, ws.month, ws.day);
      return List.generate(count, (i) {
        final day = weekStart.add(Duration(days: i));
        return allStats
            .where((s) =>
                s.date != null &&
                s.date!.year == day.year &&
                s.date!.month == day.month &&
                s.date!.day == day.day)
            .fold<double>(0, (sum, s) => sum + (s.coinsEarned ?? 0));
      });
    } else if (period == 'This Month') {
      final monthStart = DateTime(now.year, now.month, 1);
      return List.generate(count, (i) {
        final start = monthStart.add(Duration(days: i * 7));
        final end = start.add(const Duration(days: 7));
        return allStats
            .where((s) =>
                s.date != null &&
                !s.date!.isBefore(start) &&
                s.date!.isBefore(end))
            .fold<double>(0, (sum, s) => sum + (s.coinsEarned ?? 0));
      });
    } else {
      // All Time: 6 rolling months
      return List.generate(count, (i) {
        final month = DateTime(now.year, now.month - (count - 1 - i), 1);
        return allStats
            .where((s) =>
                s.date != null &&
                s.date!.year == month.year &&
                s.date!.month == month.month)
            .fold<double>(0, (sum, s) => sum + (s.coinsEarned ?? 0));
      });
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 4) ENVIRONMENT TAB (kept for reference)
// ═══════════════════════════════════════════════════════════════
// ignore: unused_element
class _EnvironmentTab extends StatelessWidget {
  final AdminController admin;
  const _EnvironmentTab({required this.admin});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Compute environmental impact from data
    final totalPlantings = admin.allUsers.fold<int>(
        0,
        (s, u) =>
            s +
            u.stats
                .where((st) => st.action?.toLowerCase() == 'planting')
                .length);
    final totalWaterings = admin.allUsers.fold<int>(
        0,
        (s, u) =>
            s +
            u.stats
                .where((st) => st.action?.toLowerCase() == 'watering')
                .length);
    final totalHealthChecks = admin.allUsers.fold<int>(
        0,
        (s, u) =>
            s +
            u.stats
                .where((st) => st.action?.toLowerCase() == 'checking health')
                .length);

    // Estimated CO2 offset: ~ 22kg per tree per year
    final co2Offset = totalPlantings * 22;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // ── Environmental Impact ──
        _sectionHeader(cs, 'Environmental Impact', LucideIcons.leaf),
        const SizedBox(height: 14),
        _impactCard(cs),

        const SizedBox(height: 24),

        // ── Activity Breakdown ──
        _sectionHeader(cs, 'Activity Breakdown', LucideIcons.barChart2),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.treePine,
                  title: 'Plantings',
                  value: totalPlantings.toString(),
                  color: const Color(0xFF0BA360)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.droplets,
                  title: 'Waterings',
                  value: totalWaterings.toString(),
                  color: const Color(0xFF1E88E5)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.clipboardCheck,
                  title: 'Health Checks',
                  value: totalHealthChecks.toString(),
                  color: const Color(0xFF00897B)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.wind,
                  title: 'CO2 Offset',
                  value: '${co2Offset}kg',
                  color: const Color(0xFF546E7A)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Planting Activity ──
        _sectionHeader(cs, 'Planting Activity', LucideIcons.treeDeciduous),
        const SizedBox(height: 14),
        _ChartCard(
          cs: cs,
          title: 'Weekly Plantings',
          subtitle: '$totalPlantings total plantings recorded',
          barColor: const Color(0xFF0BA360),
          data: _generatePlantingData(7),
        ),

        const SizedBox(height: 24),

        // ── Plant Species Distribution ──
        _sectionHeader(cs, 'Species Distribution', LucideIcons.flower2),
        const SizedBox(height: 14),
        _speciesDistribution(cs),

        const SizedBox(height: 24),

        // ── Community QR Tracking ──
        _sectionHeader(cs, 'QR Code Tracking', LucideIcons.qrCode),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.qrCode,
                  title: 'Total QR',
                  value: admin.totalQrCodes.toString(),
                  color: const Color(0xFFFF8F00)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(cs,
                  icon: LucideIcons.treeDeciduous,
                  title: 'Communities',
                  value: admin.communities.length.toString(),
                  color: const Color(0xFF5C6BC0)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Sustainability Goals ──
        _sectionHeader(cs, 'Sustainability Goals', LucideIcons.target),
        const SizedBox(height: 14),
        _goalProgress(cs, 'Trees Planted', totalPlantings, 100,
            const Color(0xFF0BA360), LucideIcons.treePine),
        const SizedBox(height: 10),
        _goalProgress(cs, 'Disease Scans', admin.totalScans, 5000,
            const Color(0xFFE53935), LucideIcons.scan),
        const SizedBox(height: 10),
        _goalProgress(cs, 'Active Users', admin.totalUsers, 50,
            const Color(0xFF5C6BC0), LucideIcons.users),
        const SizedBox(height: 10),
        _goalProgress(cs, 'CO2 Offset (kg)', co2Offset, 1000,
            const Color(0xFF546E7A), LucideIcons.wind),
      ],
    );
  }

  Widget _impactCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0BA360),
            const Color(0xFF0BA360).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.globe2,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Eco Impact Score',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    Text('Based on community activity',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _impactMetric(LucideIcons.treePine, 'Trees',
                  '${admin.allUsers.fold<int>(0, (s, u) => s + u.stats.where((st) => st.action?.toLowerCase() == "planting").length)}'),
              Container(
                  width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
              _impactMetric(LucideIcons.droplets, 'Water Events',
                  '${admin.allUsers.fold<int>(0, (s, u) => s + u.stats.where((st) => st.action?.toLowerCase() == "watering").length)}'),
              Container(
                  width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
              _impactMetric(LucideIcons.scan, 'Total Scans',
                  _formatNum(admin.totalScans)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _impactMetric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _speciesDistribution(ColorScheme cs) {
    // Aggregate plant types from all stats
    final speciesMap = <String, int>{};
    for (final u in admin.allUsers) {
      for (final s in u.stats) {
        if (s.type != null && s.type != 'Unknown') {
          speciesMap[s.type!] = (speciesMap[s.type!] ?? 0) + 1;
        }
      }
    }

    if (speciesMap.isEmpty) {
      speciesMap['No Data'] = 1;
    }

    final colors = [
      const Color(0xFF0BA360),
      const Color(0xFF5C6BC0),
      const Color(0xFFFF8F00),
      const Color(0xFFE53935),
      const Color(0xFF00897B),
      const Color(0xFF546E7A),
    ];
    final total = speciesMap.values.fold<int>(0, (s, v) => s + v);
    final entries = speciesMap.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: List.generate(entries.length, (i) {
                  return Expanded(
                    flex: entries[i].value,
                    child: Container(color: colors[i % colors.length]),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(entries.length, (i) {
            final e = entries[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.key,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
                  ),
                  Text('${e.value}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(width: 6),
                  Text(
                      '(${total > 0 ? ((e.value / total) * 100).round() : 0}%)',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withOpacity(0.4))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _goalProgress(ColorScheme cs, String title, int current, int target,
      Color color, IconData icon) {
    final progress = (current / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
              ),
              Text('$current / $target',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: cs.onSurface.withOpacity(0.08),
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(progress * 100).round()}%',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.4))),
          ),
        ],
      ),
    );
  }

  List<double> _generatePlantingData(int count) {
    return List.generate(count, (_) => 0.0);
  }

  static String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ═══════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════

Widget _sectionHeader(ColorScheme cs, String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, size: 18, color: cs.primary),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface)),
    ],
  );
}

Widget _statCard(
  ColorScheme cs, {
  required IconData icon,
  required String title,
  required String value,
  required Color color,
  VoidCallback? onTap,
}) {
  return Material(
    color: cs.surfaceContainerHighest.withOpacity(0.25),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(title.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: cs.onSurface.withOpacity(0.45))),
          ],
        ),
      ),
    ),
  );
}

Widget _reportTile(
  ColorScheme cs, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return Material(
    color: cs.surfaceContainerHighest.withOpacity(0.2),
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withOpacity(0.45))),
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

// ═══════════════════════════════════════════════════════════════
// CUSTOM BAR CHART WIDGET (styled like Scan Trend Chart)
// ═══════════════════════════════════════════════════════════════
class _ChartCard extends StatelessWidget {
  final ColorScheme cs;
  final String title;
  final String subtitle;
  final Color barColor;
  final List<double> data;
  final String? period;

  const _ChartCard({
    required this.cs,
    required this.title,
    required this.subtitle,
    required this.barColor,
    required this.data,
    this.period,
  });

  List<String> get _labels {
    switch (period) {
      case 'Today':
        return ['6AM', '9AM', '12PM', '3PM', '6PM', '9PM'];
      case 'This Week':
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 'This Month':
        return ['W1', 'W2', 'W3', 'W4'];
      case 'All Time':
        const abbr = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        final now = DateTime.now();
        return List.generate(
            6, (i) => abbr[DateTime(now.year, now.month - 5 + i).month - 1]);
      default:
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
  }

  String get _periodLabel {
    switch (period) {
      case 'Today':
        return 'Today';
      case 'This Week':
        return '7 Days';
      case 'This Month':
        return '4 Weeks';
      case 'All Time':
        return '6 Months';
      default:
        return '7 Days';
    }
  }

  int get _highlightIndex {
    switch (period) {
      case 'Today':
        return DateTime.now().hour ~/ 3;
      case 'This Week':
        return DateTime.now().weekday - 1;
      case 'This Month':
        return (DateTime.now().day - 1) ~/ 7;
      case 'All Time':
        return _labels.length - 1;
      default:
        return DateTime.now().weekday - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = data.reduce(max);
    final total = data.reduce((a, b) => a + b).round();
    final labels = _labels;
    final highlightIdx = _highlightIndex.clamp(0, labels.length - 1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header row with title & period badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(total.toString(),
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.trendingUp,
                                  color: Colors.green, size: 12),
                              const SizedBox(width: 4),
                              Text('+${(total * 0.12).round()}%',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_periodLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: barColor,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(min(data.length, labels.length), (i) {
              final height = maxVal > 0 ? (data[i] / maxVal) * 100 : 20;
              final isHighlighted = i == highlightIdx;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(data[i].round().toString(),
                            style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurface.withOpacity(0.5),
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: height.clamp(20, 100).toDouble(),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isHighlighted
                                ? [barColor, barColor.withOpacity(0.6)]
                                : [
                                    barColor.withOpacity(0.3),
                                    barColor.withOpacity(0.15)
                                  ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(labels[i],
                          style: TextStyle(
                              fontSize: 10,
                              color: isHighlighted
                                  ? barColor
                                  : cs.onSurface.withOpacity(0.4),
                              fontWeight: isHighlighted
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
