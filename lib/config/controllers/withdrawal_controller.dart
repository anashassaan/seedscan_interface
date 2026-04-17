import 'package:flutter/foundation.dart';
import '../../models/withdrawal_model.dart';
import '../../services/withdrawal_service.dart';
import '../../services/garden_cache_service.dart';

class WithdrawalController extends ChangeNotifier {
  final WithdrawalService _withdrawalService = WithdrawalService();

  List<WithdrawalModel> _withdrawalHistory = [];
  List<WithdrawalModel> _pendingRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<WithdrawalModel> get withdrawalHistory => _withdrawalHistory;
  List<WithdrawalModel> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constants
  static const int MIN_WITHDRAWAL_COINS = 5000;
  static const double COINS_TO_PKR_RATIO = 10.0;

  /// Calculate PKR from coins (10 coins = 1 PKR)
  double coinsToRupees(int coins) {
    return coins / COINS_TO_PKR_RATIO;
  }

  /// Check if user can withdraw
  bool canWithdraw(int currentCoins) {
    return currentCoins >= MIN_WITHDRAWAL_COINS;
  }

  /// User requests withdrawal
  Future<bool> requestWithdrawal(
    int coinsToWithdraw,
    String paymentMethod,
    String accountTitle,
    String accountNumber,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate
      if (coinsToWithdraw < MIN_WITHDRAWAL_COINS) {
        throw Exception('Minimum $MIN_WITHDRAWAL_COINS coins required');
      }

      if (accountNumber.isEmpty || accountTitle.isEmpty) {
        throw Exception('Please provide account details');
      }

      // Call service
      final success = await _withdrawalService.requestWithdraw(
        coinsToWithdraw,
        paymentMethod,
        accountTitle,
        accountNumber,
      );

      if (success) {
        _errorMessage = null;
      } else {
        _errorMessage = 'Withdrawal request failed. Please try again.';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Admin fetches pending requests: cache-first → background sync
  Future<void> fetchPendingRequests(String adminId) async {
    // STEP 1: LOAD FROM CACHE (instant)
    _loadPendingRequestsFromCache(adminId);

    // STEP 2: SYNC FROM APPWRITE (background, non-blocking)
    await _syncPendingRequestsFromAppwrite(adminId);
  }

  /// Load pending requests from Hive cache instantly
  void _loadPendingRequestsFromCache(String adminId) {
    try {
      final cached = GardenCacheService.getCachedWithdrawalData(adminId);
      if (cached != null) {
        final pendingList = cached['pending_requests'] as List? ?? [];
        _pendingRequests = pendingList.whereType<Map>().map((data) {
          return WithdrawalModel.fromMap(
              Map<String, dynamic>.from(data));
        }).toList();
        debugPrint(
            '[WithdrawalController] Loaded ${_pendingRequests.length} pending requests from cache');
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
          '[WithdrawalController] _loadPendingRequestsFromCache error: $e');
    }
  }

  /// Sync pending requests from Appwrite in background
  Future<void> _syncPendingRequestsFromAppwrite(String adminId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _pendingRequests = await _withdrawalService.getPendingRequests(adminId);
      _errorMessage = null;

      // Cache the fetched data
      final withdrawalData = <String, dynamic>{
        'pending_requests': _pendingRequests.map((r) => r.toMap()).toList(),
        'withdrawal_history': _withdrawalHistory.map((r) => r.toMap()).toList(),
      };
      await GardenCacheService.cacheWithdrawalData(adminId, withdrawalData);
      debugPrint(
          '[WithdrawalController] Synced ${_pendingRequests.length} pending requests from Appwrite');
    } catch (e) {
      debugPrint(
          '[WithdrawalController] Appwrite sync failed for pending requests (using cached data): $e');
      _errorMessage = 'Failed to fetch requests';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Admin reviews withdrawal request
  Future<bool> reviewWithdrawal(
    String requestId,
    bool isApproved,
    String? note,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _withdrawalService.reviewWithdrawal(
        requestId,
        isApproved,
        note,
      );

      if (success) {
        // Remove from pending list if approved/rejected
        _pendingRequests.removeWhere((r) => r.id == requestId);
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to process review';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch user's withdrawal history: cache-first → background sync
  Future<void> fetchUserWithdrawalHistory(String userId) async {
    // STEP 1: LOAD FROM CACHE (instant)
    _loadWithdrawalHistoryFromCache(userId);

    // STEP 2: SYNC FROM APPWRITE (background, non-blocking)
    await _syncWithdrawalHistoryFromAppwrite(userId);
  }

  /// Load withdrawal history from Hive cache instantly
  void _loadWithdrawalHistoryFromCache(String userId) {
    try {
      final cached = GardenCacheService.getCachedWithdrawalData(userId);
      if (cached != null) {
        final historyList = cached['withdrawal_history'] as List? ?? [];
        _withdrawalHistory = historyList.whereType<Map>().map((data) {
          return WithdrawalModel.fromMap(
              Map<String, dynamic>.from(data));
        }).toList();
        debugPrint(
            '[WithdrawalController] Loaded ${_withdrawalHistory.length} withdrawal records from cache');
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
          '[WithdrawalController] _loadWithdrawalHistoryFromCache error: $e');
    }
  }

  /// Sync withdrawal history from Appwrite in background
  Future<void> _syncWithdrawalHistoryFromAppwrite(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch withdrawal history from service if implemented
      // For now, this would need to be added to WithdrawalService
      _errorMessage = null;

      // Cache the fetched data
      final withdrawalData = <String, dynamic>{
        'pending_requests': _pendingRequests.map((r) => r.toMap()).toList(),
        'withdrawal_history': _withdrawalHistory.map((r) => r.toMap()).toList(),
      };
      await GardenCacheService.cacheWithdrawalData(userId, withdrawalData);
      debugPrint(
          '[WithdrawalController] Synced ${_withdrawalHistory.length} withdrawal records from Appwrite');
    } catch (e) {
      debugPrint(
          '[WithdrawalController] Appwrite sync failed for history (using cached data): $e');
      _errorMessage = 'Failed to fetch history';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear errors
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _withdrawalHistory = [];
    _pendingRequests = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
