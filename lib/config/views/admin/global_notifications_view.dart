import 'package:flutter/material.dart';
import '../common/custom_text_field.dart';
import '../common/custom_button.dart';

class GlobalNotificationsView extends StatefulWidget {
  const GlobalNotificationsView({super.key});

  @override
  State<GlobalNotificationsView> createState() =>
      _GlobalNotificationsViewState();
}

class _GlobalNotificationsViewState extends State<GlobalNotificationsView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Global Alert')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CustomTextField(
              controller: _titleController,
              label: 'Notification Title',
              hint: 'e.g. System Maintenance',
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _messageController,
              label: 'Message Content',
              hint: 'Type your message to all users...',
            ),
            const SizedBox(height: 30),
            CustomButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _messageController.text.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Broadcast sent successfully!')),
                  );
                  _titleController.clear();
                  _messageController.clear();
                }
              },
              child: const Text('Broadcast to All Users'),
            ),
          ],
        ),
      ),
    );
  }
}
