// lib/services/push_notification_service.dart
/// Push Notification Service
/// Uses Appwrite Realtime (WebSocket) for delivery + flutter_local_notifications
/// to show system-level notifications.
///
/// Flow:
///   User logs in → NotificationController.initialize(userId) →
///   subscribes to Appwrite Realtime channel for notifications collection →
///   on new doc with recipient_id == userId || 'all' → shows local notification
///   AND adds to the in-app list.

import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/appwrite_constants.dart';
import 'appwrite_service.dart';

class PushNotificationService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // ── Fields ────────────────────────────────────────────────────────────────
  final FlutterLocalNotificationsPlugin _flnp =
      FlutterLocalNotificationsPlugin();

  RealtimeSubscription? _subscription;
  bool _localInitialized = false;

  // ── Android notification channel ──────────────────────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'seedscan_notifications',
    'SeedScan Alerts',
    description: 'Watering reminders and admin broadcasts from SeedScan',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  // ── Initialize local notifications ────────────────────────────────────────
  Future<void> initLocalNotifications() async {
    if (_localInitialized) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _flnp.initialize(initSettings);

      // Create the Android notification channel
      await _flnp
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Request Android 13+ notification permission
      await _flnp
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _localInitialized = true;
      debugPrint('[PushNotification] Local notifications initialized');
    } catch (e) {
      debugPrint('[PushNotification] initLocalNotifications error: $e');
    }
  }

  // ── Subscribe to Appwrite Realtime ────────────────────────────────────────
  /// Call this after user login. [userId] is the Appwrite user `$id`.
  /// [onNotification] is called with (title, body) whenever a notification
  /// arrives for this user so the controller can add it to its list.
  Future<void> subscribe({
    required String userId,
    required void Function(Map<String, dynamic> data) onNotification,
  }) async {
    await unsubscribe(); // clean up any prior subscription

    try {
      const channel =
          'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.notificationsCollection}.documents';

      // CRITICAL FIX: Create Realtime AND call subscribe() INSIDE runZonedGuarded.
      //
      // The Appwrite SDK registers its internal WebSocket onMessage handler in
      // whichever Dart zone is current when subscribe() is called.  Previously
      // both calls were made in the ROOT zone, so when the SDK's message parser
      // cast null → Map<dynamic,dynamic> it threw in the root zone — bypassing
      // every guard we placed only on stream.listen().
      //
      // By running everything inside runZonedGuarded, every SDK-internal
      // callback (including the null-cast that produces the TypeError) is owned
      // by this zone.  The zone's error handler swallows the error silently,
      // so it never reaches PlatformDispatcher and the debugger never breaks.
      runZonedGuarded(
        () {
          final realtime = Realtime(AppwriteService().client);
          _subscription = realtime.subscribe([channel]);

          _subscription!.stream.listen(
            (event) {
              try {
                final dynamic rawPayload = event.payload;
                if (rawPayload is! Map) return;
                final payload = Map<String, dynamic>.from(rawPayload);

                final recipientId = payload['recipient_id'] ?? '';
                if (recipientId == userId || recipientId == 'all') {
                  final title = payload['title'] ?? 'SeedScan';
                  final body = payload['body'] ?? '';
                  _showLocalNotification(title: title, body: body);
                  onNotification(payload);
                }
              } catch (e) {
                debugPrint(
                    '[PushNotification] Event processing error (ignored): $e');
              }
            },
            onError: (e) => debugPrint(
                '[PushNotification] Realtime stream error (ignored): $e'),
            cancelOnError: false,
          );
        },
        (e, st) =>
            debugPrint('[PushNotification] Realtime zone error (ignored): $e'),
      );

      debugPrint('[PushNotification] Subscribed for userId=$userId');
    } catch (e) {
      debugPrint('[PushNotification] subscribe() error: $e');
    }
  }

  // ── Unsubscribe ───────────────────────────────────────────────────────────
  Future<void> unsubscribe() async {
    try {
      _subscription?.close();
      _subscription = null;
    } catch (_) {}
  }

  // ── Show a local system notification ─────────────────────────────────────
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    if (!_localInitialized) await initLocalNotifications();
    try {
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        ticker: title,
        styleInformation: BigTextStyleInformation(body),
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _flnp.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('[PushNotification] _showLocalNotification error: $e');
    }
  }

  // ── Convenience: show a notification without Realtime (e.g. test) ─────────
  Future<void> showManual({
    required String title,
    required String body,
  }) async {
    await _showLocalNotification(title: title, body: body);
  }
}
