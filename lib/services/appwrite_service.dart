// lib/services/appwrite_service.dart
import 'package:appwrite/appwrite.dart';

/// Shared Appwrite service for both main app and admin panel
/// This service manages connections to Appwrite backend
class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();

  late Client _client;
  late Account _account;
  late Databases _databases;
  late Storage _storage;
  late Functions _functions;
  late Messaging _messaging;

  // TODO: Replace with your actual Appwrite project details
  static const String endpoint =
      'https://cloud.appwrite.io/v1'; // Your Appwrite endpoint
  static const String projectId = 'YOUR_PROJECT_ID'; // Your Project ID
  static const String databaseId = 'YOUR_DATABASE_ID'; // Your Database ID

  // Collection IDs - Update these with your actual collection IDs
  static const String usersCollectionId = 'users';
  static const String communitiesCollectionId = 'communities';
  static const String plantsCollectionId = 'plants';
  static const String qrCodesCollectionId = 'qr_codes';
  static const String transactionsCollectionId = 'transactions';
  static const String notificationsCollectionId = 'notifications';

  /// Initialize Appwrite client
  void initialize() {
    _client = Client()
        .setEndpoint(endpoint)
        .setProject(projectId)
        .setSelfSigned(
            status: true); // Only for development with self-signed certificates

    _account = Account(_client);
    _databases = Databases(_client);
    _storage = Storage(_client);
    _functions = Functions(_client);
    _messaging = Messaging(_client);
  }

  // Getters for Appwrite services
  Client get client => _client;
  Account get account => _account;
  Databases get databases => _databases;
  Storage get storage => _storage;
  Functions get functions => _functions;
  Messaging get messaging => _messaging;

  // === Authentication Methods ===

  /// Sign in with email and password
  Future<dynamic> signIn(String email, String password) async {
    try {
      final session = await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return session;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign up new user
  Future<dynamic> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user session
  Future<dynamic> getCurrentUser() async {
    try {
      return await _account.get();
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (e) {
      rethrow;
    }
  }

  // === Database Methods ===

  /// Get documents from a collection
  Future<dynamic> getDocuments({
    required String collectionId,
    List<String>? queries,
  }) async {
    try {
      return await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: queries ?? [],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get single document
  Future<dynamic> getDocument({
    required String collectionId,
    required String documentId,
  }) async {
    try {
      return await _databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Create document
  Future<dynamic> createDocument({
    required String collectionId,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      return await _databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId ?? ID.unique(),
        data: data,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update document
  Future<dynamic> updateDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: data,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete document
  Future<void> deleteDocument({
    required String collectionId,
    required String documentId,
  }) async {
    try {
      await _databases.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // === Storage Methods ===

  /// Upload file to storage
  Future<dynamic> uploadFile({
    required String bucketId,
    required String filePath,
    required String fileId,
  }) async {
    try {
      return await _storage.createFile(
        bucketId: bucketId,
        fileId: fileId,
        file: InputFile.fromPath(path: filePath),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get file preview URL
  String getFilePreview({
    required String bucketId,
    required String fileId,
    int? width,
    int? height,
  }) {
    return '$endpoint/storage/buckets/$bucketId/files/$fileId/preview?project=$projectId'
        '${width != null ? '&width=$width' : ''}'
        '${height != null ? '&height=$height' : ''}';
  }

  /// Delete file
  Future<void> deleteFile({
    required String bucketId,
    required String fileId,
  }) async {
    try {
      await _storage.deleteFile(
        bucketId: bucketId,
        fileId: fileId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // === Functions Methods ===

  /// Execute Appwrite function
  Future<dynamic> executeFunction({
    required String functionId,
    String? body,
    bool? async,
  }) async {
    try {
      return await _functions.createExecution(
        functionId: functionId,
        body: body,
        xasync: async ?? false,
      );
    } catch (e) {
      rethrow;
    }
  }

  // === Admin-specific Methods ===

  /// Check if current user has admin role
  Future<bool> isAdmin() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;

      // TODO: Implement your admin role check logic
      // Option 1: Check user labels
      final labels = user.labels as List<dynamic>? ?? [];
      if (labels.contains('admin')) return true;

      // Option 2: Check in custom user document
      // final userDoc = await getDocument(
      //   collectionId: usersCollectionId,
      //   documentId: user.$id,
      // );
      // return userDoc.data['isAdmin'] == true;

      return false;
    } catch (e) {
      return false;
    }
  }

  // === Analytics Methods (for Admin Panel) ===

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final users = await getDocuments(collectionId: usersCollectionId);
      final totalUsers = users.total ?? 0;

      // Calculate active users (logged in last 7 days)
      // final activeUsers = users.documents.where((doc) {
      //   final lastLogin = DateTime.parse(doc.data['lastLogin'] ?? '');
      //   return DateTime.now().difference(lastLogin).inDays <= 7;
      // }).length;

      return {
        'totalUsers': totalUsers,
        'activeUsers': 0, // Implement based on your schema
        'newToday': 0, // Implement based on your schema
        'avgPlantsPerUser': 0, // Implement based on your schema
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'newToday': 0,
        'avgPlantsPerUser': 0,
      };
    }
  }

  /// Get community statistics
  Future<Map<String, dynamic>> getCommunityStats() async {
    try {
      final communities =
          await getDocuments(collectionId: communitiesCollectionId);
      return {
        'totalCommunities': communities.total ?? 0,
        'totalMembers': 0, // Calculate from your data
        'avgMembersPerCommunity': 0,
      };
    } catch (e) {
      return {
        'totalCommunities': 0,
        'totalMembers': 0,
        'avgMembersPerCommunity': 0,
      };
    }
  }

  /// Get QR code statistics
  Future<Map<String, dynamic>> getQRStats() async {
    try {
      final qrCodes = await getDocuments(collectionId: qrCodesCollectionId);
      return {
        'totalGenerated': qrCodes.total ?? 0,
        'scanned': 0, // Implement based on your schema
        'unused': 0,
      };
    } catch (e) {
      return {
        'totalGenerated': 0,
        'scanned': 0,
        'unused': 0,
      };
    }
  }

  /// Get coin/transaction statistics
  Future<Map<String, dynamic>> getCoinStats() async {
    try {
      final transactions =
          await getDocuments(collectionId: transactionsCollectionId);
      return {
        'totalTransactions': transactions.total ?? 0,
        'totalCoinsDistributed': 0, // Calculate from transactions
        'avgCoinsPerUser': 0,
      };
    } catch (e) {
      return {
        'totalTransactions': 0,
        'totalCoinsDistributed': 0,
        'avgCoinsPerUser': 0,
      };
    }
  }
}
