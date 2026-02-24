import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';

class ManageUsersView extends StatelessWidget {
  const ManageUsersView({super.key});

  // Dialog to Edit User Role
  void _showEditRoleDialog(BuildContext context, int communityIndex,
      int userIndex, String currentRole) {
    final admin = Provider.of<AdminController>(context, listen: false);
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit User Role'),
          content: DropdownButton<String>(
            value: selectedRole,
            isExpanded: true,
            items: ['Admin', 'User', 'Moderator'].map((String role) {
              return DropdownMenuItem<String>(value: role, child: Text(role));
            }).toList(),
            onChanged: (val) => setDialogState(() => selectedRole = val!),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await admin.updateUserRole(
                    communityIndex, userIndex, selectedRole);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to Add New User
  void _showAddUserDialog(BuildContext context) {
    final admin = Provider.of<AdminController>(context, listen: false);
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (admin.communities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a community first!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v!.contains('@') ? null : 'Invalid email',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await admin.addUserToCommunity(
                    0, nameController.text, emailController.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);

    List<Map<String, dynamic>> allUsers = [];
    for (int cIdx = 0; cIdx < admin.communities.length; cIdx++) {
      for (int uIdx = 0;
          uIdx < admin.communities[cIdx].members.length;
          uIdx++) {
        allUsers.add({
          'user': admin.communities[cIdx].members[uIdx],
          'cIdx': cIdx,
          'uIdx': uIdx,
        });
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Global User Management')),
      body: allUsers.isEmpty
          ? const Center(child: Text('No users found across any communities.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allUsers.length,
              itemBuilder: (context, index) {
                final userData = allUsers[index];
                final AppUser user = userData['user'];
                final int cIdx = userData['cIdx'];
                final int uIdx = userData['uIdx'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors
                              .primaries[index % Colors.primaries.length]
                              .withOpacity(0.8),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(user.email,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  _infoChip(
                                    admin.communities[cIdx].name,
                                    Icons.group,
                                    Colors.blue,
                                  ),
                                  const SizedBox(width: 6),
                                  _infoChip(
                                    user.role,
                                    Icons.badge,
                                    user.role == 'Admin'
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  _infoChip(
                                    '🌿 ${_plantCount(user)} plants',
                                    null,
                                    Colors.teal,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showEditRoleDialog(
                                  context, cIdx, uIdx, user.role);
                            } else if (value == 'delete') {
                              await admin.removeUserFromCommunity(cIdx, uIdx);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit Role')),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Remove User',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  /// Small colored chip for displaying community/role/plant info.
  static Widget _infoChip(String label, IconData? icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Count "Planting" activity logs for a user.
  static int _plantCount(AppUser user) {
    return user.stats
        .where((s) => s.action == 'Planting')
        .fold(0, (sum, s) => sum + (s.count ?? 0));
  }
}
