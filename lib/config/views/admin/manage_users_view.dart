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
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name[0].toUpperCase()),
                    ),
                    title: Text(user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "${user.email} • ${user.role}\nIn: ${admin.communities[cIdx].name}"),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _showEditRoleDialog(context, cIdx, uIdx, user.role);
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
}
