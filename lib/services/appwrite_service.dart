// lib/services/appwrite_service.dart
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../config/appwrite_constants.dart';

/// Shared Appwrite service for both main app and admin panel.
/// Uses constants from [AppwriteConstants] for all IDs.
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
  bool _initialized = false;

  // ── Convenience aliases (backward-compat) ─────────────────────────────────
  static const String endpoint = AppwriteConstants.endpoint;
  static const String projectId = AppwriteConstants.projectId;
  static const String databaseId = AppwriteConstants.databaseId;

  // Collection IDs – all 12 collections from the design doc
  static const String usersCollectionId = AppwriteConstants.usersCollection;
  static const String plantsCollectionId = AppwriteConstants.plantsCollection;
  static const String drivesCollectionId = AppwriteConstants.drivesCollection;
  static const String activityLogsCollectionId =
      AppwriteConstants.activityLogsCollection;
  static const String rewardsCollectionId = AppwriteConstants.rewardsCollection;
  static const String communitiesCollectionId =
      AppwriteConstants.communitiesCollection;
  static const String communityMembersCollectionId =
      AppwriteConstants.communityMembersCollection;
  static const String communityPostsCollectionId =
      AppwriteConstants.communityPostsCollection;
  static const String communityCommentsCollectionId =
      AppwriteConstants.communityCommentsCollection;
  static const String communityLikesCollectionId =
      AppwriteConstants.communityLikesCollection;
  static const String notificationsCollectionId =
      AppwriteConstants.notificationsCollection;
  static const String userFcmTokensCollectionId =
      AppwriteConstants.userFcmTokensCollection;
  static const String adminQrCodesCollectionId =
      AppwriteConstants.adminQrCodesCollection;
  static const String systemLogsCollectionId =
      AppwriteConstants.systemLogsCollection;

  // Storage bucket IDs
  static const String plantImagesBucket = AppwriteConstants.plantImagesBucket;
  static const String communityMediaBucket =
      AppwriteConstants.communityMediaBucket;

  // Cloud function IDs
  static const String verifyActionFunctionId =
      AppwriteConstants.verifyActionFunctionId;
  static const String joinCommunityFunctionId =
      AppwriteConstants.joinCommunityFunctionId;
  static const String sendNotificationFunctionId =
      AppwriteConstants.sendNotificationFunctionId;

  /// Initialize Appwrite client – safe to call multiple times.
  void initialize() {
    if (_initialized) return;

    _client = Client()
        .setEndpoint(endpoint)
        .setProject(projectId)
        .setSelfSigned(status: true); // dev only

    _account = Account(_client);
    _databases = Databases(_client);
    _storage = Storage(_client);
    _functions = Functions(_client);
    _messaging = Messaging(_client);
    _initialized = true;
  }

  // Getters for Appwrite services
  Client get client => _client;
  Account get account => _account;
  Databases get databases => _databases;
  Storage get storage => _storage;
  Functions get functions => _functions;
  Messaging get messaging => _messaging;
  bool get isInitialized => _initialized;

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

  /// Sign up new user (Appwrite Auth)
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

  /// Create a user profile document in the `users` collection.
  /// Uses the Auth user's `$id` as the document ID so they match.
  Future<dynamic> createUserDocument({
    required String userId,
    required String name,
    required String username,
    required String email,
    String role = 'user',
    String? communityName,
    String? organization,
    String? adminReason,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'username': username,
        'email': email,
        'role': role,
        'wallet_balance': 0,
        'current_streak': 0,
        'joined_drives': [],
        'created_at': DateTime.now().toIso8601String(),
        // Appwrite requires these fields for all users due to collection schema
        'organization': organization ?? 'N/A',
        'admin_reason': adminReason ?? 'N/A',
      };

      // Add admin-specific fields if registering as admin
      if (role == 'admin') {
        if (communityName != null && communityName.isNotEmpty) {
          data['community_name'] = communityName;
        }
        if (organization != null && organization.isNotEmpty) {
          data['organization'] = organization;
        }
        if (adminReason != null && adminReason.isNotEmpty) {
          data['admin_reason'] = adminReason;
        }
      }

      return await _databases.createDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
        data: data,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch the user profile document from the `users` collection.
  Future<dynamic> getUserDocument(String userId) async {
    try {
      return await _databases.getDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Look up a user document by username.
  /// Returns the document if found, null otherwise.
  Future<dynamic> getUserByUsername(String username) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        queries: [
          Query.equal('username', username),
          Query.limit(1),
        ],
      );
      if (result.documents.isNotEmpty) {
        return result.documents.first;
      }
      return null;
    } catch (e) {
      return null;
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
    List<String>? permissions,
  }) async {
    try {
      return await _databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId ?? ID.unique(),
        data: data,
        permissions: permissions,
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
    List<String>? permissions,
  }) async {
    try {
      return await _storage.createFile(
        bucketId: bucketId,
        fileId: fileId,
        file: InputFile.fromPath(path: filePath),
        permissions: permissions,
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
      if (user == null) {
        debugPrint('[APPWRITE] isAdmin: no current user');
        return false;
      }

      // Check 1: Appwrite Auth labels
      final labels = user.labels as List<dynamic>? ?? [];
      debugPrint('[APPWRITE] isAdmin: labels=$labels');
      if (labels.contains('admin')) return true;

      // Check 2: 'role' field in user document (users collection)
      try {
        final userDoc = await _databases.getDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: user.$id,
        );
        debugPrint('[APPWRITE] isAdmin: doc role=${userDoc.data['role']}');
        if (userDoc.data['role'] == 'admin') return true;
      } catch (e) {
        debugPrint('[APPWRITE] isAdmin: failed to read user doc: $e');
      }

      return false;
    } catch (e) {
      debugPrint('[APPWRITE] isAdmin: outer error: $e');
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

  /// Get drive statistics
  Future<Map<String, dynamic>> getDriveStats() async {
    try {
      final drives = await getDocuments(collectionId: drivesCollectionId);
      return {
        'totalDrives': drives.total ?? 0,
        'activeDrives': 0,
        'completedDrives': 0,
      };
    } catch (e) {
      return {
        'totalDrives': 0,
        'activeDrives': 0,
        'completedDrives': 0,
      };
    }
  }

  /// Get activity log / coin statistics
  Future<Map<String, dynamic>> getCoinStats() async {
    try {
      final logs = await getDocuments(collectionId: activityLogsCollectionId);
      return {
        'totalActivities': logs.total ?? 0,
        'totalCoinsDistributed': 0, // Sum from activity_logs.coins_awarded
        'avgCoinsPerUser': 0,
      };
    } catch (e) {
      return {
        'totalActivities': 0,
        'totalCoinsDistributed': 0,
        'avgCoinsPerUser': 0,
      };
    }
  }

  /// Get reward catalog statistics
  Future<Map<String, dynamic>> getRewardStats() async {
    try {
      final rewards = await getDocuments(collectionId: rewardsCollectionId);
      return {
        'totalRewards': rewards.total ?? 0,
      };
    } catch (e) {
      return {'totalRewards': 0};
    }
  }
}
