// lib/models/user_model.dart
/// Matches Appwrite collection: `users`

class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String role; // 'user' or 'admin'
  final int walletBalance;
  final int currentStreak;
  final List<String> joinedDrives;
  final String? profileImageId;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.username = '',
    required this.email,
    this.role = 'user',
    this.walletBalance = 0,
    this.currentStreak = 0,
    this.joinedDrives = const [],
    this.profileImageId,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['\$id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      walletBalance: json['wallet_balance'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      joinedDrives:
          (json['joined_drives'] as List? ?? []).whereType<String>().toList(),
      profileImageId: json['profile_image_id'],
      createdAt: DateTime.tryParse(
            json['created_at'] ?? json['\$createdAt'] ?? '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'wallet_balance': walletBalance,
      'current_streak': currentStreak,
      'joined_drives': joinedDrives,
      'profile_image_id': profileImageId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? role,
    int? walletBalance,
    int? currentStreak,
    List<String>? joinedDrives,
    String? profileImageId,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      walletBalance: walletBalance ?? this.walletBalance,
      currentStreak: currentStreak ?? this.currentStreak,
      joinedDrives: joinedDrives ?? this.joinedDrives,
      profileImageId: profileImageId ?? this.profileImageId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
