// lib/config/controllers/community_controller.dart
import 'package:flutter/material.dart';
import '../../models/community_model.dart';
import '../../services/database_service.dart';
import '../../services/garden_cache_service.dart';

class CommunityController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  // List of communities the current user belongs to
  final List<Community> _communities = [];
  final Map<String, List<CommunityPlant>> _communityPlants = {};
  String? _loadedForUserId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingCommunityPlants = false;
  bool get isLoadingCommunityPlants => _isLoadingCommunityPlants;

  /// Load all communities that the given [userId] is a member of from Appwrite.
  Future<void> loadUserCommunities(String userId) async {
    if (userId.isEmpty) return;

    if (_loadedForUserId != userId) {
      _communities.clear();
      _communityPlants.clear();
      _loadedForUserId = userId;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Get membership records for this user
      final memberships = await _db.listUserMemberships(userId);

      // 2. Fetch full Community doc for each membership
      final List<Community> loaded = [];
      for (final m in memberships) {
        final community = await _db.getCommunity(m.communityId);
        if (community != null) {
          loaded.add(community);
        }
      }

      _communities
        ..clear()
        ..addAll(loaded);

      // Restore cached plants for each community that has no in-memory data
      for (final community in loaded) {
        if (!_communityPlants.containsKey(community.id) ||
            _communityPlants[community.id]!.isEmpty) {
          final cached =
              GardenCacheService.getCommunityPlantsCache(community.id);
          if (cached != null && cached.isNotEmpty) {
            _communityPlants[community.id] =
                cached.map((m) => CommunityPlant.fromMap(m)).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('CommunityController.loadUserCommunities failed: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Communities created by [userId].
  List<Community> getCreatedCommunities(String userId) {
    return _communities.where((c) => c.creatorId == userId).toList();
  }

  /// Communities the user joined but did NOT create.
  List<Community> getJoinedCommunities(String userId) {
    return _communities.where((c) => c.creatorId != userId).toList();
  }

  /// Number of communities created by [userId].
  int createdCount(String userId) => getCreatedCommunities(userId).length;

  /// Number of communities joined (but not created) by [userId].
  int joinedCount(String userId) => getJoinedCommunities(userId).length;

  /// Add a community to the in-memory list (used after QR auto-join).
  void addCommunityLocally(Community community) {
    // Avoid duplicates
    if (_communities.any((c) => c.id == community.id)) return;
    _communities.add(community);
    notifyListeners();
  }

  // Get all communities
  List<Community> getCommunities() {
    // Update plant counts dynamically before returning
    return _communities.map<Community>((community) {
      final plantCount = _communityPlants[community.id]?.length ?? 0;
      return community.copyWith(plantCount: plantCount);
    }).toList();
  }

  // Get community by ID
  Community? getCommunityById(String id) {
    try {
      final community = _communities.firstWhere((c) => c.id == id);
      // Update plant count dynamically
      final plantCount = _communityPlants[id]?.length ?? 0;
      return community.copyWith(plantCount: plantCount);
    } catch (e) {
      return null;
    }
  }

  // Get plants for a specific community
  List<CommunityPlant> getCommunityPlants(String communityId) {
    return List.unmodifiable(_communityPlants[communityId] ?? []);
  }

  /// Load/refresh all member plants for [communityId] from Appwrite.
  Future<void> loadCommunityPlantsFromServer(String communityId) async {
    if (_isLoadingCommunityPlants) return;
    _isLoadingCommunityPlants = true;
    notifyListeners();
    try {
      final plants = await _db.getCommunityMemberPlants(communityId);
      _communityPlants[communityId] = plants;
      notifyListeners();
      _savePlantsToCache(communityId);
    } catch (e) {
      debugPrint('CommunityController.loadCommunityPlantsFromServer: $e');
    } finally {
      _isLoadingCommunityPlants = false;
      notifyListeners();
    }
  }

  // Add plant to a community
  void addPlantToCommunity(CommunityPlant plant) {
    if (!_communityPlants.containsKey(plant.communityId)) {
      _communityPlants[plant.communityId] = [];
    }
    _communityPlants[plant.communityId]!.add(plant);

    // Update plant count
    final communityIndex =
        _communities.indexWhere((c) => c.id == plant.communityId);
    if (communityIndex != -1) {
      final updatedCommunity = _communities[communityIndex].copyWith(
        plantCount: _communityPlants[plant.communityId]!.length,
      );
      _communities[communityIndex] = updatedCommunity;
    }
    notifyListeners();
    // Persist to Hive so plants survive app restart
    _savePlantsToCache(plant.communityId);
  }

  void _savePlantsToCache(String communityId) {
    try {
      final plants = _communityPlants[communityId];
      if (plants == null) return;
      final maps = plants.map((p) => p.toMap()).toList();
      GardenCacheService.saveCommunityPlants(communityId, maps);
    } catch (_) {}
  }

  // Remove plant from community
  void removePlantFromCommunity(String communityId, String plantId) {
    if (_communityPlants.containsKey(communityId)) {
      _communityPlants[communityId]!.removeWhere((p) => p.id == plantId);

      // Update plant count
      final communityIndex =
          _communities.indexWhere((c) => c.id == communityId);
      if (communityIndex != -1) {
        final updatedCommunity = _communities[communityIndex].copyWith(
          plantCount: _communityPlants[communityId]!.length,
        );
        _communities[communityIndex] = updatedCommunity;
      }
      notifyListeners();
    }
  }

  // Toggle like on community plant
  void toggleLikePlant(String communityId, String plantId) {
    if (_communityPlants.containsKey(communityId)) {
      final plants = _communityPlants[communityId]!;
      final plantIndex = plants.indexWhere((p) => p.id == plantId);

      if (plantIndex != -1) {
        final plant = plants[plantIndex];
        final updatedPlant = plant.copyWith(
          isLiked: !plant.isLiked,
          likeCount: plant.isLiked ? plant.likeCount - 1 : plant.likeCount + 1,
        );
        _communityPlants[communityId]![plantIndex] = updatedPlant;
        notifyListeners();
      }
    }
  }

  // Search communities
  List<Community> searchCommunities(String query) {
    if (query.isEmpty) return getCommunities();

    final lowerQuery = query.toLowerCase();
    return _communities.where((community) {
      return community.name.toLowerCase().contains(lowerQuery) ||
          (community.description?.toLowerCase().contains(lowerQuery) ??
              false) ||
          community.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get communities by category
  List<Community> getCommunitiesByCategory(String category) {
    return _communities.where((c) => c.category == category).toList();
  }

  // Check if QR code belongs to a community (for backward compatibility)
  Community? getCommunityByQrCode(String qrCode) {
    // For now, return null as QR prefix system is removed
    // You can implement custom logic here if needed
    return null;
  }

  // Update plant image
  void updatePlantImage(String communityId, String plantId, String imagePath) {
    if (_communityPlants.containsKey(communityId)) {
      final plants = _communityPlants[communityId]!;
      final plantIndex = plants.indexWhere((p) => p.id == plantId);

      if (plantIndex != -1) {
        final plant = plants[plantIndex];
        final updatedPlant = plant.copyWith(imageUrl: imagePath);
        _communityPlants[communityId]![plantIndex] = updatedPlant;
        notifyListeners();
        _savePlantsToCache(communityId);
      }
    }
  }

  // Update plant location
  void updatePlantLocation(String communityId, String plantId, String location,
      double? latitude, double? longitude) {
    if (_communityPlants.containsKey(communityId)) {
      final plants = _communityPlants[communityId]!;
      final plantIndex = plants.indexWhere((p) => p.id == plantId);

      if (plantIndex != -1) {
        final plant = plants[plantIndex];
        final updatedPlant = plant.copyWith(
          location: location,
          latitude: latitude,
          longitude: longitude,
        );
        _communityPlants[communityId]![plantIndex] = updatedPlant;
        notifyListeners();
        _savePlantsToCache(communityId);
      }
    }
  }

  // Get total count of all plants across all communities
  int getTotalCommunityPlantsCount() {
    int total = 0;
    for (var plants in _communityPlants.values) {
      total += plants.length;
    }
    return total;
  }
}
