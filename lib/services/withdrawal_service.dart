import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import '../config/appwrite_constants.dart';
import '../models/withdrawal_model.dart';
import 'appwrite_service.dart';

class WithdrawalService {
  final Functions _functions;
  final Databases _databases;

  WithdrawalService()
      : _functions = AppwriteService().functions,
        _databases = AppwriteService().databases;

  /// User requests a withdrawal via Appwrite Cloud Function
  /// Fallback: If function is missing (404), create document directly
  Future<bool> requestWithdraw(
    String userId,
    int coinsToWithdraw,
    String paymentMethod,
    String accountTitle,
    String accountNo,
  ) async {
    if (coinsToWithdraw < 5000) {
      throw Exception('Minimum 5000 coins required');
    }

    final bodyMap = {
      "requested_coins": coinsToWithdraw,
      "payment_method": paymentMethod,
      "account_title": accountTitle,
      "account_number": accountNo,
      "user_id": userId, // Include userId for manual fallback
    };

    try {
      final execution = await _functions.createExecution(
        functionId: AppwriteConstants.requestWithdrawalFunctionId,
        body: jsonEncode(bodyMap),
      );

      if (execution.status == 'completed') {
        return true;
      } else {
        final errorMsg = execution.responseBody.isNotEmpty
            ? execution.responseBody
            : 'Status: ${execution.status}';
        throw Exception('Withdrawal failed: $errorMsg');
      }
    } on AppwriteException catch (ae) {
      // FALLBACK: If function is not found (404), create document directly
      if (ae.code == 404) {
        print(
            '[WithdrawalService] Function not found (404), falling back to manual document creation');
        try {
          await _databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.withdrawalsCollection,
            documentId: ID.unique(),
            data: {
              'user_id': userId,
              'requested_coins': coinsToWithdraw,
              'equivalent_pkr': coinsToWithdraw / 10,
              'payment_method': paymentMethod,
              'account_title': accountTitle,
              'account_number': accountNo,
              'status': 'pending',
              'created_at': DateTime.now().toIso8601String(),
            },
          );
          return true;
        } catch (e) {
          throw Exception('Manual withdrawal failed: $e');
        }
      }
      rethrow;
    }
  }

  /// Admin fetches pending withdrawal requests
  Future<List<WithdrawalModel>> getPendingRequests(String adminId) async {
    try {
      final res = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.withdrawalsCollection,
        queries: [
          Query.equal('status', 'pending'),
          Query.orderDesc('created_at'),
        ],
      );
      return res.documents.map((d) => WithdrawalModel.fromMap(d.data)).toList();
    } catch (e) {
      print('Error fetching pending withdrawals: \$e');
      return [];
    }
  }

  /// Admin reviews (approves/rejects) a request
  Future<bool> reviewWithdrawal(
      String requestId, bool isApproved, String? note) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.withdrawalsCollection,
        documentId: requestId,
        data: {
          'status': isApproved ? 'approved' : 'rejected',
          'admin_note': note ?? '',
        },
      );
      return true;
    } catch (e) {
      print('Error reviewing withdrawal: \$e');
      return false;
    }
  }

  /// Fetch user's withdrawal history
  Future<List<WithdrawalModel>> getUserWithdrawalHistory(String userId) async {
    try {
      final res = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.withdrawalsCollection,
        queries: [
          Query.equal('user_id', userId),
        ],
      );
      return res.documents.map((d) => WithdrawalModel.fromMap(d.data)).toList();
    } catch (e) {
      print('Error fetching user withdrawal history: \$e');
      return [];
    }
  }
}
