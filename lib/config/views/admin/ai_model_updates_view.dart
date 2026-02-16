import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../common/custom_button.dart';

class AIModelUpdatesView extends StatelessWidget {
  const AIModelUpdatesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Model Control')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Active Model: disease_classifier.tflite',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Version: 2.1.0 (Deployed 3 days ago)',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            _buildModelStat('Average Accuracy', '94.2%'),
            _buildModelStat('Inference Time', '120ms'),
            const Spacer(),
            CustomButton(
              onPressed: () {},
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.uploadCloud),
                  SizedBox(width: 10),
                  Text('Upload New .tflite Model'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}
