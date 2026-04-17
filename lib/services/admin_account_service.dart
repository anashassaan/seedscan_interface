import 'package:appwrite/appwrite.dart';
import '../config/appwrite_constants.dart';
import '../models/admin_account_model.dart';
import 'appwrite_service.dart';

class AdminAccountService {
  final Databases _databases;

  AdminAccountService() : _databases = AppwriteService().databases;

  /// Add new admin payment account (JazzCash/EasyPaisa)
  Future<AdminAccountModel?> addAdminAccount(
    String adminId,
    String accountTitle,
    String accountNumber,
    String paymentMethod,
  ) async {
    try {
      // Validate input
      if (accountTitle.isEmpty || accountNumber.isEmpty) {
        throw Exception('Account title and number are required');
      }

      if (!['jazzcash', 'easypaisa'].contains(paymentMethod)) {
        throw Exception('Invalid payment method');
      }

      final doc = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'admin_accounts',
        documentId: 'unique()',
        data: {
          'admin_id': adminId,
          'account_title': accountTitle,
          'account_number': accountNumber,
          'payment_method': paymentMethod,
          'is_verified': false,
          'is_primary': false,
        },
      );

      return AdminAccountModel.fromMap(doc.data);
    } catch (e) {
      print('Error adding admin account: $e');
      return null;
    }
  }

  /// Get all admin payment accounts
  Future<List<AdminAccountModel>> getAdminAccounts(String adminId) async {
    try {
      final res = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'admin_accounts',
        queries: [
          Query.equal('admin_id', adminId),
        ],
      );

      return res.documents
          .map((d) => AdminAccountModel.fromMap(d.data))
          .toList();
    } catch (e) {
      print('Error fetching admin accounts: $e');
      return [];
    }
  }

  /// Get primary admin account
  Future<AdminAccountModel?> getPrimaryAccount(String adminId) async {
    try {
      final res = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'admin_accounts',
        queries: [
          Query.equal('admin_id', adminId),
          Query.equal('is_primary', true),
        ],
      );

      if (res.documents.isNotEmpty) {
        return AdminAccountModel.fromMap(res.documents.first.data);
      }
      return null;
    } catch (e) {
      print('Error fetching primary account: $e');
      return null;
    }
  }

  /// Set a specific account as primary (only one per admin)
  Future<bool> setPrimaryAccount(
    String adminAccountId,
    String adminId,
  ) async {
    try {
      // Fetch all accounts for this admin
      final accounts = await getAdminAccounts(adminId);

      // Set all others to non-primary
      for (var acc in accounts) {
        if (acc.id != adminAccountId) {
          await _databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: 'admin_accounts',
            documentId: acc.id,
            data: {'is_primary': false},
          );
        }
      }

      // Set this one as primary
      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'admin_accounts',
        documentId: adminAccountId,
        data: {'is_primary': true},
      );

      return true;
    } catch (e) {
      print('Error setting primary account: $e');
      return false;
    }
  }

  /// Update admin account details
  Future<bool> updateAdminAccount(
    String accountId,
    String accountTitle,
    String accountNumber,
  ) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'admin_accounts',
        documentId: accountId,
        data: {
          'account_title': accountTitle,
          'account_number': accountNumber,
        },
      );
      return true;
    } catch (e) {
      print('Error updating admin account: $e');
      return false;
    }
  }

  /// Delete admin account
  Future<bool> deleteAdminAccount(String accountId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'admin_accounts',
        documentId: accountId,
      );
      return true;
    } catch (e) {
      print('Error deleting admin account: $e');
      return false;
    }
  }

  /// Verify admin account (optional - for manual verification)
  Future<bool> verifyAdminAccount(String accountId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'admin_accounts',
        documentId: accountId,
        data: {
          'is_verified': true,
          'verified_at': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      print('Error verifying admin account: $e');
      return false;
    }
  }
}
