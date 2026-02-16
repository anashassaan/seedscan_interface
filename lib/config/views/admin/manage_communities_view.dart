import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import 'community_details_view.dart';

class ManageCommunitiesView extends StatelessWidget {
  const ManageCommunitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Communities')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: admin.communities.length,
        itemBuilder: (context, index) {
          final community = admin.communities[index];
          return Card(
            child: ListTile(
              title: Text(community.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "${community.location} • ${community.members.length} Members"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CommunityDetailsView(communityIndex: index))),
            ),
          );
        },
      ),
    );
  }
}
