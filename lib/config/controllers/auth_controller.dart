// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';

class AuthController extends ChangeNotifier {
  AuthController();

  // Simple in-memory user model for demo
  String? _name;
  String? _email;
  String? _cmsId;
  bool _loggedIn = false;

  bool get isLoggedIn => _loggedIn;
  String get userName => _name ?? 'Student';

  // Validation helpers
  String? validateName(String? v) {
    if (v == null || v.trim().length < 3)
      return 'Enter full name (min 3 chars)';
    return null;
  }

  String? validateCms(String? v) {
    if (v == null || v.trim().isEmpty) return 'CMS ID required';
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
    _loggedIn = true;
    notifyListeners();
    return true;
  }

  Future<bool> signUp({
    required String fullName,
    required String cmsId,
    required String email,
    required String password,
  }) async {
    // Mock sign-up with minimal checks
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (validateName(fullName) != null ||
        validateCms(cmsId) != null ||
        validateEmail(email) != null ||
        validatePassword(password) != null) {
      return false;
    }
    _name = fullName;
    _cmsId = cmsId;
    _email = email;
    _loggedIn = true;
    notifyListeners();
    return true;
  }

  void signOut() {
    _loggedIn = false;
    _name = null;
    _email = null;
    _cmsId = null;
    notifyListeners();
  }
}
