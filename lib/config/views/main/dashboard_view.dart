// lib/views/main/dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../common/plant_card.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final cs = Theme.of(context).colorScheme;

    // Sample stats and plants (mock)
    final stats = [
      {'title': 'Trees Planted', 'value': '12'},
      {'title': 'Carbon Offset', 'value': '36 Kg'},
      {'title': 'Wallet Points', 'value': '420'},
    ];

    final plants = [
      {
        'image':
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=800&q=60',
        'name': 'Moringa',
        'id': '402',
        'status': 'Healthy',
        'last': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'image':
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=800&q=60',
        'name': 'Neem',
        'id': '278',
        'status': 'Needs Water',
        'last': DateTime.now().subtract(const Duration(days: 4)),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome back, ${auth.userName}'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
        child: Column(
          children: [
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final s = stats[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['title']!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            s['value']!,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Plants',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: plants.length,
                itemBuilder: (context, i) {
                  final p = plants[i];
                  return PlantCard(
                    imageUrl: p['image'] as String,
                    name: p['name'] as String,
                    id: p['id'] as String,
                    status: p['status'] as String,
                    lastScanned: p['last'] as DateTime,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
