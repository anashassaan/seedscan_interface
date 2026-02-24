// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/controllers/theme_controller.dart';
import 'config/controllers/notification_controller.dart';
import 'config/controllers/admin_controller.dart';
import 'config/theme.dart';
import 'config/controllers/auth_controller.dart';
import 'config/controllers/scan_controller.dart';
import 'config/controllers/chat_controller.dart';
import 'config/controllers/wallet_controller.dart';
import 'config/controllers/community_controller.dart';
import 'services/appwrite_service.dart';

import 'config/views/auth/login_view.dart';
import 'config/views/main/main_navigation.dart';
import 'config/views/admin/admin_dashboard_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
            darkTheme: AppTheme
                .dark(), // Assuming AppTheme has a dark() method, if not I'll use standard dark
            themeMode: themeController.themeMode,
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    await auth.initialize();

    // Load user's communities AND plants from Appwrite once logged in
    if (auth.isLoggedIn && !auth.isAdmin) {
      final communityCtrl =
          Provider.of<CommunityController>(context, listen: false);
      final scanCtrl = Provider.of<ScanController>(context, listen: false);
      final uid = auth.userId ?? '';
      // Fire both loads concurrently
      await Future.wait([
        communityCtrl.loadUserCommunities(uid),
        scanCtrl.loadMyPlants(uid),
      ]);
    }

    if (mounted) {
      setState(() => _initializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      return const AdminDashboardView();
    }

    // Regular users get the main app
    return const MainNavigation();
  }
}
