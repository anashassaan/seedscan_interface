import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/admin_controller.dart';

// --- 1. TOTAL USERS DETAIL PAGE ---
class TotalUsersStatsPage extends StatelessWidget {
  const TotalUsersStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('User Analytics',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroStats(context,
                title: "Active Community",
                value: "${admin.totalUsers}",
                subtitle: "Total registered gardeners",
                icon: LucideIcons.users,
                color: Colors.blueAccent),
            const SizedBox(height: 24),
            _buildSectionHeader("System Roles"),
            _buildCategoryRow("Standard Users",
                "${(admin.totalUsers * 0.9).round()}", Colors.green),
            _buildCategoryRow("Moderators", "2", Colors.orange),
            _buildCategoryRow("System Admins", "1", Colors.redAccent),
            const SizedBox(height: 24),
            const Text("User retention is up 4% this week",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

// --- 2. TREE SCANS DETAIL PAGE ---
class TreeScansStatsPage extends StatelessWidget {
  const TreeScansStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Scan Activity')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeroStats(context,
                title: "Total Scans",
                value: "${admin.totalScans}",
                subtitle: "Images processed by AI",
                icon: LucideIcons.scan,
                color: Colors.green),
            const SizedBox(height: 24),
            _buildSectionHeader("Identification History"),
            _buildScanHistoryTile("Oak Tree", "High Accuracy", "10:15 AM"),
            _buildScanHistoryTile("Maple Leaf", "Medium Accuracy", "Yesterday"),
            _buildScanHistoryTile("Pine Needle", "High Accuracy", "2 days ago"),
          ],
        ),
      ),
    );
  }

  Widget _buildScanHistoryTile(String type, String accuracy, String time) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(LucideIcons.leaf, color: Colors.green),
      ),
      title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(accuracy),
      trailing:
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}

// --- 3. DISEASE REPORTS PAGE ---
class DiseaseStatsPage extends StatelessWidget {
  const DiseaseStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFA),
      appBar: AppBar(title: const Text('Health Reports')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
            )
          ],
        ),
      ),
    );
  }
}

// --- 4. SERVER PERFORMANCE PAGE (Tech UI) ---
class ServerHealthPage extends StatelessWidget {
  const ServerHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:
            const Text('Infra Status', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.activity,
                      color: Colors.greenAccent, size: 48),
                  const SizedBox(height: 16),
                  const Text("SYSTEMS STABLE",
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                  Text("Uptime: 99.9%",
                      style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildMetricBar("CPU Usage", 0.12, "12%", Colors.blueAccent),
            _buildMetricBar(
                "Database Latency", 0.45, "45ms", Colors.purpleAccent),
            _buildMetricBar("API Response", 0.20, "180ms", Colors.greenAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBar(String label, double val, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
              Text(text,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: val,
            backgroundColor: Colors.white.withOpacity(0.1),
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}

// --- SHARED REUSABLE UI COMPONENTS ---

Widget _buildHeroStats(BuildContext context,
    {required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
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
                  style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.w900)),
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

Widget _buildCategoryRow(String label, String value, Color color) {
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    ),
  );
}

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );
}
