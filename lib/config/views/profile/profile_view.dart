// lib/views/profile/profile_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final cs = Theme.of(context).colorScheme;

    final notifications = _mockNotifications();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundImage: NetworkImage(
                      'https://randomuser.me/api/portraits/men/45.jpg',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.userName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Level 4 · Eco-Warrior',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  // Progress bar for gamification
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: LinearProgressIndicator(
                                value: 0.68,
                                minHeight: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '68%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Next level: Plant 10 more trees',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Notifications',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...notifications.map((n) {
            return Dismissible(
              key: ValueKey(n['id']),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {},
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_rounded),
                  title: Text(n['title'] as String),
                  subtitle: Text(n['subtitle'] as String),
                  trailing: Text(
                    n['time'] as String,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<Map<String, Object>> _mockNotifications() {
    return [
      {
        'id': 'n1',
        'title': 'Watering due for Plant #402',
        'subtitle': 'Last watered 6 days ago',
        'time': 'Now',
      },
      {
        'id': 'n2',
        'title': 'Scan Reminder',
        'subtitle': 'Don\'t forget to scan your plant this week',
        'time': '2d',
      },
      {
        'id': 'n3',
        'title': 'New comment on your post',
        'subtitle': 'Aisha commented: Great progress!',
        'time': '3d',
      },
    ];
  }
}
