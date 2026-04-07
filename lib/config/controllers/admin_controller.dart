import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/admin_database_service.dart';
import '../../models/user_model.dart';
import 'package:appwrite/appwrite.dart';
import '../../services/database_service.dart';
import '../../models/plant_model.dart';
import '../../models/transaction_model.dart';
import '../../models/community_model.dart';

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

  /// Create from an Appwrite activity_logs document.
  factory PlantStat.fromActivityLog(Map<String, dynamic> json) {
    return PlantStat(
      type: json['plant_species'] ?? json['action_type'] ?? 'Unknown',
      action: _mapActionType(json['action_type'] ?? ''),
      count: 1,
      coinsEarned: json['coins_awarded'] ?? 0,
      date: json['created_at'] != null || json['\$createdAt'] != null
          ? DateTime.tryParse(json['created_at'] ?? json['\$createdAt'] ?? '')
          : DateTime.now(),
    );
  }

  static String _mapActionType(String actionType) {
    switch (actionType) {
      case 'water':
        return 'Watering';
      case 'scan_disease':
        return 'Health Scan';
      case 'register':
        return 'Planting';
      default:
        return actionType.isNotEmpty
            ? actionType[0].toUpperCase() + actionType.substring(1)
            : 'Activity';
    }
  }
}

// 2. Updated User Model with Reinforced Coin Logic
class AppUser {
  final String id; // Appwrite document ID
  final String name;
  final String email;
  String role;
  final List<PlantStat> stats;
  final int walletBalance;
  final DateTime createdAt;

  AppUser({
    this.id = '',
    required this.name,
    required this.email,
    this.role = 'User',
    this.stats = const [],
    this.walletBalance = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from Appwrite UserModel + optional role from CommunityMember.
  factory AppUser.fromUserModel(UserModel user,
      {String role = 'User', List<PlantStat> stats = const []}) {
    return AppUser(
      id: user.id,
      name: user.name,
      email: user.email,
      role: role,
      stats: stats,
      walletBalance: user.walletBalance,
      createdAt: user.createdAt,
    );
  }

  // Reinforced getter to prevent Null Check Operator errors
  int get totalCoins {
    // Prefer wallet balance from Appwrite if available
    if (walletBalance > 0) return walletBalance;
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

// 3. Community Model (Admin-specific, wraps the Appwrite Community model)
class AdminCommunity {
  final String id; // Appwrite document ID
  final String name;
  final String location;
  final String description;
  final String createdBy;
  final String? imagePath; // Local file path (used for newly picked images)
  final String? imageUrl; // Remote URL from Appwrite storage
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final List<AppUser> members;

  /// Returns the best available image source (URL preferred over local path).
  String? get displayImage => imageUrl ?? imagePath;
  bool get hasNetworkImage => imageUrl != null && imageUrl!.isNotEmpty;

  AdminCommunity({
    this.id = '',
    required this.name,
    required this.location,
    this.description = '',
    this.createdBy = 'Admin',
    this.imagePath,
    this.imageUrl,
    this.category = 'General',
    this.isActive = true,
    DateTime? createdAt,
    required this.members,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from Appwrite Community model with loaded members.
  factory AdminCommunity.fromCommunity(Community community,
      {List<AppUser> members = const [], String? creatorName}) {
    return AdminCommunity(
      id: community.id,
      name: community.name,
      location: community.description ?? '',
      description: community.description ?? '',
      createdBy: creatorName ?? community.creatorId,
      imageUrl: community.imageUrl,
      category: community.category,
      isActive: community.isActive,
      createdAt: community.createdAt,
      members: members,
    );
  }
}

// 4. QR Code Model for plant tracking
class PlantQrCode {
  final String id; // Unique QR ID
  final String communityId; // Community document ID
  final String communityName;
  final String plantName;
  final String plantType; // e.g. Tree, Shrub, Herb, Climber, Grass
  final String bestSeason; // e.g. Spring, Summer, Monsoon, Autumn, Winter
  final String notes;
  final bool isSeed; // true = Seed, false = Plant
  final String? plantAge; // Only applicable when isSeed == false
  final DateTime generatedAt;
  bool isUploaded;
  String? appwriteDocId; // Appwrite document ID for persistence

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
    this.appwriteDocId,
  }) : generatedAt = generatedAt ?? DateTime.now();

  /// The data encoded in the QR code
  String get qrData =>
      'SEEDSCAN|$communityId|$id|$plantName|$plantType|$bestSeason'
      '|${isSeed ? "SEED" : "PLANT"}|${plantAge ?? "N/A"}'
      '|${generatedAt.millisecondsSinceEpoch}';

  /// Short label for display
  String get displayLabel => plantName.isNotEmpty ? plantName : id;

  /// Create from Appwrite document.
  factory PlantQrCode.fromJson(Map<String, dynamic> json) {
    return PlantQrCode(
      id: json['id'] ?? json['\$id'] ?? '',
      communityId: json['community_id'] ?? '',
      communityName: json['community_name'] ?? '',
      plantName: json['plant_name'] ?? '',
      plantType: json['plant_type'] ?? '',
      bestSeason: json['best_season'] ?? '',
      notes: json['notes'] ?? '',
      isSeed: json['is_seed'] ?? true,
      plantAge: json['plant_age'],
      generatedAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      isUploaded: json['is_uploaded'] ?? false,
      appwriteDocId: json['id'] ?? json['\$id'],
    );
  }

  /// Convert to a map for Appwrite storage.
  Map<String, dynamic> toJson() {
    return {
      'plantName': plantName,
      'plantType': plantType,
      'bestSeason': bestSeason,
      'notes': notes,
      'isSeed': isSeed,
      'plantAge': plantAge,
      'qrData': qrData,
    };
  }

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

  // ── Backend services ───────────────────────────────────────────────────────
  final AdminDatabaseService _adminDb = AdminDatabaseService();

  // ── Local state (populated from Appwrite) ──────────────────────────────────
  List<AdminCommunity> _communities = [];
  Map<String, int> _plantHealth = {};

  /// species → Set<guardianId>
  Map<String, Set<String>> _speciesOwners = {};

  /// health_status → Set<guardianId>  (only non-healthy statuses)
  Map<String, Set<String>> _healthOwners = {};
  bool _isInitialized = false;
  bool _useLocalFallback = false; // true when Appwrite is unreachable
  String _serverStatus = "Online";
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<AdminCommunity> get communities => _communities;
  Map<String, int> get plantHealth => _plantHealth;
  int get healthyPlants => _plantHealth['healthy'] ?? 0;
  int get diseasedPlants =>
      (_plantHealth['diseased'] ?? 0) + (_plantHealth['critical'] ?? 0);
  int get deadPlants => _plantHealth['dead'] ?? 0;
  bool get isInitialized => _isInitialized;
  String get serverStatus => _serverStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<AppUser> get allUsers {
    return _communities.expand((community) => community.members).toList();
  }

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

  int get totalScans {
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

  int get diseasesDetected {
    int total = 0;
    for (var community in _communities) {
      for (var member in community.members) {
        for (var stat in member.stats) {
          if (stat.action == "Health Scan" ||
              stat.action == "Disease Detection") {
            total += stat.count ?? 0;
          }
        }
      }
    }
    return total;
  }

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

  /// Distinct plant species that actually exist (from plants collection + QR codes).
  List<String> get existingPlantSpecies {
    final species = <String>{};
    // Primary: species from the plants collection
    species.addAll(_speciesOwners.keys);
    // Supplement: plant names from QR codes (may not match a guardian yet)
    for (final qrList in _communityQrCodes.values) {
      for (final qr in qrList) {
        final name = qr.plantName.trim();
        if (name.isNotEmpty) species.add(name);
      }
    }
    return species.toList()..sort();
  }

  /// Returns the set of guardian user IDs who own plants of [species].
  Set<String> getUserIdsForSpecies(String species) =>
      _speciesOwners[species] ?? {};

  /// Display label → Appwrite health_status key.
  static String _diseaseDisplayToStatus(String label) {
    switch (label) {
      case 'Critical Condition':
        return 'critical';
      case 'Dead / Deceased':
        return 'dead';
      default:
        return 'diseased';
    }
  }

  /// Returns the set of guardian user IDs whose plants match [displayLabel].
  Set<String> getUserIdsForDisease(String displayLabel) =>
      _healthOwners[_diseaseDisplayToStatus(displayLabel)] ?? {};

  /// Human-readable disease labels that have affected plants in the community.
  List<String> get existingDiseaseTypes {
    final types = <String>[];
    if ((_healthOwners['diseased']?.isNotEmpty ?? false) ||
        (_plantHealth['diseased'] ?? 0) > 0) types.add('Diseased');
    if ((_healthOwners['critical']?.isNotEmpty ?? false) ||
        (_plantHealth['critical'] ?? 0) > 0) types.add('Critical Condition');
    if ((_healthOwners['dead']?.isNotEmpty ?? false) ||
        (_plantHealth['dead'] ?? 0) > 0) types.add('Dead / Deceased');
    return types;
  }

  /// All planting stats across every community member, with their dates.
  /// Used to build the Scan Trends chart bucketed by period.
  List<PlantStat> get allPlantingStats {
    final result = <PlantStat>[];
    for (final community in _communities) {
      for (final member in community.members) {
        for (final stat in member.stats) {
          if (stat.action == 'Planting') {
            result.add(stat);
          }
        }
      }
    }
    return result;
  }

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Load all admin data from Appwrite. Call once on admin login.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadFromAppwrite();
      _serverStatus = "Online";
      _useLocalFallback = false;
    } catch (e) {
      debugPrint('AdminController: Appwrite load failed: $e');
      _serverStatus = "Offline";
      _useLocalFallback = true;
      _errorMessage = 'Failed to connect to server. Please try again.';
    }

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  /// Reload all data from the backend.
  Future<void> refreshStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadFromAppwrite();
      _serverStatus = "Online";
      _useLocalFallback = false;
    } catch (e) {
      debugPrint('AdminController: Refresh failed: $e');
      _errorMessage = 'Failed to refresh data. Using cached data.';
      _serverStatus = "Offline";
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Core data loading from Appwrite.
  Future<void> _loadFromAppwrite() async {
    // 1. Load all communities
    final communities = await _adminDb.listAllCommunities();

    // 2. Load all users
    final allUserModels = await _adminDb.listAllUsers();
    final userMap = {for (var u in allUserModels) u.id: u};

    // 3. Load activity logs for stats
    final activityLogs = await _adminDb.listAllActivityLogs();

    // Group activity logs by user
    final userActivityMap = <String, List<PlantStat>>{};
    for (final log in activityLogs) {
      final userId = log['user_id'] as String? ?? '';
      userActivityMap.putIfAbsent(userId, () => []);
      userActivityMap[userId]!.add(PlantStat.fromActivityLog(log));
    }

    // 4. For each community, load members and assemble AdminCommunity
    final adminCommunities = <AdminCommunity>[];
    for (final community in communities) {
      final memberDocs = await _adminDb.listCommunityMembers(community.id);

      final members = <AppUser>[];
      for (final memberDoc in memberDocs) {
        final user = userMap[memberDoc.userId];
        if (user != null) {
          final stats = userActivityMap[user.id] ?? [];
          members.add(AppUser.fromUserModel(
            user,
            role: _formatRole(memberDoc.role),
            stats: stats,
          ));
        }
      }

      // Resolve creator name
      final creator = userMap[community.creatorId];
      adminCommunities.add(AdminCommunity.fromCommunity(
        community,
        members: members,
        creatorName: creator?.name,
      ));
    }

    _communities = adminCommunities;

    // 5. Load plant health distribution
    _plantHealth = await _adminDb.getPlantHealthDistribution();

    // 6. Load QR codes for each community
    _communityQrCodes.clear();
    for (int i = 0; i < _communities.length; i++) {
      final qrDocs = await _adminDb.listAdminQrCodes(_communities[i].id);
      if (qrDocs.isNotEmpty) {
        _communityQrCodes[i] =
            qrDocs.map((d) => PlantQrCode.fromJson(d)).toList();
      }
    }

    // 7. Load all plants to build species→owners and health→owners maps
    final allPlants = await _adminDb.listAllPlants();
    _speciesOwners = {};
    _healthOwners = {};
    for (final plant in allPlants) {
      final species = plant.species.trim();
      if (species.isNotEmpty) {
        _speciesOwners.putIfAbsent(species, () => {}).add(plant.guardianId);
      }
      final status = plant.healthStatus.trim().toLowerCase();
      if (status.isNotEmpty && status != 'healthy') {
        _healthOwners.putIfAbsent(status, () => {}).add(plant.guardianId);
      }
    }
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      case 'member':
        return 'User';
      default:
        return 'User';
    }
  }

  // ── Fetch User Specific Data ────────────────────────────────────────────────

  /// Get all plants belonging to a specific user.
  Future<List<PlantModel>> getUserPlants(String userId) async {
    try {
      final dbService = DatabaseService();
      return await dbService.listMyPlants(userId);
    } catch (e) {
      debugPrint(
          'AdminController: Failed to fetch plants for user $userId: $e');
      return [];
    }
  }

  /// Get plants planted by a user within a specific community (drive_id == communityId).
  ///
  /// Uses a 3-tier strategy to handle missing Appwrite indexes gracefully:
  ///  1. Single-attribute query by guardian_id (needs guardian_id index).
  ///  2. Full-collection scan limited to 500 most-recent docs (no index needed).
  ///  3. Return empty list with a debugPrint if all else fails.
  ///
  /// In both successful tiers the result is further filtered client-side by
  /// communityId so we never depend on a compound query.
  Future<List<PlantModel>> getCommunityMemberPlants(
      String userId, String communityId) async {
    final dbService = DatabaseService();

    // ── Tier 1: indexed single-attribute query ─────────────────────────────
    try {
      final all = await dbService.listMyPlants(userId);
      debugPrint(
          'AdminController: Tier-1 query returned ${all.length} plants for $userId');
      if (all.isNotEmpty) {
        final filtered = all.where((p) => p.driveId == communityId).toList();
        // Return community-filtered results; fall back to ALL user plants if
        // none match the community (e.g. legacy plants without drive_id).
        return filtered.isNotEmpty ? filtered : all;
      }
    } catch (e) {
      debugPrint('AdminController: Tier-1 query failed ($e) — trying Tier-2');
    }

    // ── Tier 2: scan-all (no index required) ──────────────────────────────
    try {
      final all = await dbService.listPlants(queries: [
        Query.limit(500),
        Query.orderDesc('\$createdAt'),
      ]);
      debugPrint(
          'AdminController: Tier-2 scan returned ${all.length} total plants');
      final byUser = all.where((p) => p.guardianId == userId).toList();
      final filtered = byUser.where((p) => p.driveId == communityId).toList();
      return filtered.isNotEmpty ? filtered : byUser;
    } catch (e) {
      debugPrint('AdminController: Tier-2 scan also failed: $e');
      return [];
    }
  }

  /// Get activity history logs for a specific plant, including image updates.
  ///
  /// Uses a two-tier strategy:
  ///  Tier 1 – query directly by plant_id (fast, uses index).
  ///  Tier 2 – broad scan with client-side ID matching (for legacy entries
  ///            that embed IDs inside the rejectionReason JSON metadata).
  Future<List<ActivityLog>> getPlantHistoryLogs(String plantId) async {
    final dbService = DatabaseService();
    final Set<String> seenIds = {};
    final List<ActivityLog> matched = [];

    // ── Tier 1: direct query by plant_id (indexed, fast) ──────────────────
    try {
      final directLogs = await dbService.listActivityLogs(queries: [
        Query.equal('plant_id', plantId),
        Query.orderDesc('\$createdAt'),
        Query.limit(200),
      ]);
      debugPrint(
          'AdminController.getPlantHistoryLogs: Tier-1 returned '
          '${directLogs.length} logs for plantId=$plantId');
      for (final log in directLogs) {
        if (seenIds.add(log.id)) matched.add(log);
      }
    } catch (e) {
      debugPrint('AdminController.getPlantHistoryLogs: Tier-1 failed ($e)');
    }

    // ── Tier 2: broad scan for logs with embedded IDs in metadata ─────────
    // This catches entries created by older code that stored IDs inside
    // the rejectionReason JSON instead of as the primary plant_id field.
    try {
      final allLogs = await dbService.listActivityLogs(queries: [
        Query.orderDesc('\$createdAt'),
        Query.limit(500),
      ]);
      for (final log in allLogs) {
        if (seenIds.contains(log.id)) continue; // already added in Tier 1

        final raw = log.rejectionReason;
        if (raw == null || raw.trim().isEmpty) continue;

        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            final sourceId  = decoded['source_plant_id']?.toString() ?? '';
            final resolvedId = decoded['resolved_plant_id']?.toString() ?? '';
            final originalId = decoded['plant_id']?.toString() ?? '';
            if (sourceId == plantId ||
                resolvedId == plantId ||
                originalId == plantId) {
              if (seenIds.add(log.id)) matched.add(log);
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('AdminController.getPlantHistoryLogs: Tier-2 failed ($e)');
    }

    // Sort oldest → newest (the UI re-sorts newest first on its end)
    matched.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    debugPrint(
        'AdminController.getPlantHistoryLogs: returning '
        '${matched.length} total logs for plantId=$plantId');
    return matched;
  }


  // ── Notification & Automation Logic ────────────────────────────────────────

  Future<void> toggleAutoReminder(bool value) async {
    _isAutoReminderEnabled = value;
    debugPrint(
        value ? 'Auto-reminder enabled (24h cycle)' : 'Auto-reminder disabled');
    notifyListeners();
  }

  // ── Community Management ───────────────────────────────────────────────────

  /// Create a new community, persisted to Appwrite.
  Future<bool> addCommunity({
    required String name,
    required String location,
    String description = '',
    String createdBy = 'Admin',
    String? imagePath,
    String category = 'General',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_useLocalFallback) {
        // Upload image if provided
        String? imageUrl;
        if (imagePath != null) {
          imageUrl = await _adminDb.uploadCommunityImage(imagePath);
        }

        final community = await _adminDb.createCommunity(
          name: name,
          location: location,
          description: description.isNotEmpty ? description : location,
          creatorId: createdBy,
          imageUrl: imageUrl,
          category: category,
        );

        _communities.add(AdminCommunity.fromCommunity(
          community,
          members: [],
          creatorName: createdBy,
        ));

        // Log the action
        try {
          await _adminDb.createSystemLog(
            action: 'Created community: $name',
            performedBy: createdBy,
          );
        } catch (_) {}

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Offline fallback: local only
        _communities.add(AdminCommunity(
          name: name,
          location: location,
          description: description,
          createdBy: createdBy,
          imagePath: imagePath,
          category: category,
          members: [],
        ));
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      final msg = e.toString();
      debugPrint('AdminController: Failed to add community: $msg');
      _errorMessage = 'Failed to create community: $msg';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update a community's profile image, persisted to Appwrite.
  Future<bool> updateCommunityImage(int communityIndex, String filePath) async {
    if (communityIndex < 0 || communityIndex >= _communities.length) {
      return false;
    }

    try {
      final community = _communities[communityIndex];
      final imageUrl = await _adminDb.uploadCommunityImage(filePath);
      if (imageUrl == null) return false;

      final updated = await _adminDb.updateCommunity(
        community.id,
        {'image_url': imageUrl},
      );
      if (updated == null) return false;

      _communities[communityIndex] = AdminCommunity.fromCommunity(
        updated,
        members: community.members,
        creatorName: community.createdBy,
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AdminController: Failed to update community image: $e');
      return false;
    }
  }

  /// Add a user to a community, persisted to Appwrite.
  Future<bool> addUserToCommunity(
      int communityIndex, String name, String email) async {
    if (communityIndex < 0 || communityIndex >= _communities.length) {
      return false;
    }

    try {
      if (!_useLocalFallback) {
        final community = _communities[communityIndex];

        // Find the user by email
        final allUsersResult = await _adminDb.listAllUsers();
        final user = allUsersResult.where((u) => u.email == email).firstOrNull;

        if (user != null) {
          await _adminDb.addMemberToCommunity(
            communityId: community.id,
            userId: user.id,
            role: 'member',
          );

          _communities[communityIndex].members.add(
                AppUser.fromUserModel(user, role: 'User'),
              );
        } else {
          // User doesn't exist in Appwrite - add locally only
          _communities[communityIndex].members.add(
                AppUser(name: name, email: email, stats: []),
              );
        }
      } else {
        _communities[communityIndex].members.add(
              AppUser(name: name, email: email, stats: []),
            );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AdminController: Failed to add user to community: $e');
      return false;
    }
  }

  /// Delete a community, persisted to Appwrite.
  Future<bool> deleteCommunity(int index) async {
    if (index < 0 || index >= _communities.length) return false;

    try {
      final community = _communities[index];

      if (!_useLocalFallback && community.id.isNotEmpty) {
        final success = await _adminDb.deleteCommunity(community.id);
        if (!success) {
          _errorMessage = 'Failed to delete community from server';
          notifyListeners();
          return false;
        }

        await _adminDb.createSystemLog(
          action: 'Deleted community: ${community.name}',
          performedBy: 'Admin',
        );
      }

      _communities.removeAt(index);
      _communityQrCodes.remove(index);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AdminController: Failed to delete community: $e');
      return false;
    }
  }

  /// Update a user's role, persisted to Appwrite.
  Future<bool> updateUserRole(
      int communityIndex, int userIndex, String newRole) async {
    if (communityIndex < 0 || communityIndex >= _communities.length) {
      return false;
    }
    final members = _communities[communityIndex].members;
    if (userIndex < 0 || userIndex >= members.length) return false;

    try {
      if (!_useLocalFallback) {
        final community = _communities[communityIndex];
        final user = members[userIndex];

        // Find the membership document
        final memberDocs = await _adminDb.listCommunityMembers(community.id);
        final memberDoc =
            memberDocs.where((m) => m.userId == user.id).firstOrNull;

        if (memberDoc != null) {
          final appwriteRole = newRole.toLowerCase() == 'user'
              ? 'member'
              : newRole.toLowerCase();
          await _adminDb.updateMemberRole(
            memberDocId: memberDoc.id,
            newRole: appwriteRole,
          );
        }
      }

      members[userIndex].role = newRole;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AdminController: Failed to update user role: $e');
      return false;
    }
  }

  /// Remove a user from a community, persisted to Appwrite.
  Future<bool> removeUserFromCommunity(
      int communityIndex, int userIndex) async {
    if (communityIndex < 0 || communityIndex >= _communities.length) {
      return false;
    }
    final members = _communities[communityIndex].members;
    if (userIndex < 0 || userIndex >= members.length) return false;

    try {
      if (!_useLocalFallback) {
        final community = _communities[communityIndex];
        final user = members[userIndex];

        final memberDocs = await _adminDb.listCommunityMembers(community.id);
        final memberDoc =
            memberDocs.where((m) => m.userId == user.id).firstOrNull;

        if (memberDoc != null) {
          await _adminDb.removeMemberFromCommunity(
            memberDocId: memberDoc.id,
            communityId: community.id,
          );
        }
      }

      members.removeAt(userIndex);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AdminController: Failed to remove user: $e');
      return false;
    }
  }

  // ── System Actions ─────────────────────────────────────────────────────────

  /// Send a global notification, persisted to Appwrite.
  Future<bool> sendGlobalNotification(String title, String message) async {
    _isLoading = true;
    notifyListeners();

    try {
      bool success = true;
      if (!_useLocalFallback) {
        success = await _adminDb.sendGlobalNotification(
          title: title,
          body: message,
          senderId: 'admin',
        );

        await _adminDb.createSystemLog(
          action: 'Sent global notification: $title',
          performedBy: 'Admin',
        );
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to send notification: $e';
      notifyListeners();
      return false;
    }
  }

  // ── QR Code Management ────────────────────────────────────────────────────

  final Map<int, List<PlantQrCode>> _communityQrCodes = {};

  List<PlantQrCode> getQrCodes(int communityIndex) {
    return _communityQrCodes[communityIndex] ?? [];
  }

  /// Add QR codes, persisted to Appwrite.
  Future<void> addQrCodes(int communityIndex, List<PlantQrCode> codes) async {
    _communityQrCodes.putIfAbsent(communityIndex, () => []);
    _communityQrCodes[communityIndex]!.addAll(codes);

    if (!_useLocalFallback && communityIndex < _communities.length) {
      final community = _communities[communityIndex];
      if (community.id.isNotEmpty) {
        try {
          final qrDataList = codes.map((c) => c.toJson()).toList();
          final docIds = await _adminDb.createAdminQrCodes(
            communityId: community.id,
            communityName: community.name,
            qrDataList: qrDataList,
          );

          // Store the Appwrite doc IDs back on the local objects
          for (int i = 0; i < codes.length && i < docIds.length; i++) {
            codes[i].appwriteDocId = docIds[i];
          }
        } catch (e) {
          debugPrint('AdminController: Failed to persist QR codes: $e');
        }
      }
    }

    notifyListeners();
  }

  /// Mark QR codes as uploaded, persisted to Appwrite.
  Future<void> markQrCodesUploaded(int communityIndex) async {
    final codes = _communityQrCodes[communityIndex];
    if (codes == null) return;

    // Get doc IDs for Appwrite update
    final docIds = codes
        .where((c) => c.appwriteDocId != null && !c.isUploaded)
        .map((c) => c.appwriteDocId!)
        .toList();

    if (!_useLocalFallback && docIds.isNotEmpty) {
      try {
        await _adminDb.markQrCodesUploaded(docIds);
      } catch (e) {
        debugPrint('AdminController: Failed to mark QR codes uploaded: $e');
      }
    }

    for (final code in codes) {
      code.isUploaded = true;
    }
    notifyListeners();
  }

  int get totalQrCodes =>
      _communityQrCodes.values.fold(0, (sum, list) => sum + list.length);

  // ── Fallback removed — no dummy data ────────────────────────────────────
  // _loadFallbackData has been removed. When Appwrite is unreachable the admin
  // panel simply shows empty state / error message.
}
