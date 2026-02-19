import 'package:flutter/material.dart';

class SystemLogsView extends StatelessWidget {
  const SystemLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('System Logs')),
      backgroundColor: isDark ? cs.surface : const Color(0xFF1E1E2E),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 20,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              '[${DateTime.now().toString().substring(11, 19)}] INFO: Scan performed by User ID 402 - Confidence 0.92',
              style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
