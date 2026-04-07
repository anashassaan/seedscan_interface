// lib/main.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/controllers/theme_controller.dart';
import 'config/controllers/notification_controller.dart';
import 'services/push_notification_service.dart';
import 'config/controllers/admin_controller.dart';
import 'config/theme.dart';
import 'config/controllers/auth_controller.dart';
import 'config/controllers/scan_controller.dart';
import 'config/controllers/chat_controller.dart';
import 'config/controllers/wallet_controller.dart';
import 'config/controllers/community_controller.dart';
import 'services/appwrite_service.dart';
import 'services/garden_cache_service.dart';

import 'config/views/auth/login_view.dart';
import 'config/views/main/main_navigation.dart';
import 'config/views/admin/admin_dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return false;
  };

  // Initialize Hive (local cache)
  await Hive.initFlutter();
  await GardenCacheService.initialize();

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
  bool _loadingUserData = false;
  String? _loadedForUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    await auth.initialize();

    // Load user-scoped data once logged in
    if (auth.isLoggedIn && !auth.isAdmin) {
      final uid = auth.userId ?? '';
      await _loadUserScopedData(uid);
    }

    if (mounted) {
      setState(() => _initializing = false);
    }
  }

  Future<void> _loadUserScopedData(String userId) async {
    if (userId.isEmpty || _loadingUserData) return;
    if (_loadedForUserId == userId) return;

    if (mounted) {
      setState(() => _loadingUserData = true);
    }

    final communityCtrl =
        Provider.of<CommunityController>(context, listen: false);
    final scanCtrl = Provider.of<ScanController>(context, listen: false);
    final notifCtrl =
        Provider.of<NotificationController>(context, listen: false);
    final walletCtrl = Provider.of<WalletController>(context, listen: false);

    try {
      await Future.wait([
        communityCtrl.loadUserCommunities(userId),
        scanCtrl.loadMyPlants(userId),
        notifCtrl.initialize(userId),
        walletCtrl.fetchWalletData(userId),
      ]);
      _loadedForUserId = userId;
    } finally {
      if (mounted) {
        setState(() => _loadingUserData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing || _loadingUserData) {
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
      return const AdminDashboardView();
    }

    final uid = auth.userId ?? '';
    if (uid.isNotEmpty && _loadedForUserId != uid && !_loadingUserData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadUserScopedData(uid);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Regular users get the main app
    return const MainNavigation();
  }
}
