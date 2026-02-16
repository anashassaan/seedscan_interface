import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/admin_controller.dart';

class CoinAnalyticsView extends StatelessWidget {
  const CoinAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);
    final users = admin.allUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Analytics',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: users.isEmpty
          ? const Center(child: Text("No user data available"))
          : ListView.builder(
              itemCount: users.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade100,
                      child:
                          const Icon(LucideIcons.coins, color: Colors.orange),
                    ),
                    title: Text(user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Total Coins: ${user.totalCoins}"),
                    trailing: const Icon(Icons.analytics_outlined, size: 20),
                    onTap: () => _showBreakdown(context, user),
                  ),
                );
              },
            ),
    );
  }

  void _showBreakdown(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
              Text("${user.name}'s Earning History",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 30),
              Expanded(
                child: user.stats.isEmpty
                    ? const Center(child: Text("No transaction history"))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: user.stats.length,
                        itemBuilder: (context, i) {
                          final s = user.stats[i];
                          final String actionName = s.action ?? "Activity";
                          final String plantType = s.type ?? "Unknown";
                          final int coins = s.coinsEarned ?? 0;
                          final String dateStr = s.date != null
                              ? "${s.date!.day}/${s.date!.month}/${s.date!.year}"
                              : "Recent";

                          return ListTile(
                            leading: _getActionIcon(actionName),
                            title: Text("$actionName: $plantType"),
                            subtitle: Text(dateStr),
                            trailing: Text("+$coins",
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
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

  Widget _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'planting':
        return const Icon(LucideIcons.treePine, color: Colors.green);
      case 'watering':
        return const Icon(LucideIcons.droplets, color: Colors.blue);
      case 'checking health':
        return const Icon(LucideIcons.clipboardCheck, color: Colors.teal);
      default:
        return const Icon(LucideIcons.star, color: Colors.orange);
    }
  }
}
