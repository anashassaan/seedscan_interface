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
  Future<bool> requestWithdraw(
    int coinsToWithdraw,
    String paymentMethod,
    String accountTitle,
    String accountNo,
  ) async {
    try {
      if (coinsToWithdraw < 5000) {
        throw Exception('Minimum 5000 coins required');
      }

      final execution = await _functions.createExecution(
        functionId: AppwriteConstants.requestWithdrawalFunctionId,
        body: '''
        {
          "requested_coins": $coinsToWithdraw,
          "payment_method": "$paymentMethod",
          "account_title": "$accountTitle",
          "account_number": "$accountNo"
        }
        ''',
      );

      if (execution.status == 'completed') {
        return true;
      } else {
        throw Exception('Withdrawal failed: \${execution.responseBody}');
      }
    } catch (e) {
      print('Withdrawal Error: \$e');
      return false;
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
          // Assuming owner_id ties to community admin
          Query.equal('owner_id', adminId),
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
