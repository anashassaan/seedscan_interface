import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallet Points"),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Wallet Display
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    "1250",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Available Wallet Points",
                    style: TextStyle(
                      color: cs.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Recent Transactions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _transactionTile("Plant Scan", "-20 pts", Colors.red),
            _transactionTile("Daily Login", "+10 pts", Colors.green),
            _transactionTile("Task Completed", "+50 pts", Colors.green),
            _transactionTile("Plant Diagnosis", "-30 pts", Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _transactionTile(String title, String points, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      title: Text(title),
      trailing: Text(
        points,
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
