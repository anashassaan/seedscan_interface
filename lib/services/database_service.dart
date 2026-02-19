// lib/services/database_service.dart
import 'package:appwrite/appwrite.dart';
import '../config/appwrite_constants.dart';
import '../models/user_model.dart';
import '../models/plant_model.dart';
import '../models/community_model.dart';
import '../models/transaction_model.dart'; // ActivityLog
import '../models/qr_code_model.dart'; // DriveModel, RewardModel, UserFcmToken
import '../models/notification_model.dart';
import 'appwrite_service.dart';

/// High-level, typed database helper that sits on top of [AppwriteService].
/// Every public method returns Dart model objects instead of raw JSON.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final AppwriteService _appwrite = AppwriteService();

  // ---------------------------------------------------------------------------
  // USERS
  // ---------------------------------------------------------------------------

  /// Create a user profile document (call after Appwrite Auth sign-up).
  Future<UserModel> createUserProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.usersCollection,
      documentId: userId,
      data: {
        'name': name,
        'email': email,
        'wallet_balance': 0,
        'current_streak': 0,
        'joined_drives': <String>[],
        'created_at': DateTime.now().toIso8601String(),
      },
    );
    return UserModel.fromJson(doc.data);
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _appwrite.getDocument(
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
      );
      return UserModel.fromJson(doc.data);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    final doc = await _appwrite.updateDocument(
      collectionId: AppwriteConstants.usersCollection,
      documentId: userId,
      data: data,
    );
    return UserModel.fromJson(doc.data);
  }

  Future<List<UserModel>> listUsers({List<String>? queries}) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.usersCollection,
      queries: queries,
    );
    return (res.documents as List)
        .map((d) => UserModel.fromJson(d.data))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // PLANTS
  // ---------------------------------------------------------------------------

  Future<PlantModel> createPlant({
    required String species,
    required String guardianId,
    required double lat,
    required double lng,
    required String imageUrl,
    String? driveId,
    String? nickname,
    String? plantId,
  }) async {
    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.plantsCollection,
      documentId: plantId, // null → auto-generated
      data: {
        'species': species,
        'guardian_id': guardianId,
        'drive_id': driveId,
        'nickname': nickname,
        'location_lat': lat,
        'location_long': lng,
        'health_status': 'healthy',
        'image_url': imageUrl,
        'last_watered': null,
        'pHash_history': <String>[],
      },
    );
    return PlantModel.fromJson(doc.data);
  }

  Future<PlantModel?> getPlant(String plantId) async {
    try {
      final doc = await _appwrite.getDocument(
        collectionId: AppwriteConstants.plantsCollection,
        documentId: plantId,
      );
      return PlantModel.fromJson(doc.data);
    } catch (_) {
      return null;
    }
  }

  Future<List<PlantModel>> listPlants({List<String>? queries}) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.plantsCollection,
      queries: queries,
    );
    return (res.documents as List)
        .map((d) => PlantModel.fromJson(d.data))
        .toList();
  }

  /// List plants belonging to a specific guardian (user).
  Future<List<PlantModel>> listMyPlants(String userId) async {
    return listPlants(queries: [
      Query.equal('guardian_id', userId),
    ]);
  }

  Future<PlantModel> updatePlant(
      String plantId, Map<String, dynamic> data) async {
    final doc = await _appwrite.updateDocument(
      collectionId: AppwriteConstants.plantsCollection,
      documentId: plantId,
      data: data,
    );
    return PlantModel.fromJson(doc.data);
  }

  // ---------------------------------------------------------------------------
  // DRIVES
  // ---------------------------------------------------------------------------

  Future<DriveModel> createDrive({
    required String title,
    required String orgName,
    required int targetCount,
    required DateTime startDate,
  }) async {
    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.drivesCollection,
      data: {
        'title': title,
        'org_name': orgName,
        'status': 'active',
        'target_count': targetCount,
        'alive_count': 0,
        'start_date': startDate.toIso8601String(),
      },
    );
    return DriveModel.fromJson(doc.data);
  }

  Future<List<DriveModel>> listDrives({List<String>? queries}) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.drivesCollection,
      queries: queries,
    );
    return (res.documents as List)
        .map((d) => DriveModel.fromJson(d.data))
        .toList();
  }

  Future<DriveModel?> getDrive(String driveId) async {
    try {
      final doc = await _appwrite.getDocument(
        collectionId: AppwriteConstants.drivesCollection,
        documentId: driveId,
      );
      return DriveModel.fromJson(doc.data);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIVITY LOGS
  // ---------------------------------------------------------------------------

  Future<ActivityLog> createActivityLog({
    required String userId,
    required String plantId,
    required String actionType,
    required int coinsAwarded,
    required String verificationStatus,
    required String proofImageId,
    String? rejectionReason,
  }) async {
    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.activityLogsCollection,
      data: {
        'user_id': userId,
        'plant_id': plantId,
        'action_type': actionType,
        'coins_awarded': coinsAwarded,
        'verification_status': verificationStatus,
        'proof_image_id': proofImageId,
        'rejection_reason': rejectionReason,
      },
    );
    return ActivityLog.fromJson(doc.data);
  }

  Future<List<ActivityLog>> listActivityLogs({List<String>? queries}) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.activityLogsCollection,
      queries: queries,
    );
    return (res.documents as List)
        .map((d) => ActivityLog.fromJson(d.data))
        .toList();
  }

  /// Logs for a specific user.
  Future<List<ActivityLog>> listUserActivityLogs(String userId) async {
    return listActivityLogs(queries: [
      Query.equal('user_id', userId),
    ]);
  }

  // ---------------------------------------------------------------------------
  // REWARDS
  // ---------------------------------------------------------------------------

  Future<List<RewardModel>> listRewards({List<String>? queries}) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.rewardsCollection,
      queries: queries,
    );
    return (res.documents as List)
        .map((d) => RewardModel.fromJson(d.data))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // COMMUNITIES
  // ---------------------------------------------------------------------------

  Future<Community> createCommunity({
    required String name,
    required String creatorId,
    required String qrCodeUrl,
    required String inviteCode,
    String? description,
    String? coverImageId,
  }) async {
    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.communitiesCollection,
      data: {
        'name': name,
        'description': description,
        'creator_id': creatorId,
        'cover_image_id': coverImageId,
        'qr_code_url': qrCodeUrl,
        'invite_code': inviteCode,
        'member_count': 1,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
    return Community.fromJson(doc.data);
  }

  Future<List<Community>> listCommunities({List<String>? queries}) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.communitiesCollection,
      queries: queries,
    );
    return (res.documents as List)
        .map((d) => Community.fromJson(d.data))
        .toList();
  }

  Future<Community?> getCommunity(String communityId) async {
    try {
      final doc = await _appwrite.getDocument(
        collectionId: AppwriteConstants.communitiesCollection,
        documentId: communityId,
      );
      return Community.fromJson(doc.data);
    } catch (_) {
      return null;
    }
  }

  /// Look up community by its unique invite code.
  Future<Community?> getCommunityByInviteCode(String inviteCode) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.communitiesCollection,
      queries: [Query.equal('invite_code', inviteCode), Query.limit(1)],
    );
    final docs = res.documents as List;
    if (docs.isEmpty) return null;
    return Community.fromJson(docs.first.data);
  }

  // ---------------------------------------------------------------------------
  // COMMUNITY MEMBERS
  // ---------------------------------------------------------------------------

  Future<CommunityMember> addCommunityMember({
    required String communityId,
    required String userId,
    String role = 'member',
  }) async {
    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.communityMembersCollection,
      data: {
        'community_id': communityId,
        'user_id': userId,
        'role': role,
        'joined_at': DateTime.now().toIso8601String(),
      },
    );
    return CommunityMember.fromJson(doc.data);
  }

  Future<List<CommunityMember>> listCommunityMembers(String communityId) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.communityMembersCollection,
      queries: [Query.equal('community_id', communityId)],
    );
    return (res.documents as List)
        .map((d) => CommunityMember.fromJson(d.data))
        .toList();
  }

  /// Communities the given user belongs to.
  Future<List<CommunityMember>> listUserMemberships(String userId) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.communityMembersCollection,
      queries: [Query.equal('user_id', userId)],
    );
    return (res.documents as List)
        .map((d) => CommunityMember.fromJson(d.data))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // COMMUNITY POSTS
  // ---------------------------------------------------------------------------

  Future<CommunityPost> createPost({
    required String communityId,
    required String authorId,
    required String authorName,
    required String content,
    required String postType,
    String? imageId,
    String? linkedPlantId,
  }) async {
    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.communityPostsCollection,
      data: {
        'community_id': communityId,
        'author_id': authorId,
        'author_name': authorName,
        'content': content,
        'image_id': imageId,
        'post_type': postType,
        'linked_plant_id': linkedPlantId,
        'likes_count': 0,
        'comments_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
    return CommunityPost.fromJson(doc.data);
  }

  Future<List<CommunityPost>> listPosts(String communityId,
      {List<String>? queries}) async {
    final q = [
      Query.equal('community_id', communityId),
      Query.orderDesc('created_at'),
      ...(queries ?? []),
    ];
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.communityPostsCollection,
      queries: q,
    );
    return (res.documents as List)
        .map((d) => CommunityPost.fromJson(d.data))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // COMMUNITY COMMENTS
  // ---------------------------------------------------------------------------

  Future<CommunityComment> createComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.communityCommentsCollection,
      data: {
        'post_id': postId,
        'author_id': authorId,
        'author_name': authorName,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
    return CommunityComment.fromJson(doc.data);
  }

  Future<List<CommunityComment>> listComments(String postId) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.communityCommentsCollection,
      queries: [
        Query.equal('post_id', postId),
        Query.orderAsc('created_at'),
      ],
    );
    return (res.documents as List)
        .map((d) => CommunityComment.fromJson(d.data))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // COMMUNITY LIKES
  // ---------------------------------------------------------------------------

  Future<CommunityLike> likePost({
    required String postId,
    required String userId,
  }) async {
    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.communityLikesCollection,
      data: {
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
    return CommunityLike.fromJson(doc.data);
  }

  /// Check if a user already liked a post.
  Future<CommunityLike?> findLike(String postId, String userId) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.communityLikesCollection,
      queries: [
        Query.equal('post_id', postId),
        Query.equal('user_id', userId),
        Query.limit(1),
      ],
    );
    final docs = res.documents as List;
    if (docs.isEmpty) return null;
    return CommunityLike.fromJson(docs.first.data);
  }

  Future<void> unlikePost(String likeId) async {
    await _appwrite.deleteDocument(
      collectionId: AppwriteConstants.communityLikesCollection,
      documentId: likeId,
    );
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS
  // ---------------------------------------------------------------------------

  Future<NotificationModel> createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? senderId,
    String? linkedPostId,
    String? linkedCommunityId,
    String? linkedPlantId,
    String? plantName,
    String? plantLocation,
    String scheduleFrequency = 'none',
    int? customIntervalDays,
    bool isRecurring = false,
  }) async {
    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.notificationsCollection,
      data: {
        'recipient_id': recipientId,
        'sender_id': senderId,
        'type': type,
        'title': title,
        'body': body,
        'linked_post_id': linkedPostId,
        'linked_community_id': linkedCommunityId,
        'linked_plant_id': linkedPlantId,
        'plant_name': plantName,
        'plant_location': plantLocation,
        'schedule_frequency': scheduleFrequency,
        'custom_interval_days': customIntervalDays,
        'next_scheduled_at': null,
        'is_recurring': isRecurring,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
    return NotificationModel.fromJson(doc.data);
  }

  /// Inbox: unread first, newest first.
  Future<List<NotificationModel>> listNotifications(String userId,
      {bool unreadOnly = false}) async {
    final queries = <String>[
      Query.equal('recipient_id', userId),
      Query.orderDesc('created_at'),
    ];
    if (unreadOnly) {
      queries.add(Query.equal('is_read', false));
    }
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.notificationsCollection,
      queries: queries,
    );
    return (res.documents as List)
        .map((d) => NotificationModel.fromJson(d.data))
        .toList();
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _appwrite.updateDocument(
      collectionId: AppwriteConstants.notificationsCollection,
      documentId: notificationId,
      data: {'is_read': true},
    );
  }

  // ---------------------------------------------------------------------------
  // USER FCM TOKENS
  // ---------------------------------------------------------------------------

  Future<UserFcmToken> upsertFcmToken({
    required String userId,
    required String fcmToken,
    String? platform,
  }) async {
    // Check if token already exists for this user
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.userFcmTokensCollection,
      queries: [
        Query.equal('user_id', userId),
        Query.limit(1),
      ],
    );
    final docs = res.documents as List;
    if (docs.isNotEmpty) {
      final doc = await _appwrite.updateDocument(
        collectionId: AppwriteConstants.userFcmTokensCollection,
        documentId: docs.first.$id,
        data: {
          'fcm_token': fcmToken,
          'device_platform': platform,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
      return UserFcmToken.fromJson(doc.data);
    }
    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.userFcmTokensCollection,
      data: {
        'user_id': userId,
        'fcm_token': fcmToken,
        'device_platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
    return UserFcmToken.fromJson(doc.data);
  }

  // ---------------------------------------------------------------------------
  // CLOUD FUNCTIONS (convenience wrappers)
  // ---------------------------------------------------------------------------

  /// Call the verify_action cloud function.
  Future<dynamic> callVerifyAction({
    required String userId,
    required String plantId,
    required double userLat,
    required double userLong,
    required String imageUrl,
  }) async {
    return _appwrite.executeFunction(
      functionId: AppwriteConstants.verifyActionFunctionId,
      body:
          '{"user_id":"$userId","plant_id":"$plantId","user_lat":$userLat,"user_long":$userLong,"image_url":"$imageUrl"}',
    );
  }

  /// Call the join_community cloud function.
  Future<dynamic> callJoinCommunity({
    required String userId,
    required String inviteCode,
  }) async {
    return _appwrite.executeFunction(
      functionId: AppwriteConstants.joinCommunityFunctionId,
      body: '{"user_id":"$userId","invite_code":"$inviteCode"}',
    );
  }

  /// Call the send_notification cloud function.
  Future<dynamic> callSendNotification({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? linkedPlantId,
    String? plantName,
    String? scheduleFrequency,
  }) async {
    final payload = <String, dynamic>{
      'recipient_id': recipientId,
      'type': type,
      'title': title,
      'body': body,
    };
    if (linkedPlantId != null) payload['linked_plant_id'] = linkedPlantId;
    if (plantName != null) payload['plant_name'] = plantName;
    if (scheduleFrequency != null) {
      payload['schedule_frequency'] = scheduleFrequency;
    }
    return _appwrite.executeFunction(
      functionId: AppwriteConstants.sendNotificationFunctionId,
      body: payload.toString(),
    );
  }

  // ---------------------------------------------------------------------------
  // STORAGE HELPERS
  // ---------------------------------------------------------------------------

  /// Upload a plant evidence photo; returns the file ID.
  Future<String> uploadPlantImage(String filePath) async {
    final file = await _appwrite.uploadFile(
      bucketId: AppwriteConstants.plantImagesBucket,
      filePath: filePath,
      fileId: ID.unique(),
    );
    return file.$id;
  }

  /// Get preview URL for a plant image.
  String getPlantImageUrl(String fileId, {int? width, int? height}) {
    return _appwrite.getFilePreview(
      bucketId: AppwriteConstants.plantImagesBucket,
      fileId: fileId,
      width: width,
      height: height,
    );
  }

  /// Upload community media (post images, covers).
  Future<String> uploadCommunityMedia(String filePath) async {
    final file = await _appwrite.uploadFile(
      bucketId: AppwriteConstants.communityMediaBucket,
      filePath: filePath,
      fileId: ID.unique(),
    );
    return file.$id;
  }

  /// Get preview URL for community media.
  String getCommunityMediaUrl(String fileId, {int? width, int? height}) {
    return _appwrite.getFilePreview(
      bucketId: AppwriteConstants.communityMediaBucket,
      fileId: fileId,
      width: width,
      height: height,
    );
  }
}
