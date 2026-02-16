// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import '../../services/appwrite_service.dart';

class AuthController extends ChangeNotifier {
  AuthController();

  final AppwriteService _appwriteService = AppwriteService();

  // Simple in-memory user model for demo
  String? _name;
  String? _email;
  String? _username;
  String? _profileImagePath;
  bool _loggedIn = false;
  bool _isAdmin = false;
  String? _userId;

  bool get isLoggedIn => _loggedIn;
  bool get isAdmin => _isAdmin;
  String get userName => _name ?? 'Student';
  String get userHandle => _username ?? 'user123';
  String? get userEmail => _email;
  String? get profileImage => _profileImagePath;
  String? get userId => _userId;

  // Validation helpers
  String? validateName(String? v) {
    if (v == null || v.trim().length < 3)
      return 'Enter full name (min 3 chars)';
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
    if (v == null || v.length < 6) return 'Password min 6 characters';
    return null;
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      // Try Appwrite authentication first
      final session = await _appwriteService.signIn(email, password);
      if (session != null) {
        final user = await _appwriteService.getCurrentUser();
        if (user != null) {
          _userId = user.$id;
          _email = user.email;
          _name = user.name;
          _username = user.email.split('@').first;
          _loggedIn = true;

          // Check admin role
          _isAdmin = await _appwriteService.isAdmin();

          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      // Fall back to mock sign-in
      print('Appwrite signin failed, using mock signin: $e');
    }

    // Mock sign-in
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (validateEmail(email) != null || validatePassword(password) != null) {
      return false;
    }

    _email = email;
    _username = email.split('@').first;
    _name = email.split('@').first;
    _loggedIn = true;

    // Demo: Make specific emails admin
    _isAdmin = email.toLowerCase().contains('admin');

    notifyListeners();
    return true;
  }

  Future<bool> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Try Appwrite registration first
      final user = await _appwriteService.signUp(
        email: email,
        password: password,
        name: fullName,
      );
      if (user != null) {
        // Auto sign in after signup
        return await signIn(email: email, password: password);
      }
    } catch (e) {
      // Fall back to mock registration
      print('Appwrite signup failed, using mock signup: $e');
    }

    // Mock sign-up with minimal checks
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (validateName(fullName) != null ||
        validateUsername(username) != null ||
        validateEmail(email) != null ||
        validatePassword(password) != null) {
      return false;
    }
    _name = fullName;
    _username = username;
    _email = email;
    _loggedIn = true;

    // Demo: Make specific emails admin
    _isAdmin = email.toLowerCase().contains('admin');

    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    try {
      await _appwriteService.signOut();
    } catch (e) {
      print('Appwrite signout error: $e');
    }

    _loggedIn = false;
    _isAdmin = false;
    _name = null;
    _email = null;
    _username = null;
    _profileImagePath = null;
    _userId = null;
    notifyListeners();
  }

  /// Initialize Appwrite and check existing session
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
        _isAdmin = await _appwriteService.isAdmin();
        notifyListeners();
      }
    } catch (e) {
      print('Auth initialization error: $e');
    }
  }

  void updateProfile({required String name, String? imagePath}) {
    _name = name;
    if (imagePath != null) {
      _profileImagePath = imagePath;
    }
    notifyListeners();
  }
}
