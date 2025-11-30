// lib/views/home/home_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Welcome, ${auth.userName}'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Section
          Row(
            children: [
              Expanded(
                child: _statCard('Plants', '42', Icons.eco_outlined, cs),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Scans', '128', Icons.qr_code_scanner, cs),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Health %',
                  '87%',
                  Icons.health_and_safety,
                  cs,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Tasks', '5 Due', Icons.event_available, cs),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          // Quick Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickAction(context, Icons.qr_code, 'Scan QR', 0),
              _quickAction(
                context,
                Icons.document_scanner_outlined,
                'Diagnosis',
                1,
              ),
              _quickAction(context, Icons.chat_bubble_outline, 'Chat', 3),
            ],
          ),

          const SizedBox(height: 24),
          Text('Your Plants', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          _plantsPreview(),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, ColorScheme cs) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 34, color: cs.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(title),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
    BuildContext context,
    IconData icon,
    String label,
    int tabIndex,
  ) {
    return InkWell(
      onTap: () {
        // Switch tab in MainNavigation
        DefaultTabController.of(context)?.animateTo(tabIndex);
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          CircleAvatar(radius: 32, child: Icon(icon, size: 32)),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _plantsPreview() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _plantBox(
            'Neem Tree',
            'Healthy',
            'https://images.unsplash.com/photo-1597262975002-c5c3b14bbd62?auto=format&fit=crop&w=400',
          ),
          _plantBox(
            'Mango',
            'Needs Water',
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=400',
          ),
          _plantBox(
            'Rose',
            'Healthy',
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=400',
          ),
        ],
      ),
    );
  }

  Widget _plantBox(String name, String status, String img) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                img,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(status, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
