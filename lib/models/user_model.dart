// lib/models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final int plantCount;
  final int coins;
  final List<String> communityIds;
  final bool isAdmin;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.profileImage,
    required this.createdAt,
    this.lastLogin,
    this.plantCount = 0,
    this.coins = 0,
    this.communityIds = const [],
    this.isAdmin = false,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['\$id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt'] ??
          json['\$createdAt'] ??
          DateTime.now().toIso8601String()),
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      plantCount: json['plantCount'] ?? 0,
      coins: json['coins'] ?? 0,
      communityIds: List<String>.from(json['communityIds'] ?? []),
      isAdmin: json['isAdmin'] ?? false,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'plantCount': plantCount,
      'coins': coins,
      'communityIds': communityIds,
      'isAdmin': isAdmin,
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? profileImage,
    DateTime? createdAt,
    DateTime? lastLogin,
    int? plantCount,
    int? coins,
    List<String>? communityIds,
    bool? isAdmin,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      plantCount: plantCount ?? this.plantCount,
      coins: coins ?? this.coins,
      communityIds: communityIds ?? this.communityIds,
      isAdmin: isAdmin ?? this.isAdmin,
      isActive: isActive ?? this.isActive,
    );
  }
}
