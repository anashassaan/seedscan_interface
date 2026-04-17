// lib/main.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/controllers/theme_controller.dart';
import 'config/controllers/notification_controller.dart';
import 'services/push_notification_service.dart';
import 'config/controllers/admin_controller.dart';
import 'config/controllers/withdrawal_controller.dart';
import 'config/theme.dart';
import 'config/controllers/auth_controller.dart';
import 'config/controllers/scan_controller.dart';
import 'config/controllers/chat_controller.dart';
import 'config/controllers/wallet_controller.dart';
import 'config/controllers/community_controller.dart';
import 'services/appwrite_service.dart';
import 'services/garden_cache_service.dart';
import 'services/hive_cache_service.dart';

import 'config/views/auth/login_view.dart';
import 'config/views/main/main_navigation.dart';
import 'config/views/admin/admin_dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Google Fonts defaults to true. When offline, it throws a SocketException.
  // We explicitly catch this in the PlatformDispatcher below so it falls back
  // to system fonts smoothly without crashing.

  // Catch uncaught errors from the root zone (e.g. Appwrite Realtime SDK
  // throwing _TypeError when it receives null-payload WebSocket frames).
  // Returning true marks the error as handled so Flutter does not crash.
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error is TypeError) {
      debugPrint('[RootZone] Suppressed TypeError: $error');
      return true;
    }
    if (error is FormatException) {
      debugPrint('[RootZone] Suppressed FormatException: $error');
      return true;
    }
    if (error is RangeError) {
      debugPrint('[RootZone] Suppressed RangeError: $error');
      return true;
    }

    // Suppress Google Fonts (and other non-fatal) offline connection exceptions
    // This allows the app to fallback to native system fonts gracefully instead of crashing
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup')) {
      debugPrint(
          '[RootZone] Suppressed SocketException (Offline Mode Fallback allowed): $error');
      return true;
    }

    return false;
  };

  // Initialize Hive (local cache)
  await Hive.initFlutter();
  await GardenCacheService.initialize();
  await HiveCacheService.initialize();

  // Initialize local notifications (permission request + channel setup)
  await PushNotificationService().initLocalNotifications();

  // Initialize Appwrite before anything else
  final appwrite = AppwriteService();
  appwrite.initialize();

  runApp(const SeedScanApp());
}

class SeedScanApp extends StatelessWidget {
  const SeedScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
        ChangeNotifierProvider<ScanController>(create: (_) => ScanController()),
        ChangeNotifierProvider<ChatController>(create: (_) => ChatController()),
        ChangeNotifierProvider<CommunityController>(
            create: (_) => CommunityController()),
        ChangeNotifierProvider<ThemeController>(
            create: (_) => ThemeController()),
        ChangeNotifierProvider<NotificationController>(
            create: (_) => NotificationController()),
        ChangeNotifierProvider<WalletController>(
            create: (_) => WalletController()),
        ChangeNotifierProvider<WithdrawalController>(
            create: (_) => WithdrawalController()),
        ChangeNotifierProvider<AdminController>(
            create: (_) => AdminController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SeedScan',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeController.themeMode,
            // Clamp the system text-scale factor globally so that users
            // with large accessibility font settings cannot cause overflow.
            // 0.9–1.15 still respects the user's preference while keeping
            // all layouts safe on any screen size.
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final clampedTextScaler = mediaQuery.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.15,
              );
              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: clampedTextScaler),
                child: child!,
              );
            },
            home: const EntryDecider(),
          );
        },
      ),
    );
  }
}

class EntryDecider extends StatefulWidget {
  const EntryDecider({super.key});

  @override
  State<EntryDecider> createState() => _EntryDeciderState();
}

class _EntryDeciderState extends State<EntryDecider> {
  bool _initializing = true;
  String? _loadedForUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    // Restore auth from Hive + SharedPrefs (instant, ~30ms).
    // This sets isLoggedIn/isAdmin from cache so we can navigate immediately.
    await auth.initialize();

    if (mounted) {
      setState(() => _initializing = false);
    }

    // Fire data loading in the BACKGROUND — we do NOT await this.
    // Each controller shows cached data instantly via notifyListeners(),
    // then quietly syncs with Appwrite and updates again.
    if (auth.isLoggedIn && !auth.isAdmin) {
      final uid = auth.userId ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _kickoffUserDataLoading(uid);
      });
    }
  }

  /// Fires all user-scoped data loaders concurrently in the background.
  /// None of them block the UI — they each do cache-first + background sync.
  void _kickoffUserDataLoading(String userId) {
    if (userId.isEmpty) return;
    if (_loadedForUserId == userId) return;
    _loadedForUserId = userId;

    final communityCtrl =
        Provider.of<CommunityController>(context, listen: false);
    final scanCtrl = Provider.of<ScanController>(context, listen: false);
    final notifCtrl =
        Provider.of<NotificationController>(context, listen: false);
    final walletCtrl = Provider.of<WalletController>(context, listen: false);

    // All four are intentionally NOT awaited — they are truly fire-and-forget.
    // Each controller:
    //   1. Loads from Hive instantly → calls notifyListeners() → UI updates
    //   2. Syncs with Appwrite in background → calls notifyListeners() again
    // ignore: unawaited_futures
    communityCtrl.loadUserCommunities(userId);
    // ignore: unawaited_futures
    scanCtrl.loadMyPlants(userId);
    // ignore: unawaited_futures
    notifCtrl.initialize(userId);
    // ignore: unawaited_futures
    walletCtrl.fetchWalletData(userId);
  }

  @override
  Widget build(BuildContext context) {
    // Only show splash spinner during the initial auth restore from cache (~30ms).
    // Once auth state is known, navigate immediately — no Appwrite wait.
    if (_initializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final auth = Provider.of<AuthController>(context);

    // Show login if not logged in
    if (!auth.isLoggedIn) {
      return const LoginView();
    }

    // Admin users get the admin dashboard
    if (auth.isAdmin) {
      final adminId = auth.userId ?? '';
      // SECURITY: Trigger admin controller update if admin user changed
      // This ensures old admin data isn't shown to new admin users
      if (adminId.isNotEmpty && _loadedForUserId != adminId) {
        _loadedForUserId = adminId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final adminCtrl =
                Provider.of<AdminController>(context, listen: false);
            adminCtrl.reset();
          }
        });
      }
      // Use adminId as key to force widget recreation when admin changes
      return AdminDashboardView(adminId: adminId, key: ValueKey(adminId));
    }

    // Regular users get the main app immediately.
    // If user just logged in (uid changed), kick off background data loading.
    final uid = auth.userId ?? '';
    if (uid.isNotEmpty && _loadedForUserId != uid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _kickoffUserDataLoading(uid);
      });
    }

    return const MainNavigation();
  }
}
