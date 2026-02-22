import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../common/custom_button.dart';

class AIModelUpdatesView extends StatelessWidget {
  const AIModelUpdatesView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Model Control')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Model: mobilenetv3_apple_disease.tflite',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            Text('On-device TFLite model',
                style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
            const SizedBox(height: 30),
            _buildModelStat(context, 'Average Accuracy', '—'),
            _buildModelStat(context, 'Inference Time', '—'),
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

  Widget _buildModelStat(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onSurface)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
        ],
      ),
    );
  }
}
