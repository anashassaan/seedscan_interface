import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Low-level Hive cache for user profile and full admin state.
///
/// Cache-first architecture:
///   1. On login: read from Hive → show UI instantly.
///   2. Appwrite sync in background: write fresh data back to Hive.
///   3. On logout: clearAll() wipes every box.
class HiveCacheService {
  // ── Box names ─────────────────────────────────────────────────────────────
  static const String _userBoxName = 'userBox';
  static const String _adminBoxName = 'adminBox';
  static const String _adminCommunitiesBoxName = 'adminCommunitiesBox';
  static const String _adminQrCodesBoxName = 'adminQrCodesBox';
  static const String _cacheMetaBoxName = 'cacheMetaBox';

  // ── Cache TTL constants ───────────────────────────────────────────────────
  /// Admin full-data cache is considered stale after 30 minutes.
  static const Duration adminCacheMaxAge = Duration(minutes: 30);

  /// User profile cache is considered stale after 24 hours.
  static const Duration userCacheMaxAge = Duration(hours: 24);

  // ── Initialization ────────────────────────────────────────────────────────

  /// Must be called once after [Hive.initFlutter()].
  static Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_userBoxName)) await Hive.openBox(_userBoxName);
      if (!Hive.isBoxOpen(_adminBoxName)) await Hive.openBox(_adminBoxName);
      if (!Hive.isBoxOpen(_adminCommunitiesBoxName)) {
        await Hive.openBox<String>(_adminCommunitiesBoxName);
      }
      if (!Hive.isBoxOpen(_adminQrCodesBoxName)) {
        await Hive.openBox<String>(_adminQrCodesBoxName);
      }
      if (!Hive.isBoxOpen(_cacheMetaBoxName)) {
        await Hive.openBox<String>(_cacheMetaBoxName);
      }
    } catch (e) {
      debugPrint('[HiveCacheService] initialize error: $e');
    }
  }

  // ── Safe box accessors ────────────────────────────────────────────────────

  static Box? get _userBox {
    try {
      return Hive.isBoxOpen(_userBoxName) ? Hive.box(_userBoxName) : null;
    } catch (_) {
      return null;
    }
  }

  static Box? get _adminBox {
    try {
      return Hive.isBoxOpen(_adminBoxName) ? Hive.box(_adminBoxName) : null;
    } catch (_) {
      return null;
    }
  }

  static Box<String>? get _adminCommunitiesBox {
    try {
      return Hive.isBoxOpen(_adminCommunitiesBoxName)
          ? Hive.box<String>(_adminCommunitiesBoxName)
          : null;
    } catch (_) {
      return null;
    }
  }

  static Box<String>? get _adminQrCodesBox {
    try {
      return Hive.isBoxOpen(_adminQrCodesBoxName)
          ? Hive.box<String>(_adminQrCodesBoxName)
          : null;
    } catch (_) {
      return null;
    }
  }

  static Box<String>? get _cacheMetaBox {
    try {
      return Hive.isBoxOpen(_cacheMetaBoxName)
          ? Hive.box<String>(_cacheMetaBoxName)
          : null;
    } catch (_) {
      return null;
    }
  }

  // ── USER DATA ─────────────────────────────────────────────────────────────

  static Future<void> cacheUserData(Map<String, dynamic> data) async {
    try {
      await _userBox?.put('profile', data);
      await _setCacheTimestamp('user_profile');
    } catch (e) {
      debugPrint('[HiveCacheService] cacheUserData error: $e');
    }
  }

  static Map<String, dynamic>? getUserData() {
    try {
      final data = _userBox?.get('profile');
      if (data == null) return null;
      return Map<String, dynamic>.from(data as Map);
    } catch (_) {
      return null;
    }
  }

  // ── ADMIN STATS ───────────────────────────────────────────────────────────

  static Future<void> cacheAdminStats(Map<String, dynamic> stats) async {
    try {
      await _adminBox?.put('stats', stats);
    } catch (e) {
      debugPrint('[HiveCacheService] cacheAdminStats error: $e');
    }
  }

  static Map<String, dynamic>? getAdminStats() {
    try {
      final data = _adminBox?.get('stats');
      if (data == null) return null;
      return Map<String, dynamic>.from(data as Map);
    } catch (_) {
      return null;
    }
  }

  // ── ADMIN COMMUNITIES (full serialized list) ───────────────────────────────

  /// Cache the full admin communities list (JSON-encoded).
  /// Each map in [communities] should be the raw serialized community data.
  static Future<void> cacheAdminCommunities(
      List<Map<String, dynamic>> communities) async {
    try {
      final box = _adminCommunitiesBox;
      if (box == null) return;
      await box.put('communities_list', jsonEncode(communities));
      await _setCacheTimestamp('admin_communities');
      debugPrint(
          '[HiveCacheService] Cached ${communities.length} admin communities');
    } catch (e) {
      debugPrint('[HiveCacheService] cacheAdminCommunities error: $e');
    }
  }

  /// Returns the cached admin communities list, or null if not cached.
  static List<Map<String, dynamic>>? getAdminCommunities() {
    try {
      final box = _adminCommunitiesBox;
      if (box == null) return null;
      final raw = box.get('communities_list');
      if (raw == null || raw.isEmpty) return null;
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('[HiveCacheService] getAdminCommunities error: $e');
      return null;
    }
  }

  // ── ADMIN QR CODES (full serialized map) ──────────────────────────────────

  /// Cache the full admin QR codes map.
  /// [qrCodes] maps communityIndex → list of QR code maps.
  static Future<void> cacheAdminQrCodes(
      Map<String, List<Map<String, dynamic>>> qrCodes) async {
    try {
      final box = _adminQrCodesBox;
      if (box == null) return;
      await box.put('qr_codes_map', jsonEncode(qrCodes));
      await _setCacheTimestamp('admin_qr_codes');
      debugPrint(
          '[HiveCacheService] Cached admin QR codes for ${qrCodes.keys.length} communities');
    } catch (e) {
      debugPrint('[HiveCacheService] cacheAdminQrCodes error: $e');
    }
  }

  /// Returns the cached admin QR codes map, or null if not cached.
  static Map<String, List<Map<String, dynamic>>>? getAdminQrCodes() {
    try {
      final box = _adminQrCodesBox;
      if (box == null) return null;
      final raw = box.get('qr_codes_map');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map;
      return decoded.map((k, v) {
        final list = (v as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        return MapEntry(k.toString(), list);
      });
    } catch (e) {
      debugPrint('[HiveCacheService] getAdminQrCodes error: $e');
      return null;
    }
  }

  // ── CACHE TTL / STALENESS ─────────────────────────────────────────────────

  /// Mark cache [key] as updated right now.
  static Future<void> _setCacheTimestamp(String key) async {
    try {
      await _cacheMetaBox?.put(key, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  /// Returns true if cache [key] has never been set OR is older than [maxAge].
  static bool isCacheStale(String key,
      {Duration maxAge = const Duration(minutes: 30)}) {
    try {
      final box = _cacheMetaBox;
      if (box == null) return true;
      final raw = box.get(key);
      if (raw == null || raw.isEmpty) return true;
      final ts = DateTime.tryParse(raw);
      if (ts == null) return true;
      return DateTime.now().difference(ts) > maxAge;
    } catch (_) {
      return true;
    }
  }

  // ── LOGOUT / CLEAR ────────────────────────────────────────────────────────

  /// Wipe ALL boxes — call on logout to prevent data leaks between users.
  static Future<void> clearAll() async {
    try {
      await _userBox?.clear();
      await _adminBox?.clear();
      await _adminCommunitiesBox?.clear();
      await _adminQrCodesBox?.clear();
      await _cacheMetaBox?.clear();
      debugPrint('[HiveCacheService] All caches cleared');
    } catch (e) {
      debugPrint('[HiveCacheService] clearAll error: $e');
    }
  }

  /// Wipe only admin caches (user data kept intact).
  static Future<void> clearAdminCache() async {
    try {
      await _adminBox?.clear();
      await _adminCommunitiesBox?.clear();
      await _adminQrCodesBox?.clear();
      debugPrint('[HiveCacheService] Admin cache cleared');
    } catch (e) {
      debugPrint('[HiveCacheService] clearAdminCache error: $e');
    }
  }
}
