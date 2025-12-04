import 'package:flutter/material.dart';

class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Plants"),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _plantTile(
            "Neem Tree",
            "Healthy",
            "https://images.unsplash.com/photo-1597262975002-c5c3b14bbd62?auto=format&fit=crop&w=400",
          ),
          _plantTile(
            "Mango Plant",
            "Needs Water",
            "https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=400",
          ),
          _plantTile(
            "Rose Plant",
            "Healthy",
            "https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=400",
          ),
        ],
      ),
    );
  }

  Widget _plantTile(String name, String status, String img) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: Image.network(img, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(status,
                  style: TextStyle(
                    color: status == "Healthy" ? Colors.green : Colors.red,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
