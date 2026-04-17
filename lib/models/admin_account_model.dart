enum PaymentMethod { jazzcash, easypaisa }

class AdminAccountModel {
  final String id;
  final String adminId;
  final String accountTitle;
  final String accountNumber;
  final PaymentMethod paymentMethod;
  final bool isVerified;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  AdminAccountModel({
    required this.id,
    required this.adminId,
    required this.accountTitle,
    required this.accountNumber,
    required this.paymentMethod,
    this.isVerified = false,
    this.isPrimary = false,
    required this.createdAt,
    this.verifiedAt,
  });

  factory AdminAccountModel.fromMap(Map<String, dynamic> map) {
    return AdminAccountModel(
      id: map['\$id'] ?? '',
      adminId: map['admin_id'] ?? '',
      accountTitle: map['account_title'] ?? '',
      accountNumber: map['account_number'] ?? '',
      paymentMethod: map['payment_method'] == 'easypaisa'
          ? PaymentMethod.easypaisa
          : PaymentMethod.jazzcash,
      isVerified: map['is_verified'] ?? false,
      isPrimary: map['is_primary'] ?? false,
      createdAt: DateTime.parse(
          map['\$createdAt'] ?? DateTime.now().toIso8601String()),
      verifiedAt: map['verified_at'] != null
          ? DateTime.parse(map['verified_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'admin_id': adminId,
      'account_title': accountTitle,
      'account_number': accountNumber,
      'payment_method': paymentMethod.name,
      'is_verified': isVerified,
      'is_primary': isPrimary,
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }
}
