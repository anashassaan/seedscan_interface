enum WithdrawalStatus { pending, approved, completed, rejected }

enum PaymentMethod { jazzcash, easypaisa }

class WithdrawalModel {
  final String id;
  final String userId;
  final String communityOwnerId; // To link to the admin/owner
  final int requestedCoins;
  final double equivalentPKR;
  final PaymentMethod paymentMethod;
  final String accountTitle;
  final String accountNumber;
  final WithdrawalStatus status;
  final DateTime createdAt;
  final String? adminNote;

  WithdrawalModel({
    required this.id,
    required this.userId,
    required this.communityOwnerId,
    required this.requestedCoins,
    required this.equivalentPKR,
    required this.paymentMethod,
    required this.accountTitle,
    required this.accountNumber,
    this.status = WithdrawalStatus.pending,
    required this.createdAt,
    this.adminNote,
  });

  factory WithdrawalModel.fromMap(Map<String, dynamic> map) {
    return WithdrawalModel(
      id: map['\$id'] ?? '',
      userId: map['user_id'] ?? '',
      communityOwnerId: map['owner_id'] ?? '',
      requestedCoins: map['requested_coins'] ?? 0,
      equivalentPKR: (map['equivalent_pkr'] ?? 0).toDouble(),
      paymentMethod: map['payment_method'] == 'easypaisa'
          ? PaymentMethod.easypaisa
          : PaymentMethod.jazzcash,
      accountTitle: map['account_title'] ?? '',
      accountNumber: map['account_number'] ?? '',
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      createdAt: DateTime.parse(
          map['\$createdAt'] ?? DateTime.now().toIso8601String()),
      adminNote: map['admin_note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'owner_id': communityOwnerId,
      'requested_coins': requestedCoins,
      'equivalent_pkr': equivalentPKR,
      'payment_method': paymentMethod.name,
      'account_title': accountTitle,
      'account_number': accountNumber,
      'status': status.name,
      'admin_note': adminNote,
    };
  }
}
