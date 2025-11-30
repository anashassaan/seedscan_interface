// lib/controllers/chat_controller.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

enum Sender { user, ai }

class ChatMessage {
  final String id;
  final String text;
  final Sender sender;
  final DateTime time;
  final Uint8List? image; // optional image bytes

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    DateTime? time,
    this.image,
  }) : time = time ?? DateTime.now();
}

class ChatController extends ChangeNotifier {
  ChatController() {
    // welcome message from Dr. Zakir (AI)
    _messages.add(
      ChatMessage(
        id: 'ai-1',
        text:
            'Hello! I am Dr. Zakir — your plant assistant. Send a photo or ask anything about plant care or diseases.',
        sender: Sender.ai,
      ),
    );
  }

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  // Send user message (text)
  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final msg = ChatMessage(
      id: 'u-${DateTime.now().microsecondsSinceEpoch}',
      text: text.trim(),
      sender: Sender.user,
    );
    _messages.add(msg);
    notifyListeners();

    // simulate AI response
    await _simulateAiResponse(prompt: text.trim());
  }

  // Send user image (for plant image diagnosis)
  Future<void> sendImage(Uint8List imageBytes) async {
    final msg = ChatMessage(
      id: 'uimg-${DateTime.now().microsecondsSinceEpoch}',
      text: '[Image]',
      sender: Sender.user,
      image: imageBytes,
    );
    _messages.add(msg);
    notifyListeners();

    await _simulateAiResponse(
      prompt: 'Analyze this plant image',
      image: imageBytes,
    );
  }

  Future<void> _simulateAiResponse({
    required String prompt,
    Uint8List? image,
  }) async {
    _isTyping = true;
    notifyListeners();

    // short pause to simulate thinking
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Build deterministic reply based on prompt/image
    String reply;
    if (image != null) {
      reply =
          'Analysis: I detect signs of fungal infection on the leaf edges. Suggested action: apply fungicide and improve airflow. Confidence: 89%.';
    } else if (prompt.toLowerCase().contains('water')) {
      reply =
          'Watering Guidance: Check soil moisture to ~2 inch depth. If dry, water slowly until moisture is uniform. Avoid waterlogging.';
    } else if (prompt.toLowerCase().contains('fung') ||
        prompt.toLowerCase().contains('mold')) {
      reply =
          'Fungal infections often occur with high humidity — remove affected leaves and treat with appropriate fungicide.';
    } else {
      reply =
          'That\'s interesting — could you provide a photo or more details? I can give more accurate guidance with an image.';
    }

    // Simulate reply stream typing delay
    await Future<void>.delayed(const Duration(milliseconds: 900));

    _messages.add(
      ChatMessage(
        id: 'ai-${DateTime.now().microsecondsSinceEpoch}',
        text: reply,
        sender: Sender.ai,
      ),
    );
    _isTyping = false;
    notifyListeners();
  }

  // Simple helper to clear messages (for dev)
  void clearConvo() {
    _messages.clear();
    _messages.add(
      ChatMessage(
        id: 'ai-1',
        text:
            'Hello! I am Dr. Zakir — your plant assistant. Send a photo or ask anything about plant care or diseases.',
        sender: Sender.ai,
      ),
    );
    notifyListeners();
  }
}
