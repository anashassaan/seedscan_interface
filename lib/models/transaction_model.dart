// lib/models/transaction_model.dart
/// Matches Appwrite collection: `activity_logs`
/// Replaces old TransactionModel with the verified activity log schema.

class ActivityLog {
  final String id;
  final String userId;
  final String plantId;
  final String actionType; // water, scan_disease, register
  final int coinsAwarded;
  final String verificationStatus; // verified, rejected
  final String proofImageId;
  final String? rejectionReason;
  final String communityId;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.plantId,
    required this.actionType,
    required this.coinsAwarded,
    required this.verificationStatus,
    required this.proofImageId,
    this.rejectionReason,
    this.communityId = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['user_id'] ?? '',
      plantId: json['plant_id'] ?? '',
      actionType: json['action_type'] ?? '',
      coinsAwarded: json['coins_awarded'] ?? 0,
      verificationStatus: json['verification_status'] ?? '',
      proofImageId: json['proof_image_id'] ?? '',
      rejectionReason: json['rejection_reason'],
      communityId: json['community_id'] ?? '',
      createdAt: json['created_at'] != null || json['\$createdAt'] != null
          ? DateTime.tryParse(json['created_at'] ?? json['\$createdAt'] ?? '')
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'plant_id': plantId,
      'action_type': actionType,
      'coins_awarded': coinsAwarded,
      'verification_status': verificationStatus,
      'proof_image_id': proofImageId,
      'rejection_reason': rejectionReason,
      'community_id': communityId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Backward-compat alias if code references old type / enum
enum TransactionType { earn, spend, bonus, penalty }
