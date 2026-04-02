// lib/controllers/wallet_controller.dart
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/transaction_model.dart' as tm;

class WalletController extends ChangeNotifier {
  int _points = 0;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _userId;

  final DatabaseService _db = DatabaseService();

  int get points => _points;
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;

  WalletController();

  Future<void> fetchWalletData(String userId) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch user profile for balance
      final profile = await _db.getUserProfile(userId);
      if (profile != null) {
        _points = profile.walletBalance;
      }

      // Fetch activity logs
      final logs = await _db.listUserActivityLogs(userId);
      _transactions = logs.map((log) {
        final amount = log.coinsAwarded.abs();
        // Assuming action rules. Adjust if necessary:
        final isSpend = log.actionType.toLowerCase().contains('redeem') ||
            log.coinsAwarded < 0 ||
            log.actionType.toLowerCase().contains('spend');
        return Transaction(
          id: log.id,
          type: isSpend ? TransactionType.spend : TransactionType.earn,
          amount: amount,
          description: _formatActionType(log.actionType),
          timestamp: log.createdAt,
        );
      }).toList();

      // Sort by newest first
      _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Error fetching wallet data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatActionType(String type) {
    if (type.isEmpty) return 'Activity';
    if (type == 'scan_disease') return 'Completed Disease Scan';
    return type
        .split('_')
        .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Earn points for completing tasks
  Future<void> earnPoints(int amount, String description,
      {String actionType = 'task_completed', String plantId = 'system'}) async {
    if (_userId == null) return;

    // Update locally immediately for responsiveness
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

    try {
      // 1. Log activity
      await _db.createActivityLog(
        userId: _userId!,
        plantId: plantId,
        actionType: actionType,
        coinsAwarded: amount,
        verificationStatus: 'verified',
        proofImageId: 'none',
      );
      // 2. Update user profile
      await _db.updateUserProfile(_userId!, {
        'wallet_balance': _points,
      });
    } catch (e) {
      debugPrint('Error persisting earn points: $e');
    }
  }

  // Spend/withdraw points
  Future<bool> spendPoints(int amount, String description) async {
    if (_userId == null || _points < amount) {
      return false; // Insufficient balance or not initialized
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

    try {
      // 1. Log activity
      await _db.createActivityLog(
        userId: _userId!,
        plantId: 'system',
        actionType: 'redeemed_points',
        coinsAwarded: -amount,
        verificationStatus: 'verified',
        proofImageId: 'none',
      );
      // 2. Update user profile
      await _db.updateUserProfile(_userId!, {
        'wallet_balance': _points,
      });
    } catch (e) {
      debugPrint('Error persisting spend points: $e');
    }

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
