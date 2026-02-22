// lib/views/auth/role_selection_view.dart
import 'package:flutter/material.dart';
import 'signup_view.dart';
import 'admin_signup_view.dart';

class RoleSelectionView extends StatelessWidget {
  const RoleSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        centerTitle: true,
        title: const Text('Join SeedScan'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Header
              Text(
                'How do you want to use SeedScan?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your role to get started',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Common User Card
              _RoleCard(
                icon: Icons.person_rounded,
                iconColor: cs.primary,
                title: 'Common User',
                subtitle:
                    'Scan plants, join communities, earn rewards, and track your garden activity.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignUpView(role: 'user'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Community Admin Card
              _RoleCard(
                icon: Icons.admin_panel_settings_rounded,
                iconColor: Colors.orange.shade700,
                title: 'Community Admin',
                subtitle:
                    'Create & manage communities, organize plantation drives, and monitor users.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminSignUpView(),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Bottom hint
              Text(
                'You can change your role later from settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.4),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: cs.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
