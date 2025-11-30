// lib/views/plants/plants_view.dart
import 'package:flutter/material.dart';

class PlantsView extends StatelessWidget {
  const PlantsView({super.key});

  @override
  Widget build(BuildContext context) {
    final data = [
      {'name': 'Neem', 'health': 'Healthy'},
      {'name': 'Mango', 'health': 'Diseased'},
      {'name': 'Rose', 'health': 'Healthy'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Plants')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, i) {
          final p = data[i];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.local_florist),
              title: Text(p['name']!),
              subtitle: Text("Health: ${p['health']}"),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
