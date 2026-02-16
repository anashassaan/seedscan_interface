// lib/models/transaction_model.dart

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final int amount;
  final String description;
  final DateTime timestamp;
  final String? metadata; // JSON string for additional data

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TransactionType.earn,
      ),
      amount: json['amount'] ?? 0,
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ??
          json['\$createdAt'] ??
          DateTime.now().toIso8601String()),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

enum TransactionType {
  earn,
  spend,
  bonus,
  penalty,
}
