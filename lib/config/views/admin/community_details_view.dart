import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';

class CommunityDetailsView extends StatelessWidget {
  final int communityIndex;
  const CommunityDetailsView({super.key, required this.communityIndex});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);

    // Safety Check
    if (communityIndex < 0 || communityIndex >= admin.communities.length) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Community not found")),
      );
    }

    final community = admin.communities[communityIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(community.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: community.members.isEmpty
          ? const Center(child: Text("No members in this community"))
          : ListView.builder(
              itemCount: community.members.length,
              itemBuilder: (context, userIndex) {
                final user = community.members[userIndex];

                String initial =
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : "?";

                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(initial),
                  ),
                  title: Text(user.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(user.email),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Planting Statistics:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text("Total Coins: ${user.totalCoins}",
                                  style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          user.stats.isEmpty
                              ? const Text("No plants recorded yet.",
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey))
                              : Table(
                                  border: TableBorder.all(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(4)),
                                  columnWidths: const {
                                    0: FlexColumnWidth(2),
                                    1: FlexColumnWidth(1),
                                    2: FlexColumnWidth(1),
                                  },
                                  children: [
                                    const TableRow(
                                      decoration: BoxDecoration(
                                          color: Color(0xFFF5F5F5)),
                                      children: [
                                        Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Text("Type",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Text("Count",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Text("Coins",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                      ],
                                    ),
                                    ...user.stats.map((s) =>
                                        TableRow(children: [
                                          Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text(s.type ?? "Unknown")),
                                          Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text(
                                                  (s.count ?? 0).toString())),
                                          Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text(
                                                  "+${s.coinsEarned ?? 0}")),
                                        ])),
                                  ],
                                ),
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
    );
  }
}
