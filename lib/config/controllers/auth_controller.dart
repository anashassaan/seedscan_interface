// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../../services/appwrite_service.dart';
import '../../services/garden_cache_service.dart';
import '../../models/user_model.dart';

class AuthController extends ChangeNotifier {
  AuthController();

  final AppwriteService _appwriteService = AppwriteService();

  // ── State ────────────────────────────────────────────────────────────────
  String? _name;
  String? _email;
  String? _username;
  String? _profileImagePath;
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
  String? get profileImage => _profileImagePath;
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

          notifyListeners();
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

        notifyListeners();
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
  Future<void> initialize() async {
    try {
      _appwriteService.initialize();
      final user = await _appwriteService.getCurrentUser();
      if (user != null) {
        _userId = user.$id;
        _email = user.email;
        _name = user.name;
        _username = user.email.split('@').first;
        _loggedIn = true;

        // Load user profile document
        await _loadUserProfile(user.$id);

        // Check admin role — prefer the already-loaded profile
        if (_userModel != null && _userModel!.isAdmin) {
          _isAdmin = true;
          debugPrint(
              '[AUTH] init: Admin detected from profile (role=${_userModel!.role})');
        } else {
          _isAdmin = await _appwriteService.isAdmin();
          debugPrint('[AUTH] init: isAdmin from service: $_isAdmin');
        }
        debugPrint(
            '[AUTH] initialize complete — isAdmin=$_isAdmin, userId=$_userId');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
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
  void updateProfile({required String name, String? imagePath}) {
    _name = name;
    if (imagePath != null) {
      _profileImagePath = imagePath;
    }
    notifyListeners();
  }
}
