import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tasks"),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _taskTile("Water the Mango plant", false),
          _taskTile("Fertilize Neem plant", true),
          _taskTile("Trim Rose plant", false),
          _taskTile("Check soil moisture", true),
        ],
      ),
    );
  }

  Widget _taskTile(String task, bool done) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(
          done ? Icons.check_circle : Icons.pending_outlined,
          color: done ? Colors.green : Colors.orange,
          size: 30,
        ),
        title: Text(
          task,
          style: TextStyle(
            fontSize: 16,
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
