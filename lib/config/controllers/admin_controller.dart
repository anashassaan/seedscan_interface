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
  final String description;
  final String createdBy;
  final String? imagePath;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final List<AppUser> members;

  AdminCommunity({
    required this.name,
    required this.location,
    this.description = '',
    this.createdBy = 'Admin',
    this.imagePath,
    this.category = 'General',
    this.isActive = true,
    DateTime? createdAt,
    required this.members,
  }) : createdAt = createdAt ?? DateTime.now();
}

// 4. QR Code Model for plant tracking
class PlantQrCode {
  final String id; // Unique QR ID
  final String communityId; // Community name as ID
  final String communityName;
  final String plantName;
  final String plantType; // e.g. Tree, Shrub, Herb, Climber, Grass
  final String bestSeason; // e.g. Spring, Summer, Monsoon, Autumn, Winter
  final String notes;
  final bool isSeed; // true = Seed, false = Plant
  final String? plantAge; // Only applicable when isSeed == false
  final DateTime generatedAt;
  bool isUploaded;

  PlantQrCode({
    required this.id,
    required this.communityId,
    required this.communityName,
    required this.plantName,
    required this.plantType,
    required this.bestSeason,
    this.notes = '',
    this.isSeed = true,
    this.plantAge,
    DateTime? generatedAt,
    this.isUploaded = false,
  }) : generatedAt = generatedAt ?? DateTime.now();

  /// The data encoded in the QR code
  String get qrData =>
      'SEEDSCAN|$communityId|$id|$plantName|$plantType|$bestSeason'
      '|${isSeed ? "SEED" : "PLANT"}|${plantAge ?? "N/A"}'
      '|${generatedAt.millisecondsSinceEpoch}';

  /// Short label for display
  String get displayLabel => plantName.isNotEmpty ? plantName : id;

  @override
  String toString() =>
      'PlantQrCode($id, plant: $plantName, community: $communityName)';
}

class AdminController extends ChangeNotifier {
  bool _isAutoReminderEnabled = false;
  bool get isAutoReminderEnabled => _isAutoReminderEnabled;

  static const String reminderTaskUniqueName =
      "com.example.seedscan.daily_reminder";
  static const String reminderTaskName = "dailyPlantCareNotification";

  // Initial Data - Large dummy data set
  final List<AdminCommunity> _communities = [
    AdminCommunity(
      name: "Green Valley",
      location: "Northern Sector",
      description:
          "A thriving community focused on native tree planting and environmental restoration in the northern highlands.",
      createdBy: "Admin User",
      imagePath: null,
      category: "Reforestation",
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      members: [
        AppUser(
          name: "Admin User",
          email: "admin@seedscan.com",
          role: "Admin",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Planting",
                count: 15,
                coinsEarned: 750,
                date: DateTime.now().subtract(const Duration(days: 30))),
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 45,
                coinsEarned: 450,
                date: DateTime.now().subtract(const Duration(days: 2))),
            PlantStat(
                type: "Oak",
                action: "Planting",
                count: 8,
                coinsEarned: 400,
                date: DateTime.now().subtract(const Duration(days: 15))),
            PlantStat(
                type: "Pine",
                action: "Watering",
                count: 30,
                coinsEarned: 300,
                date: DateTime.now().subtract(const Duration(hours: 5))),
          ],
        ),
        AppUser(
          name: "Sarah Johnson",
          email: "sarah.j@seedscan.com",
          role: "Moderator",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 32,
                coinsEarned: 320,
                date: DateTime.now().subtract(const Duration(days: 3))),
            PlantStat(
                type: "Cherry",
                action: "Planting",
                count: 12,
                coinsEarned: 600,
                date: DateTime.now().subtract(const Duration(days: 10))),
            PlantStat(
                type: "Maple",
                action: "Pruning",
                count: 8,
                coinsEarned: 160,
                date: DateTime.now().subtract(const Duration(days: 1))),
          ],
        ),
        AppUser(
          name: "Michael Chen",
          email: "mike.chen@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 28,
                coinsEarned: 280,
                date: DateTime.now().subtract(const Duration(days: 5))),
            PlantStat(
                type: "Pear",
                action: "Planting",
                count: 6,
                coinsEarned: 300,
                date: DateTime.now().subtract(const Duration(days: 20))),
          ],
        ),
        AppUser(
          name: "Emily Davis",
          email: "emily.d@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 18,
                coinsEarned: 180,
                date: DateTime.now().subtract(const Duration(days: 7))),
            PlantStat(
                type: "Walnut",
                action: "Planting",
                count: 4,
                coinsEarned: 200,
                date: DateTime.now().subtract(const Duration(days: 25))),
          ],
        ),
        AppUser(
          name: "James Wilson",
          email: "james.w@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 22,
                coinsEarned: 220,
                date: DateTime.now().subtract(const Duration(days: 4))),
          ],
        ),
      ],
    ),
    AdminCommunity(
      name: "Urban Jungle",
      location: "City Center",
      description:
          "Urban gardening enthusiasts transforming city spaces into green oases with bonsai and indoor plants.",
      createdBy: "Admin User",
      imagePath: null,
      category: "Urban Gardening",
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      members: [
        AppUser(
          name: "Test User",
          email: "user@test.com",
          role: "Admin",
          stats: [
            PlantStat(
                type: "Bonsai",
                action: "Health Scan",
                count: 40,
                coinsEarned: 400,
                date: DateTime.now().subtract(const Duration(days: 1))),
            PlantStat(
                type: "Ficus",
                action: "Planting",
                count: 25,
                coinsEarned: 1250,
                date: DateTime.now().subtract(const Duration(days: 14))),
            PlantStat(
                type: "Succulent",
                action: "Watering",
                count: 60,
                coinsEarned: 600,
                date: DateTime.now()),
          ],
        ),
        AppUser(
          name: "Lisa Park",
          email: "lisa.park@email.com",
          role: "Moderator",
          stats: [
            PlantStat(
                type: "Snake Plant",
                action: "Health Scan",
                count: 35,
                coinsEarned: 350,
                date: DateTime.now().subtract(const Duration(days: 2))),
            PlantStat(
                type: "Pothos",
                action: "Planting",
                count: 18,
                coinsEarned: 900,
                date: DateTime.now().subtract(const Duration(days: 8))),
          ],
        ),
        AppUser(
          name: "David Kim",
          email: "david.k@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Monstera",
                action: "Health Scan",
                count: 20,
                coinsEarned: 200,
                date: DateTime.now().subtract(const Duration(days: 3))),
            PlantStat(
                type: "Philodendron",
                action: "Planting",
                count: 10,
                coinsEarned: 500,
                date: DateTime.now().subtract(const Duration(days: 12))),
          ],
        ),
        AppUser(
          name: "Anna Lee",
          email: "anna.lee@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "ZZ Plant",
                action: "Health Scan",
                count: 15,
                coinsEarned: 150,
                date: DateTime.now().subtract(const Duration(days: 6))),
          ],
        ),
      ],
    ),
    AdminCommunity(
      name: "Sunrise Farms",
      location: "Eastern District",
      description:
          "Agricultural community specializing in fruit orchards and sustainable farming practices.",
      createdBy: "Robert Miller",
      imagePath: null,
      category: "Agriculture",
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      members: [
        AppUser(
          name: "Robert Miller",
          email: "robert.m@sunrisefarms.com",
          role: "Admin",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 85,
                coinsEarned: 850,
                date: DateTime.now().subtract(const Duration(days: 1))),
            PlantStat(
                type: "Apple Tree",
                action: "Planting",
                count: 50,
                coinsEarned: 2500,
                date: DateTime.now().subtract(const Duration(days: 60))),
            PlantStat(
                type: "Peach",
                action: "Pruning",
                count: 30,
                coinsEarned: 600,
                date: DateTime.now().subtract(const Duration(days: 5))),
          ],
        ),
        AppUser(
          name: "Maria Garcia",
          email: "maria.g@sunrisefarms.com",
          role: "Moderator",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 62,
                coinsEarned: 620,
                date: DateTime.now().subtract(const Duration(days: 2))),
            PlantStat(
                type: "Plum",
                action: "Planting",
                count: 20,
                coinsEarned: 1000,
                date: DateTime.now().subtract(const Duration(days: 30))),
          ],
        ),
        AppUser(
          name: "Carlos Rodriguez",
          email: "carlos.r@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 45,
                coinsEarned: 450,
                date: DateTime.now().subtract(const Duration(days: 3))),
            PlantStat(
                type: "Apricot",
                action: "Watering",
                count: 40,
                coinsEarned: 400,
                date: DateTime.now().subtract(const Duration(days: 1))),
          ],
        ),
        AppUser(
          name: "Sofia Martinez",
          email: "sofia.m@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 38,
                coinsEarned: 380,
                date: DateTime.now().subtract(const Duration(days: 4))),
          ],
        ),
        AppUser(
          name: "Diego Lopez",
          email: "diego.l@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 28,
                coinsEarned: 280,
                date: DateTime.now().subtract(const Duration(days: 6))),
            PlantStat(
                type: "Nectarine",
                action: "Planting",
                count: 8,
                coinsEarned: 400,
                date: DateTime.now().subtract(const Duration(days: 45))),
          ],
        ),
        AppUser(
          name: "Isabella Hernandez",
          email: "isabella.h@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 22,
                coinsEarned: 220,
                date: DateTime.now().subtract(const Duration(days: 8))),
          ],
        ),
      ],
    ),
    AdminCommunity(
      name: "Mountain View Gardens",
      location: "Western Hills",
      description:
          "High-altitude gardening community focused on cold-resistant varieties and alpine plants.",
      createdBy: "Emma Thompson",
      imagePath: null,
      category: "Alpine Gardening",
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      members: [
        AppUser(
          name: "Emma Thompson",
          email: "emma.t@mvgardens.com",
          role: "Admin",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 55,
                coinsEarned: 550,
                date: DateTime.now().subtract(const Duration(days: 2))),
            PlantStat(
                type: "Spruce",
                action: "Planting",
                count: 35,
                coinsEarned: 1750,
                date: DateTime.now().subtract(const Duration(days: 40))),
            PlantStat(
                type: "Juniper",
                action: "Pruning",
                count: 20,
                coinsEarned: 400,
                date: DateTime.now().subtract(const Duration(days: 7))),
          ],
        ),
        AppUser(
          name: "William Brown",
          email: "will.b@mvgardens.com",
          role: "Moderator",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 42,
                coinsEarned: 420,
                date: DateTime.now().subtract(const Duration(days: 3))),
            PlantStat(
                type: "Blue Spruce",
                action: "Planting",
                count: 15,
                coinsEarned: 750,
                date: DateTime.now().subtract(const Duration(days: 25))),
          ],
        ),
        AppUser(
          name: "Olivia Taylor",
          email: "olivia.t@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 30,
                coinsEarned: 300,
                date: DateTime.now().subtract(const Duration(days: 5))),
            PlantStat(
                type: "Mountain Ash",
                action: "Watering",
                count: 25,
                coinsEarned: 250,
                date: DateTime.now().subtract(const Duration(days: 2))),
          ],
        ),
        AppUser(
          name: "Benjamin Clark",
          email: "ben.c@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 25,
                coinsEarned: 250,
                date: DateTime.now().subtract(const Duration(days: 9))),
          ],
        ),
        AppUser(
          name: "Charlotte White",
          email: "charlotte.w@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 18,
                coinsEarned: 180,
                date: DateTime.now().subtract(const Duration(days: 11))),
          ],
        ),
      ],
    ),
    AdminCommunity(
      name: "Riverside Orchards",
      location: "River Valley",
      description:
          "Premium fruit orchard community along the riverside with focus on organic apple cultivation.",
      createdBy: "Thomas Anderson",
      imagePath: null,
      category: "Organic Farming",
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      members: [
        AppUser(
          name: "Thomas Anderson",
          email: "thomas.a@riversideorchards.com",
          role: "Admin",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 120,
                coinsEarned: 1200,
                date: DateTime.now().subtract(const Duration(days: 1))),
            PlantStat(
                type: "Apple Tree",
                action: "Planting",
                count: 80,
                coinsEarned: 4000,
                date: DateTime.now().subtract(const Duration(days: 90))),
            PlantStat(
                type: "Apple Tree",
                action: "Fertilizing",
                count: 60,
                coinsEarned: 1200,
                date: DateTime.now().subtract(const Duration(days: 10))),
          ],
        ),
        AppUser(
          name: "Jennifer Wright",
          email: "jennifer.w@riversideorchards.com",
          role: "Moderator",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 95,
                coinsEarned: 950,
                date: DateTime.now().subtract(const Duration(days: 2))),
            PlantStat(
                type: "Crabapple",
                action: "Planting",
                count: 25,
                coinsEarned: 1250,
                date: DateTime.now().subtract(const Duration(days: 50))),
          ],
        ),
        AppUser(
          name: "Daniel Harris",
          email: "daniel.h@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 72,
                coinsEarned: 720,
                date: DateTime.now().subtract(const Duration(days: 3))),
            PlantStat(
                type: "Apple Tree",
                action: "Pruning",
                count: 35,
                coinsEarned: 700,
                date: DateTime.now().subtract(const Duration(days: 15))),
          ],
        ),
        AppUser(
          name: "Megan Scott",
          email: "megan.s@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 58,
                coinsEarned: 580,
                date: DateTime.now().subtract(const Duration(days: 4))),
          ],
        ),
        AppUser(
          name: "Ryan King",
          email: "ryan.k@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 45,
                coinsEarned: 450,
                date: DateTime.now().subtract(const Duration(days: 6))),
            PlantStat(
                type: "Apple Tree",
                action: "Watering",
                count: 50,
                coinsEarned: 500,
                date: DateTime.now().subtract(const Duration(days: 1))),
          ],
        ),
        AppUser(
          name: "Ashley Green",
          email: "ashley.g@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 38,
                coinsEarned: 380,
                date: DateTime.now().subtract(const Duration(days: 8))),
          ],
        ),
        AppUser(
          name: "Kevin Adams",
          email: "kevin.a@email.com",
          role: "User",
          stats: [
            PlantStat(
                type: "Apple Tree",
                action: "Health Scan",
                count: 32,
                coinsEarned: 320,
                date: DateTime.now().subtract(const Duration(days: 12))),
          ],
        ),
      ],
    ),
  ];

  // Computed from community data
  int get _calculatedTotalScans {
    int total = 0;
    for (var community in _communities) {
      for (var member in community.members) {
        for (var stat in member.stats) {
          if (stat.action == "Health Scan") {
            total += stat.count ?? 0;
          }
        }
      }
    }
    return total;
  }

  int get _calculatedDiseasesDetected {
    // Approximately 15% of scans detect issues
    return (_calculatedTotalScans * 0.15).round();
  }

  String _serverStatus = "Online";
  bool _isLoading = false;

  List<AdminCommunity> get communities => _communities;

  List<AppUser> get allUsers {
    return _communities.expand((community) => community.members).toList();
  }

  // Alias for allUsers
  List<AppUser> get allMembers => allUsers;

  String getCommunityNameForUser(String email) {
    for (var community in _communities) {
      if (community.members.any((user) => user.email == email)) {
        return community.name;
      }
    }
    return "Unknown Community";
  }

  int get totalUsers => allUsers.length;
  int get totalScans => _calculatedTotalScans;
  int get diseasesDetected => _calculatedDiseasesDetected;
  String get serverStatus => _serverStatus;
  bool get isLoading => _isLoading;

  // Get total plants (sum of all planting actions)
  int get totalPlants {
    int total = 0;
    for (var community in _communities) {
      for (var member in community.members) {
        for (var stat in member.stats) {
          if (stat.action == "Planting") {
            total += stat.count ?? 0;
          }
        }
      }
    }
    return total;
  }

  // Get scans by community
  Map<String, int> get scansByCommunity {
    final Map<String, int> result = {};
    for (var community in _communities) {
      int communityScans = 0;
      for (var member in community.members) {
        for (var stat in member.stats) {
          if (stat.action == "Health Scan") {
            communityScans += stat.count ?? 0;
          }
        }
      }
      result[community.name] = communityScans;
    }
    return result;
  }

  // --- Notification & Automation Logic ---

  Future<void> toggleAutoReminder(bool value) async {
    _isAutoReminderEnabled = value;
    // Mock implementation — in production, integrate a background task scheduler
    debugPrint(
        value ? 'Auto-reminder enabled (24h cycle)' : 'Auto-reminder disabled');
    notifyListeners();
  }

  // --- Community & User Management ---

  void addCommunity({
    required String name,
    required String location,
    String description = '',
    String createdBy = 'Admin',
    String? imagePath,
    String category = 'General',
  }) {
    _communities.add(AdminCommunity(
      name: name,
      location: location,
      description: description,
      createdBy: createdBy,
      imagePath: imagePath,
      category: category,
      members: [],
    ));
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
    // Stats are now computed from actual data, just refresh the UI
    _isLoading = false;
    notifyListeners();
  }

  // --- QR Code Management ---

  final Map<int, List<PlantQrCode>> _communityQrCodes = {};

  List<PlantQrCode> getQrCodes(int communityIndex) {
    return _communityQrCodes[communityIndex] ?? [];
  }

  void addQrCodes(int communityIndex, List<PlantQrCode> codes) {
    _communityQrCodes.putIfAbsent(communityIndex, () => []);
    _communityQrCodes[communityIndex]!.addAll(codes);
    notifyListeners();
  }

  void markQrCodesUploaded(int communityIndex) {
    final codes = _communityQrCodes[communityIndex];
    if (codes != null) {
      for (final code in codes) {
        code.isUploaded = true;
      }
      notifyListeners();
    }
  }

  int get totalQrCodes =>
      _communityQrCodes.values.fold(0, (sum, list) => sum + list.length);
}
