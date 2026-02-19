// lib/models/qr_code_model.dart
/// Now contains Drive and Reward models matching the Appwrite schema.

/// Matches Appwrite collection: `drives`
class DriveModel {
  final String id;
  final String title;
  final String orgName;
  final String status; // active, completed, archived
  final int targetCount;
  final int aliveCount;
  final DateTime startDate;

  DriveModel({
    required this.id,
    required this.title,
    required this.orgName,
    this.status = 'active',
    required this.targetCount,
    this.aliveCount = 0,
    required this.startDate,
  });

  factory DriveModel.fromJson(Map<String, dynamic> json) {
    return DriveModel(
      id: json['\$id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      orgName: json['org_name'] ?? '',
      status: json['status'] ?? 'active',
      targetCount: json['target_count'] ?? 0,
      aliveCount: json['alive_count'] ?? 0,
      startDate: DateTime.parse(
        json['start_date'] ??
            json['\$createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'org_name': orgName,
      'status': status,
      'target_count': targetCount,
      'alive_count': aliveCount,
      'start_date': startDate.toIso8601String(),
    };
  }

  DriveModel copyWith({
    String? id,
    String? title,
    String? orgName,
    String? status,
    int? targetCount,
    int? aliveCount,
    DateTime? startDate,
  }) {
    return DriveModel(
      id: id ?? this.id,
      title: title ?? this.title,
      orgName: orgName ?? this.orgName,
      status: status ?? this.status,
      targetCount: targetCount ?? this.targetCount,
      aliveCount: aliveCount ?? this.aliveCount,
      startDate: startDate ?? this.startDate,
    );
  }
}

/// Matches Appwrite collection: `rewards`
class RewardModel {
  final String id;
  final String title;
  final int costCoins;
  final int stock;

  RewardModel({
    required this.id,
    required this.title,
    required this.costCoins,
    required this.stock,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['\$id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      costCoins: json['cost_coins'] ?? 0,
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'cost_coins': costCoins,
      'stock': stock,
    };
  }
}

/// Matches Appwrite collection: `user_fcm_tokens`
class UserFcmToken {
  final String id;
  final String userId;
  final String fcmToken;
  final String? devicePlatform; // android, ios
  final DateTime updatedAt;

  UserFcmToken({
    required this.id,
    required this.userId,
    required this.fcmToken,
    this.devicePlatform,
    required this.updatedAt,
  });

  factory UserFcmToken.fromJson(Map<String, dynamic> json) {
    return UserFcmToken(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['user_id'] ?? '',
      fcmToken: json['fcm_token'] ?? '',
      devicePlatform: json['device_platform'],
      updatedAt: DateTime.parse(
        json['updated_at'] ??
            json['\$updatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'fcm_token': fcmToken,
      'device_platform': devicePlatform,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Backward-compat – kept so existing admin code compiles.
class QRCodeModel {
  final String id;
  final String code;
  final String type;
  final DateTime generatedAt;
  final String? assignedTo;
  final DateTime? scannedAt;
  final String? plantId;
  final bool isUsed;
  final String? batchId;

  QRCodeModel({
    required this.id,
    required this.code,
    required this.type,
    required this.generatedAt,
    this.assignedTo,
    this.scannedAt,
    this.plantId,
    this.isUsed = false,
    this.batchId,
  });

  factory QRCodeModel.fromJson(Map<String, dynamic> json) {
    return QRCodeModel(
      id: json['\$id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? 'plant',
      generatedAt: DateTime.parse(json['generatedAt'] ??
          json['\$createdAt'] ??
          DateTime.now().toIso8601String()),
      assignedTo: json['assignedTo'],
      scannedAt:
          json['scannedAt'] != null ? DateTime.parse(json['scannedAt']) : null,
      plantId: json['plantId'],
      isUsed: json['isUsed'] ?? false,
      batchId: json['batchId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'type': type,
      'generatedAt': generatedAt.toIso8601String(),
      'assignedTo': assignedTo,
      'scannedAt': scannedAt?.toIso8601String(),
      'plantId': plantId,
      'isUsed': isUsed,
      'batchId': batchId,
    };
  }

  QRCodeModel copyWith({
    String? id,
    String? code,
    String? type,
    DateTime? generatedAt,
    String? assignedTo,
    DateTime? scannedAt,
    String? plantId,
    bool? isUsed,
    String? batchId,
  }) {
    return QRCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      generatedAt: generatedAt ?? this.generatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      scannedAt: scannedAt ?? this.scannedAt,
      plantId: plantId ?? this.plantId,
      isUsed: isUsed ?? this.isUsed,
      batchId: batchId ?? this.batchId,
    );
  }
}
