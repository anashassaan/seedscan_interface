import 'package:flutter/material.dart';

class ChatController extends ChangeNotifier {
  String? pendingScanReport;

  Future<void> sendText(String text) async {
    pendingScanReport = text;
    notifyListeners();
  }
  
  void clearPending() {
    pendingScanReport = null;
    notifyListeners();
  }
}

