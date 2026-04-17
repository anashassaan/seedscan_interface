// lib/config/appwrite_constants.dart
/// Central Appwrite configuration constants matching the SeedScan database design.

class AppwriteConstants {
  AppwriteConstants._();

  // ── Core ──────────────────────────────────────────────────────────────────
  static const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String projectId = '6971de42002712d649b2';
  static const String databaseId = 'seedscan_main_db';

  // ── Collection IDs ────────────────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String plantsCollection = 'plants';
  static const String drivesCollection = 'drives';
  static const String activityLogsCollection = 'activity_logs';
  static const String rewardsCollection = 'rewards';
  static const String communitiesCollection = 'communities';
  static const String communityMembersCollection = 'community_members';
  static const String communityPostsCollection = 'community_posts';
  static const String communityCommentsCollection = 'community_comments';
  static const String communityLikesCollection = 'community_likes';
  static const String notificationsCollection = 'notifications';
  static const String userFcmTokensCollection = 'user_fcm_tokens';
  static const String myGardenQrCollection = 'my_garden_qr_codes';
  static const String adminQrCodesCollection = 'admin_qr_codes';
  static const String customTasksCollection = 'custom_tasks';
  static const String systemLogsCollection = 'system_logs';
  static const String withdrawalsCollection = 'withdrawals';

  // ── Storage Bucket IDs ────────────────────────────────────────────────────
  static const String plantImagesBucket = 'plant_images';
  static const String communityMediaBucket = 'community_media';
  static const String profileImagesBucket = 'profile_images';

  // ── AI Model Bucket ───────────────────────────────────────────────────────
  /// Appwrite Storage bucket that holds all on-device model files.
  static const String modelsBucket = 'ml_models';

  /// File IDs inside [modelsBucket].
  static const String seedscanV7GgufFileId = 'seedscan_v7_q4km';
  static const String bestFloat32TfliteFileId = 'best_float32.tflite';
  static const String mobilenetV3TfliteFileId =
      'mobilenetv3_large_disease_updted';

  // ── Cloud Function IDs ────────────────────────────────────────────────────
  static const String verifyActionFunctionId = '69722863001c67722e75';
  static const String joinCommunityFunctionId = 'join_community';
  static const String sendNotificationFunctionId = 'send_notification';
  static const String requestWithdrawalFunctionId = 'request_withdrawal';

  // ── Enums (for validation) ────────────────────────────────────────────────
  static const List<String> healthStatuses = [
    'healthy',
    'diseased',
    'critical',
    'dead',
  ];
  static const List<String> driveStatuses = [
    'active',
    'completed',
    'archived',
  ];
  static const List<String> actionTypes = [
    'water',
    'scan_disease',
    'register',
  ];
  static const List<String> verificationStatuses = ['verified', 'rejected'];
  static const List<String> communityRoles = [
    'admin',
    'moderator',
    'member',
  ];
  static const List<String> postTypes = [
    'general',
    'plant_update',
    'tip',
    'achievement',
  ];
  static const List<String> notificationTypes = [
    'like',
    'comment',
    'invite',
    'watering',
    'system',
  ];
  static const List<String> scheduleFrequencies = [
    'none',
    'daily',
    'weekly',
    'monthly',
    'custom',
  ];
  static const List<String> devicePlatforms = ['android', 'ios'];
}
