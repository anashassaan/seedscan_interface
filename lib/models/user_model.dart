// lib/models/user_model.dart
/// Matches Appwrite collection: `users`

class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final int walletBalance;
  final int currentStreak;
  final List<String> joinedDrives;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.username = '',
    required this.email,
    this.walletBalance = 0,
    this.currentStreak = 0,
    this.joinedDrives = const [],
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['\$id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      walletBalance: json['wallet_balance'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      joinedDrives: List<String>.from(json['joined_drives'] ?? []),
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['\$createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'wallet_balance': walletBalance,
      'current_streak': currentStreak,
      'joined_drives': joinedDrives,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    int? walletBalance,
    int? currentStreak,
    List<String>? joinedDrives,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      walletBalance: walletBalance ?? this.walletBalance,
      currentStreak: currentStreak ?? this.currentStreak,
      joinedDrives: joinedDrives ?? this.joinedDrives,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
