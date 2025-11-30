// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';

class AuthController extends ChangeNotifier {
  AuthController();

  // Simple in-memory user model for demo
  String? _name;
  String? _email;
  String? _username;
  String? _profileImagePath;
  bool _loggedIn = false;

  bool get isLoggedIn => _loggedIn;
  String get userName => _name ?? 'Student';
  String get userHandle => _username ?? 'user123';
  String? get profileImage => _profileImagePath;

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
    // Mock sign-in: accepts any email with password length >=6
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (validateEmail(email) != null || validatePassword(password) != null) {
      return false;
    }
    _email = email;
    _name ??= email.split('@').first;
    _username ??= email.split('@').first;
    _loggedIn = true;
    notifyListeners();
    return true;
  }

  Future<bool> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
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
    notifyListeners();
    return true;
  }

  void updateProfile({required String name, String? imagePath}) {
    _name = name;
    if (imagePath != null) {
      _profileImagePath = imagePath;
    }
    notifyListeners();
  }

  void signOut() {
    _loggedIn = false;
    _name = null;
    _email = null;
    _username = null;
    _profileImagePath = null;
    notifyListeners();
  }
}
