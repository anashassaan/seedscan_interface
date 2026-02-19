import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/admin_controller.dart';

class MyGardenView extends StatelessWidget {
  const MyGardenView({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);
    final allUsers = admin.allUsers;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garden',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: allUsers.isEmpty
          ? const Center(child: Text("No gardeners registered yet."))
          : ListView.builder(
              itemCount: allUsers.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final user = allUsers[index];
                final communityName = admin.getCommunityNameForUser(user.email);

                final totalPlants = user.stats
                    .fold<int>(0, (sum, item) => sum + (item.count ?? 0));

                String initial =
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : "?";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: cs.primaryContainer,
                      child: Text(initial,
                          style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.globe,
                                size: 14, color: cs.primary),
                            const SizedBox(width: 4),
                            Text(communityName,
                                style:
                                    TextStyle(color: cs.primary, fontSize: 13)),
                          ],
                        ),
                        Text('$totalPlants Plants recorded',
                            style: TextStyle(
                                color: cs.onSurface.withOpacity(0.6))),
                      ],
                    ),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => _showPlantDetails(context, user),
                  ),
                );
              },
            ),
    );
  }

  void _showPlantDetails(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text("${user.name}'s Collection",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Divider(),
              Expanded(
                child: user.stats.isEmpty
                    ? const Center(
                        child: Text("No plant data available for this user."))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: user.stats.length,
                        itemBuilder: (context, i) {
                          final stat = user.stats[i];

                          final type = stat.type ?? "Unknown Plant";
                          final count = stat.count ?? 0;

                          String dateStr = "Unknown Date";
                          if (stat.date != null) {
                            dateStr =
                                "${stat.date!.day}/${stat.date!.month}/${stat.date!.year}";
                          }

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(LucideIcons.leaf,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            title: Text(type,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text("Recorded on $dateStr"),
                            trailing: Text("${count}x",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
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
}
