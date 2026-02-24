// lib/services/database_service.dart
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../config/appwrite_constants.dart';
import '../models/user_model.dart';
import '../models/plant_model.dart';
import '../models/community_model.dart';
import '../models/transaction_model.dart'; // ActivityLog
import '../models/qr_code_model.dart'; // DriveModel, RewardModel, UserFcmToken
import '../models/notification_model.dart';
import '../models/my_garden_qr_model.dart';
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
      permissions: [
        'read("users")',
        'create("users")',
        'update("users")',
        'delete("users")',
      ],
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
    // Use proper Appwrite SDK Permission + Role syntax (not raw strings)
    // Document-level permissions let THIS user read/update/delete their own membership.
    // IMPORTANT: The collection must also have 'create' permission for 'role:users'
    // in the Appwrite console, otherwise this call will return 401.
    final doc = await _appwrite.databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.communityMembersCollection,
      documentId: ID.unique(),
      data: {
        'community_id': communityId,
        'user_id': userId,
        'role': role,
        'joined_at': DateTime.now().toIso8601String(),
      },
      permissions: [
        Permission.read(Role.users()), // all authenticated users can read
        Permission.update(Role.user(userId)), // only this user can update
        Permission.delete(Role.user(userId)), // only this user can delete
      ],
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

  /// Check whether [userId] is already a member of [communityId].
  Future<bool> isUserInCommunity(String communityId, String userId) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.communityMembersCollection,
      queries: [
        Query.equal('community_id', communityId),
        Query.equal('user_id', userId),
        Query.limit(1),
      ],
    );
    return (res.documents as List).isNotEmpty;
  }

  /// Increment the member_count on a community document.
  Future<void> incrementCommunityMemberCount(String communityId) async {
    final community = await getCommunity(communityId);
    if (community != null) {
      await _appwrite.updateDocument(
        collectionId: AppwriteConstants.communitiesCollection,
        documentId: communityId,
        data: {'member_count': community.memberCount + 1},
      );
    }
  }

  /// Increment the plant_count on a community document.
  Future<void> incrementCommunityPlantCount(String communityId) async {
    final community = await getCommunity(communityId);
    if (community != null) {
      await _appwrite.updateDocument(
        collectionId: AppwriteConstants.communitiesCollection,
        documentId: communityId,
        data: {'plant_count': community.plantCount + 1},
      );
    }
  }

  /// Safely join a community. Returns `true` if the user was newly added,
  /// or `false` if they were already a member.
  /// Throws on unexpected backend errors so the caller can surface them.
  Future<bool> safeJoinCommunity({
    required String communityId,
    required String userId,
    String role = 'member',
  }) async {
    // Guard: no-op for empty IDs
    if (communityId.isEmpty || userId.isEmpty) return false;

    // Check membership first (avoid duplicate document errors)
    final alreadyMember = await isUserInCommunity(communityId, userId);
    if (alreadyMember) return false;

    // Add member record
    await addCommunityMember(
      communityId: communityId,
      userId: userId,
      role: role,
    );

    // Update member count (best-effort — don't fail if this errors)
    try {
      await incrementCommunityMemberCount(communityId);
    } catch (e) {
      debugPrint('safeJoinCommunity: member_count update failed: $e');
    }

    return true; // newly added
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
    final q = <String>[
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
  // MY GARDEN QR CODES
  // ---------------------------------------------------------------------------

  /// Create a My Garden QR code entry.
  Future<MyGardenQRModel> createMyGardenQR({
    required String uniqueCode,
    required String plantName,
    required String localName,
    required String category,
    required String bestSeason,
    required String qrType,
    String? plantAge,
    String notes = '',
    required String ownerId,
    required String ownerName,
    String ownerEmail = '',
    required String gardenId,
    double locationLat = 0.0,
    double locationLong = 0.0,
    String? imageFileId,
    String? imageUrl,
    DateTime? plantedAt,
  }) async {
    final now = DateTime.now();
    final List<String> imageHistory = [];
    if (imageFileId != null && imageUrl != null) {
      imageHistory.add(jsonEncode({
        'file_id': imageFileId,
        'url': imageUrl,
        'updated_at': (plantedAt ?? now).toIso8601String(),
      }));
    }
    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.myGardenQrCollection,
      data: {
        'unique_code': uniqueCode,
        'plant_name': plantName,
        'local_name': localName,
        'category': category,
        'best_season': bestSeason,
        'qr_type': qrType,
        'plant_age': plantAge,
        'notes': notes,
        'owner_id': ownerId,
        'owner_name': ownerName,
        'owner_email': ownerEmail,
        'garden_id': gardenId,
        'source': 'my_garden',
        'created_at': now.toIso8601String(),
        'location_lat': locationLat,
        'location_long': locationLong,
        'image_file_id': imageFileId,
        'image_url': imageUrl,
        'planted_at': (plantedAt ?? now).toIso8601String(),
        'image_history': imageHistory,
      },
    );
    return MyGardenQRModel.fromJson(doc.data);
  }

  /// Get a single My Garden QR code by document ID.
  Future<MyGardenQRModel?> getMyGardenQR(String docId) async {
    try {
      final doc = await _appwrite.getDocument(
        collectionId: AppwriteConstants.myGardenQrCollection,
        documentId: docId,
      );
      return MyGardenQRModel.fromJson(doc.data);
    } catch (_) {
      return null;
    }
  }

  /// List all My Garden QR codes for a given user.
  Future<List<MyGardenQRModel>> listMyGardenQRCodes(String userId) async {
    final res = await _appwrite.getDocuments(
      collectionId: AppwriteConstants.myGardenQrCollection,
      queries: [
        Query.equal('owner_id', userId),
        Query.orderDesc('created_at'),
      ],
    );
    return (res.documents as List)
        .map((d) => MyGardenQRModel.fromJson(d.data))
        .toList();
  }

  /// Find a My Garden QR code by its unique code (e.g. MYGARDEN-...).
  Future<MyGardenQRModel?> findMyGardenQRByUniqueCode(String uniqueCode) async {
    try {
      final res = await _appwrite.getDocuments(
        collectionId: AppwriteConstants.myGardenQrCollection,
        queries: <String>[
          Query.equal('unique_code', uniqueCode),
          Query.limit(1),
        ],
      );
      if (res.documents.isNotEmpty) {
        return MyGardenQRModel.fromJson(res.documents.first.data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Check if a QR code with this unique code already exists for a given user.
  Future<bool> qrExistsForUser(String uniqueCode, String userId) async {
    try {
      final res = await _appwrite.getDocuments(
        collectionId: AppwriteConstants.myGardenQrCollection,
        queries: <String>[
          Query.equal('unique_code', uniqueCode),
          Query.equal('owner_id', userId),
          Query.limit(1),
        ],
      );
      return res.documents.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Clone / add a scanned QR code into the current user's garden.
  Future<MyGardenQRModel> addScannedQRToMyGarden({
    required MyGardenQRModel originalQr,
    required String newOwnerId,
    required String newOwnerName,
    required String newOwnerEmail,
    required String newGardenId,
    double locationLat = 0.0,
    double locationLong = 0.0,
    String? imageFileId,
    String? imageUrl,
    DateTime? plantedAt,
  }) async {
    final newUniqueCode =
        'MYGARDEN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}-${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
    return createMyGardenQR(
      uniqueCode: newUniqueCode,
      plantName: originalQr.plantName,
      localName: originalQr.localName,
      category: originalQr.category,
      bestSeason: originalQr.bestSeason,
      qrType: originalQr.qrType,
      plantAge: originalQr.plantAge,
      notes:
          'Scanned from ${originalQr.ownerName}\'s garden (${originalQr.uniqueCode})',
      ownerId: newOwnerId,
      ownerName: newOwnerName,
      ownerEmail: newOwnerEmail,
      gardenId: newGardenId,
      locationLat: locationLat,
      locationLong: locationLong,
      imageFileId: imageFileId,
      imageUrl: imageUrl,
      plantedAt: plantedAt,
    );
  }

  /// Delete a My Garden QR code.
  Future<void> deleteMyGardenQR(String docId) async {
    await _appwrite.deleteDocument(
      collectionId: AppwriteConstants.myGardenQrCollection,
      documentId: docId,
    );
  }

  /// Update a My Garden plant's image in the database (upload + update doc).
  /// Returns the updated image URL.
  Future<Map<String, String>> updateMyGardenPlantImage({
    required String docId,
    required String filePath,
  }) async {
    // 1. Upload image to Appwrite storage
    final fileId = await uploadPlantImage(filePath);
    final url = getPlantImageUrl(fileId);
    final now = DateTime.now().toIso8601String();

    // 2. Get the existing document to append to image_history
    final existing = await getMyGardenQR(docId);
    final List<String> history =
        existing?.imageHistory.map((e) => jsonEncode(e)).toList() ?? [];
    history.add(jsonEncode({
      'file_id': fileId,
      'url': url,
      'updated_at': now,
    }));

    // 3. Update the document with new image info
    await _appwrite.updateDocument(
      collectionId: AppwriteConstants.myGardenQrCollection,
      documentId: docId,
      data: {
        'image_file_id': fileId,
        'image_url': url,
        'image_history': history,
      },
    );

    return {'fileId': fileId, 'url': url, 'updatedAt': now};
  }

  /// Update a My Garden plant's location in the database.
  Future<void> updateMyGardenPlantLocation({
    required String docId,
    required double lat,
    required double lng,
  }) async {
    await _appwrite.updateDocument(
      collectionId: AppwriteConstants.myGardenQrCollection,
      documentId: docId,
      data: {
        'location_lat': lat,
        'location_long': lng,
      },
    );
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
      permissions: [
        Permission.read(Role.any()), // Allow everyone to view community images
      ],
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
