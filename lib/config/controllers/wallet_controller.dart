// lib/controllers/wallet_controller.dart
import 'package:flutter/material.dart';

class WalletController extends ChangeNotifier {
  int _points = 1250;
  final List<Transaction> _transactions = [];

  int get points => _points;
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  WalletController() {
    // Initialize with some sample transactions
    _transactions.addAll([
      Transaction(
        id: 't1',
        type: TransactionType.earn,
        amount: 50,
        description: 'Watered Golden Pothos',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Transaction(
        id: 't2',
        type: TransactionType.earn,
        amount: 100,
        description: 'Completed Disease Scan',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Transaction(
        id: 't3',
        type: TransactionType.earn,
        amount: 25,
        description: 'Daily Login Bonus',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: 't4',
        type: TransactionType.spend,
        amount: 200,
        description: 'Redeemed Gift Card',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Transaction(
        id: 't5',
        type: TransactionType.earn,
        amount: 75,
        description: 'Fertilized Mango Tree',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);
  }

  // Earn points for completing tasks
  void earnPoints(int amount, String description) {
    _points += amount;
    _transactions.insert(
      0,
      Transaction(
        id: 't${DateTime.now().millisecondsSinceEpoch}',
        type: TransactionType.earn,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // Spend/withdraw points
  bool spendPoints(int amount, String description) {
    if (_points < amount) {
      return false; // Insufficient balance
    }
    _points -= amount;
    _transactions.insert(
      0,
      Transaction(
        id: 't${DateTime.now().millisecondsSinceEpoch}',
        type: TransactionType.spend,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  // Get transactions by type
  List<Transaction> getTransactionsByType(TransactionType type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  // Get total earned
  int get totalEarned {
    return _transactions
        .where((t) => t.type == TransactionType.earn)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Get total spent
  int get totalSpent {
    return _transactions
        .where((t) => t.type == TransactionType.spend)
        .fold(0, (sum, t) => sum + t.amount);
  }
}

// Transaction Model
class Transaction {
  final String id;
  final TransactionType type;
  final int amount;
  final String description;
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
  });
}

// Transaction Types
enum TransactionType {
  earn,
  spend,
}
