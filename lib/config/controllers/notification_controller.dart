import 'package:flutter/material.dart';

class NotificationController extends ChangeNotifier {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'n1',
      'title': 'Watering due for Plant #402',
      'subtitle': 'Last watered 6 days ago',
      'time': 'Now',
      'read': false,
    },
    {
      'id': 'n2',
      'title': 'Scan Reminder',
      'subtitle': 'Don\'t forget to scan your plant this week',
      'time': '2d',
      'read': false,
    },
    {
      'id': 'n3',
      'title': 'New comment on your post',
      'subtitle': 'Aisha commented: Great progress!',
      'time': '3d',
      'read': true,
    },
  ];

  List<Map<String, dynamic>> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => n['read'] == false).length;

  void markAllAsRead() {
    for (var n in _notifications) {
      n['read'] = true;
    }
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['read'] = true;
      notifyListeners();
    }
  }
}
