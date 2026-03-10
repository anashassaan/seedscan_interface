// lib/services/garden_cache_service.dart
/// Hive-backed local cache for My Garden QR entries.
///
/// Flow:
///   1. App launch / login  → Appwrite fetch → [syncAll] stores in Hive
///   2. Image upload        → Appwrite bucket upload → [updateImage] patches Hive
///   3. Screen open         → [getImageUrl] reads from Hive instantly (never throws)
///   4. Logout              → [clearAll] wipes the box
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GardenCacheService {
  static const String _boxName = 'garden_cache';
  static const String _plantsBoxName = 'community_plants_cache';
  static bool _ready = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Must be called once after [Hive.initFlutter()].
  static Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox<String>(_boxName);
      }
      if (!Hive.isBoxOpen(_plantsBoxName)) {
        await Hive.openBox<String>(_plantsBoxName);
      }
      _ready = true;
    } catch (e) {
      debugPrint('GardenCacheService.initialize error: $e');
    }
  }

  /// Safe accessor — returns null instead of throwing when box isn't open.
  static Box<String>? get _box {
    try {
      if (!_ready || !Hive.isBoxOpen(_boxName)) return null;
      return Hive.box<String>(_boxName);
    } catch (_) {
      return null;
    }
  }

  static Box<String>? get _plantsBox {
    try {
      if (!_ready || !Hive.isBoxOpen(_plantsBoxName)) return null;
      return Hive.box<String>(_plantsBoxName);
    } catch (_) {
      return null;
    }
  }

  // ── Write ────────────────────────────────────────────────────────────────

  /// Cache a single garden entry (stores imageFileId + imageUrl + metadata).
  /// Never throws — silently no-ops when box is unavailable.
  static Future<void> cacheEntry({
    required String docId,
    required String plantName,
    required String localName,
    required String category,
    String? imageFileId,
    String? imageUrl,
  }) async {
    try {
      final box = _box;
      if (box == null) return;

      // Preserve an existing uploaded image URL so a fresh Appwrite fetch
      // (which may lag behind) doesn't overwrite it with null.
      final existing = _getMapFrom(box, docId);
      final data = <String, dynamic>{
        'plantName': plantName,
        'localName': localName,
        'category': category,
        'imageFileId': imageFileId ?? existing['imageFileId'] ?? '',
        'imageUrl': imageUrl ?? existing['imageUrl'] ?? '',
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await box.put(docId, jsonEncode(data));
    } catch (e) {
      debugPrint('GardenCacheService.cacheEntry error: $e');
    }
  }

  /// Sync a full list of entries (call after loading from Appwrite).
  static Future<void> syncAll(
    List<Map<String, String?>> entries,
  ) async {
    for (final e in entries) {
      final docId = e['docId'];
      if (docId == null || docId.isEmpty) continue;
      await cacheEntry(
        docId: docId,
        plantName: e['plantName'] ?? '',
        localName: e['localName'] ?? '',
        category: e['category'] ?? '',
        imageFileId: e['imageFileId'],
        imageUrl: e['imageUrl'],
      );
    }
  }

  /// Update ONLY the image fields for a cached entry (called right after upload).
  static Future<void> updateImage(
    String docId,
    String fileId,
    String url,
  ) async {
    try {
      final box = _box;
      if (box == null) return;

      final map = _getMapFrom(box, docId);
      map['imageFileId'] = fileId;
      map['imageUrl'] = url;
      map['updatedAt'] = DateTime.now().toIso8601String();
      await box.put(docId, jsonEncode(map));
    } catch (e) {
      debugPrint('GardenCacheService.updateImage error: $e');
    }
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Returns the cached preview URL for [docId], or null.
  /// Safe to call from build() — never throws.
  static String? getImageUrl(String docId) {
    try {
      final box = _box;
      if (box == null) return null;
      final url = _getMapFrom(box, docId)['imageUrl'] as String?;
      return (url != null && url.isNotEmpty) ? url : null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the cached fileId for [docId], or null.
  static String? getFileId(String docId) {
    try {
      final box = _box;
      if (box == null) return null;
      final id = _getMapFrom(box, docId)['imageFileId'] as String?;
      return (id != null && id.isNotEmpty) ? id : null;
    } catch (_) {
      return null;
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────

  /// Persist all plants for a community (overwrites previous cache).
  static Future<void> saveCommunityPlants(
    String communityId,
    List<Map<String, dynamic>> plants,
  ) async {
    try {
      final box = _plantsBox;
      if (box == null) return;
      await box.put(communityId, jsonEncode(plants));
    } catch (e) {
      debugPrint('GardenCacheService.saveCommunityPlants error: $e');
    }
  }

  /// Returns cached plants for [communityId], or null if nothing saved.
  static List<Map<String, dynamic>>? getCommunityPlantsCache(
      String communityId) {
    try {
      final box = _plantsBox;
      if (box == null) return null;
      final raw = box.get(communityId);
      if (raw == null || raw.isEmpty) return null;
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Clear the entire cache — call on logout.
  static Future<void> clearAll() async {
    try {
      final box = _box;
      if (box != null) await box.clear();
      final plantsBox = _plantsBox;
      if (plantsBox != null) await plantsBox.clear();
      // _ready stays true: the box remains open, just emptied
    } catch (e) {
      debugPrint('GardenCacheService.clearAll error: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _getMapFrom(Box<String> box, String docId) {
    final raw = box.get(docId);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }
}
