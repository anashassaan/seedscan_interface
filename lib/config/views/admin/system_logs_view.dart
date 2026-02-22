import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SystemLogsView extends StatelessWidget {
  const SystemLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('System Logs')),
      backgroundColor: isDark ? cs.surface : const Color(0xFF1E1E2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileText,
                size: 48, color: Colors.greenAccent.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'No logs available',
              style: TextStyle(
                color: Colors.greenAccent.withOpacity(0.6),
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'System logs will appear here as activity occurs.',
              style: TextStyle(
                color: Colors.greenAccent.withOpacity(0.3),
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
