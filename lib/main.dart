// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/controllers/auth_controller.dart';
import 'config/controllers/scan_controller.dart';
import 'config/controllers/chat_controller.dart';

import 'config/views/auth/login_view.dart';
import 'config/views/main/main_navigation.dart';

void main() {
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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SeedScan',
        theme: AppTheme.light(),
        home: const EntryDecider(),
      ),
    );
  }
}

class EntryDecider extends StatelessWidget {
  const EntryDecider({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: auth.isLoggedIn ? const MainNavigation() : const LoginView(),
    );
  }
}
