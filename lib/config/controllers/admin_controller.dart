import 'package:flutter/material.dart';

// 1. Model for individual planting records
class PlantStat {
  final String? type;
  final String? action;
  final int? count;
  final int? coinsEarned;
  final DateTime? date;

  PlantStat({
    this.type = "Unknown",
    this.action = "Activity",
    this.count = 0,
    this.coinsEarned = 0,
    this.date,
  });
}

// 2. Updated User Model with Reinforced Coin Logic
class AppUser {
  final String name;
  final String email;
  String role;
  final List<PlantStat> stats;

  AppUser({
    required this.name,
    required this.email,
    this.role = 'User',
    this.stats = const [],
  });

  // Reinforced getter to prevent Null Check Operator errors
  int get totalCoins {
    if (stats.isEmpty) return 0;
    try {
      return stats.fold<int>(0, (int sum, item) {
        final int earned = item.coinsEarned ?? 0;
        return sum + earned;
      });
    } catch (e) {
      debugPrint("Error calculating coins for $name: $e");
      return 0;
    }
  }
}

// 3. Community Model (Admin-specific, separate from app's Community model)
class AdminCommunity {
  final String name;
  final String location;
  final List<AppUser> members;

  AdminCommunity({
    required this.name,
    required this.location,
    required this.members,
  });
}

class AdminController extends ChangeNotifier {
  bool _isAutoReminderEnabled = false;
  bool get isAutoReminderEnabled => _isAutoReminderEnabled;

  static const String reminderTaskUniqueName =
      "com.example.seedscan.daily_reminder";
  static const String reminderTaskName = "dailyPlantCareNotification";

  // Initial Data
  final List<AdminCommunity> _communities = [
    AdminCommunity(
      name: "Green Valley",
      location: "Northern Sector",
      members: [
        AppUser(
          name: "Admin User",
          email: "admin@seedscan.com",
          role: "Admin",
          stats: [
            PlantStat(
                type: "Pine",
                action: "Planting",
                count: 1,
                coinsEarned: 50,
                date: DateTime.now().subtract(const Duration(days: 2))),
            PlantStat(
                type: "Pine",
                action: "Watering",
                count: 1,
                coinsEarned: 10,
                date: DateTime.now().subtract(const Duration(hours: 5))),
            PlantStat(
                type: "Oak",
                action: "Planting",
                count: 1,
                coinsEarned: 50,
                date: DateTime.now()),
          ],
        ),
      ],
    ),
    AdminCommunity(
      name: "Urban Jungle",
      location: "City Center",
      members: [
        AppUser(
          name: "Test User",
          email: "user@test.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Bonsai",
                action: "Planting",
                count: 1,
                coinsEarned: 50,
                date: DateTime.now().subtract(const Duration(days: 1))),
            PlantStat(
                type: "Bonsai",
                action: "Checking Health",
                count: 1,
                coinsEarned: 15,
                date: DateTime.now()),
          ],
        ),
      ],
    ),
  ];

  int _totalScans = 4500;
  int _diseasesDetected = 890;
  String _serverStatus = "Online";
  bool _isLoading = false;

  List<AdminCommunity> get communities => _communities;

  List<AppUser> get allUsers {
    return _communities.expand((community) => community.members).toList();
  }

  String getCommunityNameForUser(String email) {
    for (var community in _communities) {
      if (community.members.any((user) => user.email == email)) {
        return community.name;
      }
    }
    return "Unknown Community";
  }

  int get totalUsers => allUsers.length;
  int get totalScans => _totalScans;
  int get diseasesDetected => _diseasesDetected;
  String get serverStatus => _serverStatus;
  bool get isLoading => _isLoading;

  // --- Notification & Automation Logic ---

  Future<void> toggleAutoReminder(bool value) async {
    _isAutoReminderEnabled = value;
    // Mock implementation — in production, integrate a background task scheduler
    debugPrint(
        value ? 'Auto-reminder enabled (24h cycle)' : 'Auto-reminder disabled');
    notifyListeners();
  }

  // --- Community & User Management ---

  void addCommunity(String name, String location) {
    _communities
        .add(AdminCommunity(name: name, location: location, members: []));
    notifyListeners();
  }

  void addUserToCommunity(int communityIndex, String name, String email) {
    if (communityIndex >= 0 && communityIndex < _communities.length) {
      _communities[communityIndex].members.add(
            AppUser(
              name: name,
              email: email,
              stats: [],
            ),
          );
      notifyListeners();
    }
  }

  void deleteCommunity(int index) {
    if (index >= 0 && index < _communities.length) {
      _communities.removeAt(index);
      notifyListeners();
    }
  }

  void updateUserRole(int communityIndex, int userIndex, String newRole) {
    if (communityIndex >= 0 && communityIndex < _communities.length) {
      final members = _communities[communityIndex].members;
      if (userIndex >= 0 && userIndex < members.length) {
        members[userIndex].role = newRole;
        notifyListeners();
      }
    }
  }

  void removeUserFromCommunity(int communityIndex, int userIndex) {
    if (communityIndex >= 0 && communityIndex < _communities.length) {
      final members = _communities[communityIndex].members;
      if (userIndex >= 0 && userIndex < members.length) {
        members.removeAt(userIndex);
        notifyListeners();
      }
    }
  }

  // --- System Actions ---

  Future<void> sendGlobalNotification(String title, String message) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshStats() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _totalScans += 5;
    _isLoading = false;
    notifyListeners();
  }
}
