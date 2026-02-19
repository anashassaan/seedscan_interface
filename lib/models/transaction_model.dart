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

  ActivityLog({
    required this.id,
    required this.userId,
    required this.plantId,
    required this.actionType,
    required this.coinsAwarded,
    required this.verificationStatus,
    required this.proofImageId,
    this.rejectionReason,
  });

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
    };
  }
}

/// Backward-compat alias if code references old type / enum
enum TransactionType { earn, spend, bonus, penalty }
