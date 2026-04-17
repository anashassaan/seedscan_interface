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

  // Bug-3 fix: remember who is logged in so plant queries are filtered.
  String? _currentUserId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingCommunityPlants = false;
  bool get isLoadingCommunityPlants => _isLoadingCommunityPlants;

  /// Load all communities that the given [userId] is a member of.
  /// CACHE-FIRST: Loads from GardenCacheService instantly, then syncs from Appwrite in background.
  Future<void> loadUserCommunities(String userId) async {
    if (userId.isEmpty) return;

    // Bug-3 fix: always keep the current user ID up-to-date.
    _currentUserId = userId;

    if (_loadedForUserId != userId) {
      _communities.clear();
      _communityPlants.clear();
      _loadedForUserId = userId;
    }

    // STEP 1: INSTANT LOAD FROM CACHE
    _loadCommunitiesFromCache(userId);
    _isLoading = true;
    notifyListeners();

    // STEP 2: BACKGROUND SYNC WITH APPWRITE (silent refresh)
    _syncCommunitiesFromAppwrite(userId);
  }

  /// Load communities from GardenCacheService (instant, no network required)
  void _loadCommunitiesFromCache(String userId) {
    try {
      final cachedCommunities = GardenCacheService.getCachedCommunities(userId);
      if (cachedCommunities != null && cachedCommunities.isNotEmpty) {
        _communities.clear();
        _communities.addAll(cachedCommunities);

        // Load cached plants for EACH community
        _communityPlants.clear();
        for (final community in cachedCommunities) {
          final cachedPlants =
              GardenCacheService.getCommunityPlantsCache(community.id);
          if (cachedPlants != null && cachedPlants.isNotEmpty) {
            _communityPlants[community.id] =
                cachedPlants.map((m) => CommunityPlant.fromMap(m)).toList();
            debugPrint(
                '[CommunityController] Loaded ${cachedPlants.length} cached plants for community ${community.name}');
          } else {
            _communityPlants[community.id] = [];
            debugPrint(
                '[CommunityController] No cached plants yet for community ${community.name}');
          }
        }
        debugPrint(
            '[CommunityController] Loaded ${_communities.length} communities and ${_communityPlants.length} plant caches from Hive');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[CommunityController] Failed to load from cache: $e');
    }
  }

  /// Background sync: Fetch fresh communities from Appwrite
  Future<void> _syncCommunitiesFromAppwrite(String userId) async {
    try {
      debugPrint(
          '[CommunityController] Starting background Appwrite sync for user \$userId');

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

      // 3. Update in-memory state with fresh data
      _communities
        ..clear()
        ..addAll(loaded);

      // 4. Cache the fresh communities
      GardenCacheService.cacheCommunities(userId, loaded);

      // 5. Fetch and cache plants for each community
      for (final community in loaded) {
        try {
          // Try to fetch fresh plants for this community
          final plants = await _db.getCommunityMemberPlants(
            community.id,
            userId: _currentUserId,
          );
          _communityPlants[community.id] = plants;
          _savePlantsToCache(community.id);
          debugPrint(
              '[CommunityController] Cached ${plants.length} plants for community ${community.name}');
        } catch (e) {
          // If fetch fails, try to restore from cache
          debugPrint(
              '[CommunityController] Failed to fetch plants for community ${community.id}: $e');
          final cached =
              GardenCacheService.getCommunityPlantsCache(community.id);
          if (cached != null && cached.isNotEmpty) {
            _communityPlants[community.id] =
                cached.map((m) => CommunityPlant.fromMap(m)).toList();
            debugPrint(
                '[CommunityController] Restored ${cached.length} cached plants for community ${community.id}');
          }
        }
      }
      debugPrint(
          '[CommunityController] Background sync complete — \${_communities.length} communities with \${_communityPlants.length} plant caches');
    } catch (e) {
      debugPrint(
          '[CommunityController] Background Appwrite sync failed (using cached data): \$e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  /// Load/refresh all member plants for [communityId].
  /// CACHE-FIRST: Loads from GardenCacheService instantly, then syncs from Appwrite in background.
  /// Only fetches plants belonging to the currently logged-in user.
  Future<void> loadCommunityPlantsFromServer(String communityId) async {
    if (_isLoadingCommunityPlants) return;
    _isLoadingCommunityPlants = true;

    // STEP 1: INSTANT LOAD FROM CACHE
    _loadCommunityPlantsFromCache(communityId);
    notifyListeners();

    // STEP 2: BACKGROUND SYNC WITH APPWRITE (silent refresh)
    await _syncCommunityPlantsFromAppwrite(communityId);
  }

  /// Load plants from GardenCacheService (instant, no network required)
  void _loadCommunityPlantsFromCache(String communityId) {
    try {
      final cached = GardenCacheService.getCommunityPlantsCache(communityId);
      if (cached != null && cached.isNotEmpty) {
        _communityPlants[communityId] =
            cached.map((m) => CommunityPlant.fromMap(m)).toList();
        debugPrint(
            '[CommunityController] Loaded ${_communityPlants[communityId]?.length ?? 0} cached plants for community $communityId');
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
          '[CommunityController] Failed to load community plants from cache: $e');
    }
  }

  /// Background sync: Fetch fresh community plants from Appwrite
  Future<void> _syncCommunityPlantsFromAppwrite(String communityId) async {
    try {
      debugPrint(
          '[CommunityController] Starting background sync for community $communityId');

      // Bug-3 fix: pass _currentUserId so only the logged-in user's plants
      // are returned, not every member's plants.
      final plants = await _db.getCommunityMemberPlants(
        communityId,
        userId: _currentUserId,
      );
      _communityPlants[communityId] = plants;
      _savePlantsToCache(communityId);
      debugPrint(
          '[CommunityController] Background sync complete for community $communityId — ${plants.length} plants');
    } catch (e) {
      debugPrint(
          '[CommunityController] Background sync failed for community $communityId (using cached data): $e');
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

  // Update plant image in-memory with the new Appwrite preview URL.
  void updatePlantImage(String communityId, String plantId, String imageUrl) {
    if (_communityPlants.containsKey(communityId)) {
      final plants = _communityPlants[communityId]!;
      final plantIndex = plants.indexWhere((p) => p.id == plantId);

      if (plantIndex != -1) {
        final plant = plants[plantIndex];
        // imageUrl here is the full Appwrite preview URL, not a local path.
        final updatedPlant = plant.copyWith(imageUrl: imageUrl);
        _communityPlants[communityId]![plantIndex] = updatedPlant;
        notifyListeners();
        _savePlantsToCache(communityId);
      }
    }
  }

  // Update plant location
  Future<void> updatePlantLocation(String communityId, String plantId,
      String location, double? latitude, double? longitude) async {
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

        // Synchronize with database
        try {
          await _db.updatePlant(plantId, {
            if (latitude != null) 'location_lat': latitude,
            if (longitude != null) 'location_long': longitude,
          });
          debugPrint(
              'Successfully synced updated location for $plantId to database.');
        } catch (e) {
          debugPrint('Failed to sync location for $plantId to database: $e');
        }
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

  // Synchronize location locally generated by another screen
  void syncPlantLocationLocal(
      String plantId, String locationName, double latitude, double longitude) {
    bool updated = false;
    for (final communityId in _communityPlants.keys) {
      final plants = _communityPlants[communityId]!;
      final idx = plants.indexWhere((p) => p.id == plantId);
      if (idx != -1) {
        _communityPlants[communityId]![idx] = plants[idx].copyWith(
          location: locationName,
          latitude: latitude,
          longitude: longitude,
        );
        _savePlantsToCache(communityId);
        updated = true;
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  /// Preemptively cache all community plants in background
  /// Call this on app startup to populate Hive with all plants before going offline
  void preemptiveCacheAllCommunityPlants() {
    debugPrint(
        '[CommunityController] Starting preemptive cache of all community plants for ${_communities.length} communities');

    for (final community in _communities) {
      // Fire and forget - cache each community's plants in background
      _preemptiveCacheCommunitySilently(community.id);
    }
  }

  /// Cache plants for a single community without blocking (fire and forget)
  void _preemptiveCacheCommunitySilently(String communityId) {
    // Run in background without blocking UI
    Future.microtask(() async {
      try {
        final plants = await _db.getCommunityMemberPlants(
          communityId,
          userId: _currentUserId,
        );
        _communityPlants[communityId] = plants;
        _savePlantsToCache(communityId);
        debugPrint(
            '[CommunityController] Preemptively cached ${plants.length} plants for community $communityId');
      } catch (e) {
        debugPrint(
            '[CommunityController] Failed to preemptively cache community $communityId: $e');
      }
    });
  }
}
