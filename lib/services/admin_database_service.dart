// lib/services/admin_database_service.dart
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import '../config/appwrite_constants.dart';
import '../models/user_model.dart';
import '../models/community_model.dart';
import '../models/notification_model.dart';
import 'appwrite_service.dart';
import 'database_service.dart';

/// Admin-specific database service that bridges admin panel operations
/// to Appwrite backend. Uses [DatabaseService] for shared ops and adds
/// admin-only queries (bulk user listing, stats aggregation, QR codes, logs).
class AdminDatabaseService {
  static final AdminDatabaseService _instance =
      AdminDatabaseService._internal();
  factory AdminDatabaseService() => _instance;
  AdminDatabaseService._internal();

  final AppwriteService _appwrite = AppwriteService();
  final DatabaseService _db = DatabaseService();

  // ---------------------------------------------------------------------------
  // COMMUNITIES (admin operations)
  // ---------------------------------------------------------------------------

  /// Fetch all communities (admin sees everything).
  Future<List<Community>> listAllCommunities() async {
    try {
      final res = await _appwrite.getDocuments(
        collectionId: AppwriteConstants.communitiesCollection,
        queries: [Query.orderDesc('created_at'), Query.limit(100)],
      );
      return (res.documents as List)
          .map((d) => Community.fromJson(d.data))
          .toList();
    } catch (e) {
      debugPrint('AdminDB: Failed to list communities: $e');
      return [];
    }
  }

  /// Create a new community from admin panel.
  Future<Community> createCommunity({
    required String name,
    required String location,
    String description = '',
    required String creatorId,
    String? coverImageId,
    String? imageUrl,
    String category = 'General',
  }) async {
    final inviteCode =
        '${name.replaceAll(' ', '').substring(0, name.length.clamp(0, 4)).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final data = <String, dynamic>{
      'name': name,
      'description': description,
      'location': location,
      'creator_id': creatorId,
      'qr_code_url': '',
      'invite_code': inviteCode,
      'member_count': 0,
      'plant_count': 0,
      'category': category,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    };
    // Only include optional string fields when non-null to avoid
    // Appwrite rejecting explicit null values.
    if (coverImageId != null) data['cover_image_id'] = coverImageId;
    if (imageUrl != null) data['image_url'] = imageUrl;

    final doc = await _appwrite.createDocument(
      collectionId: AppwriteConstants.communitiesCollection,
      data: data,
    );
    return Community.fromJson(doc.data);
  }

  /// Update a community's fields.
  Future<Community?> updateCommunity(
      String communityId, Map<String, dynamic> data) async {
    try {
      final doc = await _appwrite.updateDocument(
        collectionId: AppwriteConstants.communitiesCollection,
        documentId: communityId,
        data: data,
      );
      return Community.fromJson(doc.data);
    } catch (e) {
      debugPrint('AdminDB: Failed to update community: $e');
      return null;
    }
  }

  /// Delete a community and all its members.
  Future<bool> deleteCommunity(String communityId) async {
    try {
      // First remove all community members
      final members = await listCommunityMembers(communityId);
      for (final m in members) {
        await _appwrite.deleteDocument(
          collectionId: AppwriteConstants.communityMembersCollection,
          documentId: m.id,
        );
      }
      // Then delete the community itself
      await _appwrite.deleteDocument(
        collectionId: AppwriteConstants.communitiesCollection,
        documentId: communityId,
      );
      return true;
    } catch (e) {
      debugPrint('AdminDB: Failed to delete community: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // USERS (admin operations)
  // ---------------------------------------------------------------------------

  /// Fetch all users in the system.
  Future<List<UserModel>> listAllUsers() async {
    try {
      return await _db.listUsers(queries: [Query.limit(500)]);
    } catch (e) {
      debugPrint('AdminDB: Failed to list users: $e');
      return [];
    }
  }

  /// Get a single user profile.
  Future<UserModel?> getUser(String userId) async {
    return _db.getUserProfile(userId);
  }

  /// Update a user's profile data.
  Future<UserModel?> updateUser(
      String userId, Map<String, dynamic> data) async {
    try {
      return await _db.updateUserProfile(userId, data);
    } catch (e) {
      debugPrint('AdminDB: Failed to update user: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // COMMUNITY MEMBERS (admin operations)
  // ---------------------------------------------------------------------------

  /// List all members of a specific community.
  Future<List<CommunityMember>> listCommunityMembers(String communityId) async {
    try {
      return await _db.listCommunityMembers(communityId);
    } catch (e) {
      debugPrint('AdminDB: Failed to list community members: $e');
      return [];
    }
  }

  /// Add a user to a community with a specific role.
  Future<CommunityMember?> addMemberToCommunity({
    required String communityId,
    required String userId,
    String role = 'member',
  }) async {
    try {
      final member = await _db.addCommunityMember(
        communityId: communityId,
        userId: userId,
        role: role,
      );
      // Update the community member count
      final community = await _db.getCommunity(communityId);
      if (community != null) {
        await updateCommunity(communityId, {
          'member_count': community.memberCount + 1,
        });
      }
      return member;
    } catch (e) {
      debugPrint('AdminDB: Failed to add member: $e');
      return null;
    }
  }

  /// Remove a member from a community.
  Future<bool> removeMemberFromCommunity({
    required String memberDocId,
    required String communityId,
  }) async {
    try {
      await _appwrite.deleteDocument(
        collectionId: AppwriteConstants.communityMembersCollection,
        documentId: memberDocId,
      );
      // Update the community member count
      final community = await _db.getCommunity(communityId);
      if (community != null && community.memberCount > 0) {
        await updateCommunity(communityId, {
          'member_count': community.memberCount - 1,
        });
      }
      return true;
    } catch (e) {
      debugPrint('AdminDB: Failed to remove member: $e');
      return false;
    }
  }

  /// Update a member's role.
  Future<bool> updateMemberRole({
    required String memberDocId,
    required String newRole,
  }) async {
    try {
      await _appwrite.updateDocument(
        collectionId: AppwriteConstants.communityMembersCollection,
        documentId: memberDocId,
        data: {'role': newRole},
      );
      return true;
    } catch (e) {
      debugPrint('AdminDB: Failed to update member role: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIVITY LOGS / STATS
  // ---------------------------------------------------------------------------

  /// Get all activity logs (for admin stats computation).
  Future<List<Map<String, dynamic>>> listAllActivityLogs() async {
    try {
      final res = await _appwrite.getDocuments(
        collectionId: AppwriteConstants.activityLogsCollection,
        queries: [Query.limit(500), Query.orderDesc('\$createdAt')],
      );
      return (res.documents as List)
          .map((d) => d.data as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('AdminDB: Failed to list activity logs: $e');
      return [];
    }
  }

  /// Get aggregated stats for the admin dashboard.
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final userStats = await _appwrite.getUserStats();
      final communityStats = await _appwrite.getCommunityStats();
      final coinStats = await _appwrite.getCoinStats();

      return {
        ...userStats,
        ...communityStats,
        ...coinStats,
      };
    } catch (e) {
      debugPrint('AdminDB: Failed to get dashboard stats: $e');
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // ADMIN QR CODES
  // ---------------------------------------------------------------------------

  /// Create admin QR code records in Appwrite.
  Future<List<String>> createAdminQrCodes({
    required String communityId,
    required String communityName,
    required List<Map<String, dynamic>> qrDataList,
  }) async {
    final createdIds = <String>[];
    try {
      for (final qrData in qrDataList) {
        final doc = await _appwrite.createDocument(
          collectionId: AppwriteConstants.adminQrCodesCollection,
          data: {
            'community_id': communityId,
            'community_name': communityName,
            'plant_name': qrData['plantName'] ?? '',
            'plant_type': qrData['plantType'] ?? '',
            'best_season': qrData['bestSeason'] ?? '',
            'is_seed': qrData['isSeed'] ?? true,
            'plant_age': qrData['plantAge'],
            'notes': qrData['notes'] ?? '',
            'qr_data': qrData['qrData'] ?? '',
            'is_uploaded': false,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
        createdIds.add(doc.$id);
      }
    } catch (e) {
      debugPrint('AdminDB: Failed to create QR codes: $e');
    }
    return createdIds;
  }

  /// List QR codes for a community.
  Future<List<Map<String, dynamic>>> listAdminQrCodes(
      String communityId) async {
    try {
      final res = await _appwrite.getDocuments(
        collectionId: AppwriteConstants.adminQrCodesCollection,
        queries: [
          Query.equal('community_id', communityId),
          Query.orderDesc('created_at'),
          Query.limit(500),
        ],
      );
      return (res.documents as List).map((d) {
        final data = d.data as Map<String, dynamic>;
        data['id'] = d.$id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('AdminDB: Failed to list QR codes: $e');
      return [];
    }
  }

  /// Mark QR codes as uploaded.
  Future<bool> markQrCodesUploaded(List<String> qrDocIds) async {
    try {
      for (final id in qrDocIds) {
        await _appwrite.updateDocument(
          collectionId: AppwriteConstants.adminQrCodesCollection,
          documentId: id,
          data: {'is_uploaded': true},
        );
      }
      return true;
    } catch (e) {
      debugPrint('AdminDB: Failed to mark QR codes uploaded: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS (admin broadcast)
  // ---------------------------------------------------------------------------

  /// Send a notification to all users (broadcasts).
  Future<bool> sendGlobalNotification({
    required String title,
    required String body,
    String? senderId,
  }) async {
    try {
      final users = await listAllUsers();
      for (final user in users) {
        await _db.createNotification(
          recipientId: user.id,
          type: 'system',
          title: title,
          body: body,
          senderId: senderId,
        );
      }
      return true;
    } catch (e) {
      debugPrint('AdminDB: Failed to send global notification: $e');
      return false;
    }
  }

  /// Send a notification to members of a specific community.
  Future<bool> sendCommunityNotification({
    required String communityId,
    required String title,
    required String body,
    String? senderId,
  }) async {
    try {
      final members = await listCommunityMembers(communityId);
      for (final member in members) {
        await _db.createNotification(
          recipientId: member.userId,
          type: 'system',
          title: title,
          body: body,
          senderId: senderId,
          linkedCommunityId: communityId,
        );
      }
      return true;
    } catch (e) {
      debugPrint('AdminDB: Failed to send community notification: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // SYSTEM LOGS
  // ---------------------------------------------------------------------------

  /// Log an admin action.
  Future<void> createSystemLog({
    required String action,
    required String performedBy,
    String level = 'INFO',
    String? details,
  }) async {
    try {
      await _appwrite.createDocument(
        collectionId: AppwriteConstants.systemLogsCollection,
        data: {
          'action': action,
          'performed_by': performedBy,
          'level': level,
          'details': details,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('AdminDB: Failed to create log: $e');
    }
  }

  /// List recent system logs.
  Future<List<Map<String, dynamic>>> listSystemLogs({int limit = 50}) async {
    try {
      final res = await _appwrite.getDocuments(
        collectionId: AppwriteConstants.systemLogsCollection,
        queries: [
          Query.orderDesc('created_at'),
          Query.limit(limit),
        ],
      );
      return (res.documents as List).map((d) {
        final data = d.data as Map<String, dynamic>;
        data['id'] = d.$id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('AdminDB: Failed to list system logs: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // PLANTS (admin stats)
  // ---------------------------------------------------------------------------

  /// Count total plants in the system.
  Future<int> getTotalPlantCount() async {
    try {
      final res = await _appwrite.getDocuments(
        collectionId: AppwriteConstants.plantsCollection,
        queries: [Query.limit(1)],
      );
      return res.total;
    } catch (e) {
      debugPrint('AdminDB: Failed to get plant count: $e');
      return 0;
    }
  }

  /// Get plant health distribution.
  Future<Map<String, int>> getPlantHealthDistribution() async {
    try {
      final distribution = <String, int>{};
      for (final status in AppwriteConstants.healthStatuses) {
        final res = await _appwrite.getDocuments(
          collectionId: AppwriteConstants.plantsCollection,
          queries: [
            Query.equal('health_status', status),
            Query.limit(1),
          ],
        );
        distribution[status] = res.total;
      }
      return distribution;
    } catch (e) {
      debugPrint('AdminDB: Failed to get health distribution: $e');
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // STORAGE (admin image uploads)
  // ---------------------------------------------------------------------------

  /// Upload a community cover image from admin panel.
  Future<String?> uploadCommunityImage(String filePath) async {
    try {
      final fileId = await _db.uploadCommunityMedia(filePath);
      return _db.getCommunityMediaUrl(fileId);
    } catch (e) {
      debugPrint('AdminDB: Failed to upload community image: $e');
      return null;
    }
  }
}
