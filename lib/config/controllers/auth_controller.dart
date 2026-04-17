// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/appwrite_service.dart';
import '../../services/garden_cache_service.dart';
import '../../services/hive_cache_service.dart';
import '../../services/llm_service.dart';
import '../../models/user_model.dart';

class AuthController extends ChangeNotifier {
  AuthController();

  final AppwriteService _appwriteService = AppwriteService();

  // SharedPreferences keys for persistent login state
  static const String _keyLoggedIn = 'auth_logged_in';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyEmail = 'auth_email';
  static const String _keyName = 'auth_name';
  static const String _keyUsername = 'auth_username';
  static const String _keyIsAdmin = 'auth_is_admin';

  // ── State ────────────────────────────────────────────────────────────────
  String? _name;
  String? _email;
  String? _username;
  String? _profileImagePath;
  bool _isUploadingAvatar = false;
  bool _loggedIn = false;
  bool _isAdmin = false;
  String? _userId;
  String? _authError;
  UserModel? _userModel;
  int _walletBalance = 0;
  int _currentStreak = 0;

  // ── Getters ──────────────────────────────────────────────────────────────
  bool get isLoggedIn => _loggedIn;
  bool get isAdmin => _isAdmin;
  String? get authError => _authError;
  String get userName => _name ?? 'Student';
  String get userHandle => _username ?? 'user123';
  String? get userEmail => _email;
  bool get isUploadingAvatar => _isUploadingAvatar;
  String? get profileImage => _profileImagePath;

  String? get profileImageUrl {
    if (_userModel?.profileImageId == null) return null;
    return _appwriteService.getProfileImageUrl(_userModel!.profileImageId!);
  }

  String get userInitials {
    final n = _name ?? _username ?? 'U';
    return n.isNotEmpty ? n[0].toUpperCase() : 'U';
  }

  String? get userId => _userId;
  UserModel? get userModel => _userModel;
  int get walletBalance => _walletBalance;
  int get currentStreak => _currentStreak;

  // ── Validation helpers ───────────────────────────────────────────────────
  String? validateName(String? v) {
    if (v == null || v.trim().length < 3) {
      return 'Enter full name (min 3 chars)';
    }
    return null;
  }

  String? validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username required';
    if (v.length < 3) return 'Min 3 chars';
    return null;
  }

  String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email required';
    final r = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!r.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.length < 8) {
      return 'Password min 8 characters';
    }
    return null;
  }

  /// Validates the login identifier (email or username).
  String? validateLoginId(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email or username required';
    if (v.trim().length < 3) return 'Min 3 characters';
    return null;
  }

  // ── Persist / clear login state via SharedPreferences ────────────────────
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLoggedIn, true);
      await prefs.setString(_keyUserId, _userId ?? '');
      await prefs.setString(_keyEmail, _email ?? '');
      await prefs.setString(_keyName, _name ?? '');
      await prefs.setString(_keyUsername, _username ?? '');
      await prefs.setBool(_keyIsAdmin, _isAdmin);

      if (_userModel != null) {
        await HiveCacheService.cacheUserData(_userModel!.toJson());
      }
      debugPrint('[AUTH] Session saved to SharedPreferences and Hive cache');
    } catch (e) {
      debugPrint('[AUTH] Failed to save session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLoggedIn);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyName);
      await prefs.remove(_keyUsername);
      await prefs.remove(_keyIsAdmin);

      await HiveCacheService.clearAll();
      debugPrint(
          '[AUTH] Session cleared from SharedPreferences and Hive cache');
    } catch (e) {
      debugPrint('[AUTH] Failed to clear session: $e');
    }
  }

  // ── Sign In (supports email OR username) ──────────────────────────────────
  Future<bool> signIn(
      {required String emailOrUsername, required String password}) async {
    _authError = null;
    try {
      String email = emailOrUsername.trim();

      // If the input doesn't look like an email, treat it as a username
      if (!email.contains('@')) {
        final userDoc = await _appwriteService.getUserByUsername(email);
        if (userDoc == null) {
          _authError = 'Username not found. Please sign up first.';
          notifyListeners();
          return false;
        }
        // Get the email from the user document
        email = userDoc.data['email'] ?? '';
        if (email.isEmpty) {
          _authError = 'Account error. Please contact support.';
          notifyListeners();
          return false;
        }
      }

      final session = await _appwriteService.signIn(email, password);
      if (session != null) {
        final user = await _appwriteService.getCurrentUser();
        if (user != null) {
          _userId = user.$id;
          _email = user.email;
          _name = user.name;
          _username = user.email.split('@').first;
          _loggedIn = true;

          // Load user profile document from DB
          await _loadUserProfile(user.$id);

          // Check admin role — prefer the already-loaded profile
          if (_userModel != null && _userModel!.isAdmin) {
            _isAdmin = true;
            debugPrint(
                '[AUTH] Admin detected from user profile (role=${_userModel!.role})');
          } else {
            // Fallback: labels + DB fetch via service
            _isAdmin = await _appwriteService.isAdmin();
            debugPrint('[AUTH] isAdmin from service: $_isAdmin');
          }
          debugPrint(
              '[AUTH] signIn complete — isAdmin=$_isAdmin, userId=$_userId');

          await _saveSession();
          notifyListeners();

          // 🔥 Automatically begin background AI model download
          LLMService().initialize().catchError((_) {});

          return true;
        }
      }
    } on AppwriteException catch (e) {
      final type = e.type ?? '';
      final code = e.code ?? 0;

      if (type == 'user_not_found') {
        _authError = 'User does not exist. Please sign up first.';
      } else if (type == 'user_invalid_credentials' || code == 401) {
        _authError = 'Invalid email/username or password.';
      } else if (type == 'general_rate_limit_exceeded' || code == 429) {
        _authError = 'Too many attempts. Please try again later.';
      } else {
        _authError = e.message ?? 'Sign in failed. Please try again.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Connection error. Please check your internet.';
      notifyListeners();
      return false;
    }

    _authError = 'Sign in failed. Please try again.';
    notifyListeners();
    return false;
  }

  // ── Sign Up ──────────────────────────────────────────────────────────────
  Future<bool> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String role = 'user',
    String? communityName,
    String? organization,
    String? adminReason,
  }) async {
    _authError = null;
    try {
      // 1. Create Appwrite Auth account
      final user = await _appwriteService.signUp(
        email: email,
        password: password,
        name: fullName,
      );

      if (user != null) {
        // 2. Sign in to get a session (needed for DB writes)
        await _appwriteService.signIn(email, password);

        // 3. Create the user profile document in `users` collection
        //    Document ID = Auth user $id so they stay linked.
        try {
          await _appwriteService.createUserDocument(
            userId: user.$id,
            name: fullName,
            username: username,
            email: email,
            role: role,
            communityName: communityName,
            organization: organization,
            adminReason: adminReason,
          );
        } catch (dbErr) {
          // If the document already exists (e.g. retry), that's OK.
          debugPrint('User document creation note: $dbErr');
        }

        // 4. Set local state
        _userId = user.$id;
        _email = email;
        _name = fullName;
        _username = username;
        _loggedIn = true;
        _walletBalance = 0;
        _currentStreak = 0;

        // Set admin directly from chosen role (reliable, no DB read-back needed)
        _isAdmin = role == 'admin';

        await _saveSession();
        notifyListeners();

        // 🔥 Automatically begin background AI model download
        LLMService().initialize().catchError((_) {});

        return true;
      }
    } on AppwriteException catch (e) {
      final type = e.type ?? '';

      if (type == 'user_already_exists') {
        _authError = 'An account with this email already exists.';
      } else if (type == 'general_argument_invalid') {
        _authError = 'Invalid details. Password must be 8+ characters.';
      } else if (type == 'general_rate_limit_exceeded') {
        _authError = 'Too many attempts. Please try again later.';
      } else {
        _authError = e.message ?? 'Sign up failed. Please try again.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Connection error. Please check your internet.';
      notifyListeners();
      return false;
    }

    _authError = 'Sign up failed. Please try again.';
    notifyListeners();
    return false;
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _appwriteService.signOut();
    } catch (e) {
      debugPrint('Appwrite signout error: $e');
    }

    // Wipe locally cached garden data so the next user starts clean
    try {
      await GardenCacheService.clearAll();
    } catch (e) {
      debugPrint('GardenCacheService clearAll error: $e');
    }

    // CRITICAL: Wipe admin cache so the next admin user doesn't see previous admin's data
    try {
      await HiveCacheService.clearAdminCache();
    } catch (e) {
      debugPrint('HiveCacheService clearAdminCache error: $e');
    }

    await _clearSession();

    _loggedIn = false;
    _isAdmin = false;
    _name = null;
    _email = null;
    _username = null;
    _profileImagePath = null;
    _userId = null;
    _userModel = null;
    _walletBalance = 0;
    _currentStreak = 0;
    _authError = null;
    notifyListeners();
  }

  // ── Initialize (check existing session on app start) ─────────────────────
  /// Cache-first strategy: Load from Hive/SharedPrefs instantly, then sync from Appwrite
  Future<void> initialize() async {
    _appwriteService.initialize();

    // STEP 1: INSTANT LOAD FROM CACHE (Hive + SharedPreferences)
    await _restoreFromPrefs();

    // STEP 2: BACKGROUND SYNC WITH APPWRITE (silent refresh)
    _syncWithAppwriteInBackground();
  }

  /// Background sync: Refreshes user data from Appwrite without blocking UI
  Future<void> _syncWithAppwriteInBackground() async {
    try {
      debugPrint('[AUTH] Starting background Appwrite sync...');
      final user = await _appwriteService.getCurrentUser();

      if (user != null) {
        debugPrint('[AUTH] Active Appwrite session found for ${user.$id}');
        _userId = user.$id;
        _email = user.email;
        _username = user.email.split('@').first;
        _loggedIn = true;

        // Load fresh user profile from Appwrite
        await _loadUserProfile(user.$id);

        // Check admin role from refreshed profile
        if (_userModel != null && _userModel!.isAdmin) {
          _isAdmin = true;
          debugPrint(
              '[AUTH] Admin detected from profile (role=${_userModel!.role})');
        } else {
          _isAdmin = await _appwriteService.isAdmin();
          debugPrint('[AUTH] isAdmin from service: $_isAdmin');
        }

        // Update cache with fresh data
        await _saveSession();
        debugPrint(
            '[AUTH] Background sync complete — isAdmin=$_isAdmin, userId=$_userId');
        notifyListeners();
      } else {
        debugPrint('[AUTH] No active Appwrite session — user logged out');
        await _clearSession();
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
          '[AUTH] Background Appwrite sync error (using cached data): $e');
      // User continues with cached data; no interruption
    }
  }

  /// Restore cached auth state from SharedPreferences & Hive (offline/instant load).
  Future<void> _restoreFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
      if (!wasLoggedIn) return;

      _userId = prefs.getString(_keyUserId);
      _email = prefs.getString(_keyEmail);
      _name = prefs.getString(_keyName);
      _username = prefs.getString(_keyUsername);
      _isAdmin = prefs.getBool(_keyIsAdmin) ?? false;
      _loggedIn = true;

      // Extract User model from Hive for instantaneous data loading
      final userData = HiveCacheService.getUserData();
      if (userData != null) {
        _userModel = UserModel.fromJson(userData);
        _walletBalance = _userModel!.walletBalance;
        _currentStreak = _userModel!.currentStreak;

        if (_userModel!.name.isNotEmpty) _name = _userModel!.name;
        if (_userModel!.username.isNotEmpty) _username = _userModel!.username;
      }

      debugPrint(
          '[AUTH] Restored from SharedPreferences & Hive — userId=$_userId, isAdmin=$_isAdmin');
      notifyListeners();

      // 🔥 Automatically begin background AI model download
      LLMService().initialize().catchError((_) {});
    } catch (e) {
      debugPrint('[AUTH] Failed to restore from SharedPreferences/Hive: $e');
    }
  }

  // ── Load user profile from DB `users` collection ─────────────────────────
  Future<void> _loadUserProfile(String userId) async {
    try {
      final doc = await _appwriteService.getUserDocument(userId);
      debugPrint(
          '[AUTH] getUserDocument($userId) → ${doc != null ? 'found' : 'null'}');
      if (doc != null) {
        debugPrint(
            '[AUTH] doc.data role=${doc.data['role']}, name=${doc.data['name']}');
        _userModel = UserModel.fromJson(doc.data);
        _walletBalance = _userModel!.walletBalance;
        _currentStreak = _userModel!.currentStreak;
        // Use DB name/username if available
        if (_userModel!.name.isNotEmpty) {
          _name = _userModel!.name;
        }
        if (_userModel!.username.isNotEmpty) {
          _username = _userModel!.username;
        }
      }
    } catch (e) {
      debugPrint('[AUTH] Failed to load user profile: $e');
    }
  }

  // ── Update profile ──────────────────────────────────────────────────────
  Future<void> updateProfileName(String name) async {
    _name = name;
    if (_userModel != null) {
      _userModel = _userModel!.copyWith(name: name);
      try {
        await _appwriteService.updateDocument(
          collectionId: AppwriteService.usersCollectionId,
          documentId: _userId!,
          data: {'name': name},
        );
      } catch (e) {
        debugPrint('[AUTH] Failed to update name in DB: \$e');
      }
    }
    await _saveSession();
    notifyListeners();
  }

  Future<void> uploadAvatar(String imagePath) async {
    if (_userId == null) return;
    try {
      _isUploadingAvatar = true;
      notifyListeners();

      // Upload file directly to the Profile Images Bucket
      final uploadedFile = await _appwriteService.uploadProfileImage(imagePath);

      // (Optional) Delete old avatar file here if passing old ID to AppwriteService
      if (_userModel?.profileImageId != null) {
        await _appwriteService.deleteProfileImage(_userModel!.profileImageId!);
      }

      // Update Database UserModel
      await _appwriteService.updateDocument(
        collectionId: AppwriteService.usersCollectionId,
        documentId: _userId!,
        data: {'profile_image_id': uploadedFile.$id},
      );

      // Refresh Memory & Cache
      _userModel = _userModel!.copyWith(profileImageId: uploadedFile.$id);
      await _saveSession();
    } catch (e) {
      debugPrint('[AUTH] Avatar upload failed: \$e');
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }
}
