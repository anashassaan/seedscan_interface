import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/custom_text_field.dart';
import '../common/custom_button.dart';
import '../../../services/database_service.dart';
import '../../controllers/auth_controller.dart';

class GlobalNotificationsView extends StatefulWidget {
  const GlobalNotificationsView({super.key});

  @override
  State<GlobalNotificationsView> createState() =>
      _GlobalNotificationsViewState();
}

class _GlobalNotificationsViewState extends State<GlobalNotificationsView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendGlobalAlert() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both title and message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final db = DatabaseService();
      final auth = Provider.of<AuthController>(context, listen: false);
      final adminId = auth.userId ?? 'admin';

      await db.createNotification(
        recipientId: 'all', // Send to everyone
        senderId: adminId,
        type: 'system',
        title: _titleController.text.trim(),
        body: _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send broadcast: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
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
            _isSending
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    onPressed: _sendGlobalAlert,
                    child: const Text('Broadcast to All Users'),
                  ),
          ],
        ),
      ),
    );
  }
}
