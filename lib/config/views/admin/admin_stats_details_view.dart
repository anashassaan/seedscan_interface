import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../services/database_service.dart';

// --- 1. AUTO NOTIFICATION SENDER PAGE ---
class AutoNotificationSenderPage extends StatefulWidget {
  const AutoNotificationSenderPage({super.key});

  @override
  State<AutoNotificationSenderPage> createState() =>
      _AutoNotificationSenderPageState();
}

class _AutoNotificationSenderPageState
    extends State<AutoNotificationSenderPage> {
  bool _isSending = false;
  bool _sent = false;
  int _notificationsSent = 0;

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);
    final cs = Theme.of(context).colorScheme;

    // Collect all plants from all communities
    final List<Map<String, dynamic>> allPlants = [];
    for (var community in admin.communities) {
      for (var member in community.members) {
        for (var stat in member.stats) {
          if (stat.action == 'Planting' && stat.type != null) {
            allPlants.add({
              'plantName': stat.type,
              'communityName': community.name,
              'location': community.location,
              'memberName': member.name,
            });
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Notifications',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Stats Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF0BA360), const Color(0xFF3CBA92)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0BA360).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.bellRing,
                      color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Watering Reminder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send watering notifications to all ${admin.communities.length} communities',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will send watering reminders for ${allPlants.length} plants across all communities.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Plants Preview
            Text(
              'Plants to Notify (${allPlants.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Plants List
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withOpacity(0.2)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: allPlants.length > 10 ? 10 : allPlants.length,
                separatorBuilder: (_, __) =>
                    Divider(color: cs.outline.withOpacity(0.1)),
                itemBuilder: (context, index) {
                  final plant = allPlants[index];
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.flower2,
                          color: Colors.green, size: 20),
                    ),
                    title: Text(
                      plant['plantName'] ?? 'Unknown Plant',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${plant['communityName']} • ${plant['location']}',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withOpacity(0.6)),
                    ),
                    trailing: Icon(
                      LucideIcons.droplet,
                      color: Colors.blue.withOpacity(0.7),
                      size: 18,
                    ),
                  );
                },
              ),
            ),
            if (allPlants.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... and ${allPlants.length - 10} more plants',
                  style: TextStyle(
                      color: cs.onSurface.withOpacity(0.5), fontSize: 12),
                ),
              ),
            const SizedBox(height: 32),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSending
                    ? null
                    : () async {
                        setState(() {
                          _isSending = true;
                          _sent = false;
                        });
                        final db = DatabaseService();
                        final auth =
                            Provider.of<AuthController>(context, listen: false);
                        final adminId = auth.userId ?? 'admin';
                        int sent = 0;
                        try {
                          // Collect unique member IDs across all communities
                          final memberIds = <String>{};
                          for (var community in admin.communities) {
                            for (var member in community.members) {
                              if (member.id.isNotEmpty)
                                memberIds.add(member.id);
                            }
                          }
                          if (memberIds.isNotEmpty) {
                            for (final uid in memberIds) {
                              await db.createNotification(
                                recipientId: uid,
                                senderId: adminId,
                                type: 'watering',
                                title: '\u{1F4A7} Watering Reminder',
                                body:
                                    "It's time to water your plants! Check your garden and give them some love today.",
                              );
                              sent++;
                            }
                          } else {
                            // Broadcast to all if no specific members loaded
                            await db.createNotification(
                              recipientId: 'all',
                              senderId: adminId,
                              type: 'watering',
                              title: '\u{1F4A7} Watering Reminder',
                              body: "It's time to water your plants!",
                            );
                            sent = 1;
                          }
                        } catch (e) {
                          debugPrint('[AutoNotify] error: \$e');
                        }
                        setState(() {
                          _isSending = false;
                          _sent = true;
                          _notificationsSent = sent;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sent $sent watering reminders!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0BA360),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _sent ? LucideIcons.checkCircle : LucideIcons.send,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _sent
                                ? 'Sent Successfully!'
                                : 'Send Watering Reminders',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Status message
            if (_sent)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Successfully sent $_notificationsSent notifications to all users!',
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w500),
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

// --- 2. TREE SCANS DETAIL PAGE --- (Premium Redesign)
class TreeScansStatsPage extends StatefulWidget {
  const TreeScansStatsPage({super.key});

  @override
  State<TreeScansStatsPage> createState() => _TreeScansStatsPageState();
}

class _TreeScansStatsPageState extends State<TreeScansStatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Today';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 24),
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
                // Back button & Title
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.arrowLeft,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scan Activity',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          Text('AI-powered plant analysis',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Period Filter
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          icon: const Icon(LucideIcons.chevronDown,
                              color: Colors.white, size: 16),
                          dropdownColor: const Color(0xFF0BA360),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          isDense: true,
                          items: [
                            'Today',
                            'This Week',
                            'This Month',
                            'All Time'
                          ]
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedPeriod = v ?? 'Today'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Stats Row
                Row(
                  children: [
                    _buildHeaderStat(
                      value: _formatNum(admin.totalPlants),
                      label: 'Trees Planted',
                      icon: LucideIcons.treeDeciduous,
                    ),
                    const SizedBox(width: 12),
                    _buildHeaderStat(
                      value: _formatNum(admin.healthyPlants),
                      label: 'Healthy',
                      icon: LucideIcons.checkCircle,
                    ),
                    const SizedBox(width: 12),
                    _buildHeaderStat(
                      value:
                          _formatNum(admin.diseasedPlants + admin.deadPlants),
                      label: 'Issues Found',
                      icon: LucideIcons.alertTriangle,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ═══════════ SCROLLABLE CONTENT ═══════════
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF0BA360),
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Scan Trend Chart ──
                    _buildSectionTitle(
                        cs, 'Scan Trends', LucideIcons.trendingUp),
                    const SizedBox(height: 14),
                    _buildTrendChart(cs, admin, _selectedPeriod),
                    const SizedBox(height: 28),

                    // ── Health Status ──
                    _buildSectionTitle(
                        cs, 'Health Status', LucideIcons.heartPulse),
                    const SizedBox(height: 14),
                    _buildHealthStatusChart(cs, admin, _selectedPeriod),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ColorScheme cs, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
      ],
    );
  }

  Widget _buildTrendChart(
      ColorScheme cs, AdminController admin, String period) {
    final now = DateTime.now();
    final stats = admin.allPlantingStats;

    List<String> labels;
    List<int> values;
    String periodLabel;
    int highlightIndex;

    switch (period) {
      case 'Today':
        labels = ['6AM', '9AM', '12PM', '3PM', '6PM', '9PM'];
        values = List.filled(6, 0);
        periodLabel = 'Today';
        highlightIndex = (now.hour ~/ 3).clamp(0, 5);
        for (final s in stats) {
          final d = s.date;
          if (d != null &&
              d.year == now.year &&
              d.month == now.month &&
              d.day == now.day) {
            final bucket = (d.hour ~/ 3).clamp(0, 5);
            values[bucket]++;
          }
        }
        break;
      case 'This Week':
        labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        values = List.filled(7, 0);
        periodLabel = '7 Days';
        highlightIndex = (now.weekday - 1).clamp(0, 6);
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        for (final s in stats) {
          final d = s.date;
          if (d != null &&
              !d.isBefore(
                  DateTime(weekStart.year, weekStart.month, weekStart.day))) {
            final bucket = d.weekday - 1;
            values[bucket]++;
          }
        }
        break;
      case 'This Month':
        labels = ['W1', 'W2', 'W3', 'W4'];
        values = List.filled(4, 0);
        periodLabel = '4 Weeks';
        highlightIndex = ((now.day - 1) ~/ 7).clamp(0, 3);
        for (final s in stats) {
          final d = s.date;
          if (d != null && d.year == now.year && d.month == now.month) {
            final bucket = ((d.day - 1) ~/ 7).clamp(0, 3);
            values[bucket]++;
          }
        }
        break;
      case 'All Time':
      default:
        // Last 6 calendar months ending this month
        labels = List.generate(6, (i) {
          final m = DateTime(now.year, now.month - 5 + i);
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
          return abbr[m.month - 1];
        });
        values = List.filled(6, 0);
        periodLabel = '6 Months';
        highlightIndex = 5;
        for (final s in stats) {
          final d = s.date;
          if (d == null) continue;
          for (int i = 0; i < 6; i++) {
            final m = DateTime(now.year, now.month - 5 + i);
            if (d.year == m.year && d.month == m.month) {
              values[i]++;
              break;
            }
          }
        }
        break;
    }

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1 : maxVal;
    final total = values.reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$period Overview',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(_formatNum(total),
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
                            Text(total > 0 ? '+$total' : '—',
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(periodLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(labels.length, (i) {
              final height = (values[i] / safeMax) * 100;
              final isHighlighted =
                  i == highlightIndex.clamp(0, labels.length - 1);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_formatNum(values[i]),
                            style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurface.withOpacity(0.5),
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: height.clamp(20, 100),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isHighlighted
                                ? [
                                    const Color(0xFF0BA360),
                                    const Color(0xFF3CBA92)
                                  ]
                                : [
                                    cs.primary.withOpacity(0.3),
                                    cs.primary.withOpacity(0.15)
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
                                  ? cs.primary
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

  // ignore: unused_element
  Widget _buildAccuracyCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAccuracyItem(
                  cs,
                  label: 'High',
                  value: '—',
                  progress: 0.0,
                  color: const Color(0xFF0BA360),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAccuracyItem(
                  cs,
                  label: 'Medium',
                  value: '—',
                  progress: 0.0,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAccuracyItem(
                  cs,
                  label: 'Low',
                  value: '—',
                  progress: 0.0,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0BA360).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: const Color(0xFF0BA360).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0BA360).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.sparkles,
                      color: Color(0xFF0BA360), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Model Performance',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      Text('MobileNetV3 Apple Disease',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(0.5))),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0BA360),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('—',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyItem(
    ColorScheme cs, {
    required String label,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 55,
                width: 55,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildHealthStatusChart(
      ColorScheme cs, AdminController admin, String period) {
    // Use real health distribution from Appwrite (period filter is visual only)
    final healthyCount = admin.healthyPlants;
    final issueCount = admin.diseasedPlants + admin.deadPlants;
    final total = healthyCount + issueCount;
    final healthyPercent = total > 0 ? (healthyCount / total * 100) : 0.0;
    final issuePercent = total > 0 ? (issueCount / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Circular Chart
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: _HealthPieChartPainter(
                      healthyPercent: healthyPercent,
                      issuePercent: issuePercent,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${healthyPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0BA360),
                      ),
                    ),
                    Text(
                      'Healthy',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Row(
            children: [
              Expanded(
                child: _buildHealthLegendItem(
                  cs,
                  'Healthy',
                  healthyCount,
                  healthyPercent,
                  const Color(0xFF0BA360),
                  LucideIcons.checkCircle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHealthLegendItem(
                  cs,
                  'Issue Found',
                  issueCount,
                  issuePercent,
                  Colors.orange,
                  LucideIcons.alertTriangle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthLegendItem(
    ColorScheme cs,
    String label,
    int count,
    double percent,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          Text(
            '${percent.toStringAsFixed(1)}% of total',
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// --- 3. DISEASE REPORTS PAGE ---
class DiseaseStatsPage extends StatefulWidget {
  const DiseaseStatsPage({super.key});

  @override
  State<DiseaseStatsPage> createState() => _DiseaseStatsPageState();
}

class _DiseaseStatsPageState extends State<DiseaseStatsPage> {
  final Set<int> _expandedCommunities = {};

  // Model disease types
  static const List<String> diseaseTypes = [
    'Alternaria Leaf Spot',
    'Apple Scab',
    'Black Rot',
    'Brown Spot',
    'Cedar Apple Rust',
    'Grey Spot',
    'Mosaic',
    'Powdery Mildew',
  ];

  // Generate disease counts - returns zeros (no dummy data)
  Map<String, int> _generateDiseaseData(int communityIndex) {
    return {
      for (var disease in diseaseTypes) disease: 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Health Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroStats(context,
                title: "Critical Detections",
                value: "${admin.diseasesDetected}",
                subtitle: "Plants requiring attention",
                icon: LucideIcons.alertTriangle,
                color: Colors.orange),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3))),
              child: const Row(
                children: [
                  Icon(LucideIcons.info, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          "Fungal infections are the most common detection this week.",
                          style: TextStyle(fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Community-wise Disease Reports",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            // Community cards
            ...List.generate(admin.communities.length, (index) {
              final community = admin.communities[index];
              final isExpanded = _expandedCommunities.contains(index);
              final diseaseData = _generateDiseaseData(index);
              final totalDiseases = diseaseData.values.reduce((a, b) => a + b);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header (always visible)
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedCommunities.remove(index);
                          } else {
                            _expandedCommunities.add(index);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.trees,
                                color: Colors.red,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    community.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$totalDiseases issues detected",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronDown,
                              color: cs.onSurface.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expandable content
                    if (isExpanded)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: diseaseTypes.length,
                          itemBuilder: (context, diseaseIndex) {
                            final disease = diseaseTypes[diseaseIndex];
                            final count = diseaseData[disease] ?? 0;
                            final color = _getDiseaseColor(diseaseIndex);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    disease,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: color.withOpacity(0.9),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$count cases",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getDiseaseColor(int index) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.brown,
      Colors.amber,
      Colors.deepOrange,
      Colors.grey,
      Colors.green,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }
}

// --- 4. CUSTOM NOTIFICATION SENDER PAGE ---
class CustomNotificationSenderPage extends StatefulWidget {
  const CustomNotificationSenderPage({super.key});

  @override
  State<CustomNotificationSenderPage> createState() =>
      _CustomNotificationSenderPageState();
}

class _CustomNotificationSenderPageState
    extends State<CustomNotificationSenderPage> {
  String _notificationType = 'community'; // community, plantType, disease
  String? _selectedCommunity;
  String? _selectedPlantType;
  String? _selectedDisease;
  bool _allCommunities = false;
  bool _isSending = false;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  static const List<String> plantTypes = [
    'Apple Tree',
    'Oak',
    'Pine',
    'Cherry',
    'Maple',
    'Willow',
    'Mango',
    'Coconut',
    'Banana',
    'Lemon',
  ];

  static const List<String> diseaseTypes = [
    'Alternaria Leaf Spot',
    'Apple Scab',
    'Black Rot',
    'Brown Spot',
    'Cedar Apple Rust',
    'Grey Spot',
    'Mosaic',
    'Powdery Mildew',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  int _calculateRecipients(AdminController admin) {
    int count = 0;
    switch (_notificationType) {
      case 'community':
        if (_allCommunities) {
          count = admin.allMembers.length;
        } else if (_selectedCommunity != null) {
          final community = admin.communities.firstWhere(
            (c) => c.name == _selectedCommunity,
            orElse: () => admin.communities.first,
          );
          count = community.members.length;
        }
        break;
      case 'plantType':
        for (var community in admin.communities) {
          if (!_allCommunities && community.name != _selectedCommunity)
            continue;
          for (var member in community.members) {
            for (var stat in member.stats) {
              if (stat.type == _selectedPlantType) {
                count++;
                break;
              }
            }
          }
        }
        break;
      case 'disease':
        // Count from real community members with disease-related stats
        for (var community in admin.communities) {
          for (var member in community.members) {
            for (var stat in member.stats) {
              if (stat.action == 'Health Scan' ||
                  stat.action == 'Disease Detection') {
                count++;
                break;
              }
            }
          }
        }
        break;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);
    final cs = Theme.of(context).colorScheme;
    final communityNames = admin.communities.map((c) => c.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Notifications',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(LucideIcons.megaphone, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Custom Broadcast',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Send targeted notifications to specific groups',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notification Type Selection
            Text(
              'Notification Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTypeChip('Community', 'community', LucideIcons.users),
                const SizedBox(width: 8),
                _buildTypeChip('Plant Type', 'plantType', LucideIcons.flower2),
                const SizedBox(width: 8),
                _buildTypeChip('Disease', 'disease', LucideIcons.alertTriangle),
              ],
            ),
            const SizedBox(height: 24),

            // Community Selection (always shown for community & plantType)
            if (_notificationType == 'community' ||
                _notificationType == 'plantType') ...[
              Row(
                children: [
                  Checkbox(
                    value: _allCommunities,
                    onChanged: (val) {
                      setState(() {
                        _allCommunities = val ?? false;
                        if (_allCommunities) _selectedCommunity = null;
                      });
                    },
                    activeColor: const Color(0xFF6366F1),
                  ),
                  const Text('All Communities'),
                ],
              ),
              if (!_allCommunities)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withOpacity(0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select Community'),
                      value: _selectedCommunity,
                      items: communityNames
                          .map((name) => DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCommunity = val),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Plant Type Selection
            if (_notificationType == 'plantType') ...[
              Text(
                'Select Plant Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select Plant Type'),
                    value: _selectedPlantType,
                    items: plantTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedPlantType = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Disease Selection
            if (_notificationType == 'disease') ...[
              Text(
                'Select Disease Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select Disease'),
                    value: _selectedDisease,
                    items: diseaseTypes
                        .map((disease) => DropdownMenuItem(
                              value: disease,
                              child: Text(disease),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedDisease = val),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notifications will be sent to owners of plants affected by ${_selectedDisease ?? "selected disease"}',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurface.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),

            // Notification Title
            Text(
              'Notification Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter notification title...',
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outline.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outline.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notification Message
            Text(
              'Message',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your notification message...',
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outline.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outline.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recipients Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(LucideIcons.users, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimated Recipients',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '${_calculateRecipients(admin)} users',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canSend()
                    ? () async {
                        setState(() => _isSending = true);
                        final db = DatabaseService();
                        final auth =
                            Provider.of<AuthController>(context, listen: false);
                        final adminId = auth.userId ?? 'admin';
                        final title = _titleController.text.trim();
                        final body = _messageController.text.trim();
                        final memberIds = <String>{};
                        try {
                          switch (_notificationType) {
                            case 'community':
                              if (_allCommunities) {
                                for (var c in admin.communities) {
                                  for (var m in c.members) {
                                    if (m.id.isNotEmpty) memberIds.add(m.id);
                                  }
                                }
                              } else if (_selectedCommunity != null) {
                                final c = admin.communities.firstWhere(
                                    (c) => c.name == _selectedCommunity,
                                    orElse: () => admin.communities.first);
                                for (var m in c.members) {
                                  if (m.id.isNotEmpty) memberIds.add(m.id);
                                }
                              }
                              break;
                            case 'plantType':
                              for (var community in admin.communities) {
                                if (!_allCommunities &&
                                    community.name != _selectedCommunity) {
                                  continue;
                                }
                                for (var member in community.members) {
                                  if (member.stats.any(
                                      (s) => s.type == _selectedPlantType)) {
                                    if (member.id.isNotEmpty) {
                                      memberIds.add(member.id);
                                    }
                                  }
                                }
                              }
                              break;
                            case 'disease':
                              for (var community in admin.communities) {
                                for (var member in community.members) {
                                  if (member.stats.any((s) =>
                                      s.action == 'Health Scan' ||
                                      s.action == 'Disease Detection')) {
                                    if (member.id.isNotEmpty) {
                                      memberIds.add(member.id);
                                    }
                                  }
                                }
                              }
                              break;
                          }
                          if (memberIds.isNotEmpty) {
                            for (final uid in memberIds) {
                              await db.createNotification(
                                recipientId: uid,
                                senderId: adminId,
                                type: _notificationType == 'disease'
                                    ? 'disease'
                                    : 'system',
                                title: title,
                                body: body,
                              );
                            }
                          } else {
                            await db.createNotification(
                              recipientId: 'all',
                              senderId: adminId,
                              type: 'system',
                              title: title,
                              body: body,
                            );
                          }
                        } catch (e) {
                          debugPrint('[CustomNotify] error: \$e');
                        }
                        setState(() => _isSending = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Notification sent to ${memberIds.isEmpty ? "all users" : "${_calculateRecipients(admin)} users"}!',
                              ),
                              backgroundColor: const Color(0xFF6366F1),
                            ),
                          );
                          _titleController.clear();
                          _messageController.clear();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  disabledBackgroundColor: cs.outline.withOpacity(0.3),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.send, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Send Notification',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String type, IconData icon) {
    final isSelected = _notificationType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _notificationType = type;
          _selectedCommunity = null;
          _selectedPlantType = null;
          _selectedDisease = null;
          _allCommunities = false;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6366F1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSend() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      return false;
    }
    switch (_notificationType) {
      case 'community':
        return _allCommunities || _selectedCommunity != null;
      case 'plantType':
        return (_allCommunities || _selectedCommunity != null) &&
            _selectedPlantType != null;
      case 'disease':
        return _selectedDisease != null;
    }
    return false;
  }
}

// --- SHARED REUSABLE UI COMPONENTS ---

Widget _buildHeroStats(BuildContext context,
    {required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color}) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10))
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: cs.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        Icon(icon, size: 60, color: color.withOpacity(0.15)),
      ],
    ),
  );
}

// ignore: unused_element
Widget _buildCategoryRow(
    BuildContext context, String label, String value, Color color) {
  final cs = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: cs.onSurface)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: cs.onSurface)),
      ],
    ),
  );
}

// ignore: unused_element
Widget _buildSectionHeader(BuildContext context, String title) {
  final cs = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(title,
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
  );
}

// Custom painter for Health Status pie chart
class _HealthPieChartPainter extends CustomPainter {
  final double healthyPercent;
  final double issuePercent;

  _HealthPieChartPainter({
    required this.healthyPercent,
    required this.issuePercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 16.0;
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Healthy arc (green)
    final healthyPaint = Paint()
      ..color = const Color(0xFF0BA360)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final healthySweep = (healthyPercent / 100) * 2 * pi;
    canvas.drawArc(rect, -pi / 2, healthySweep, false, healthyPaint);

    // Issue arc (orange)
    final issuePaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final issueSweep = (issuePercent / 100) * 2 * pi;
    canvas.drawArc(rect, -pi / 2 + healthySweep, issueSweep, false, issuePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
