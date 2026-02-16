import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UserGuidelinesScreen extends StatelessWidget {
  const UserGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'User Guidelines',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B6E4F),
                    Color(0xFF159A6E),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.bookOpen,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to SeedScan',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Learn how to make the most of the app',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Getting Started
            _buildSectionTitle('Getting Started', LucideIcons.rocket),
            const SizedBox(height: 12),
            _buildGuideCard(
              context,
              icon: LucideIcons.scan,
              title: 'Scanning Plants',
              description:
                  'Use the QR scanner to identify your plants. Tap the scan button in the center of the bottom navigation bar, then point your camera at the QR code on your plant tag.',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              context,
              icon: LucideIcons.camera,
              title: 'Disease Detection',
              description:
                  'Switch to disease detection mode in the scanner. Take a clear photo of the plant leaf to identify potential diseases using AI-powered analysis.',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              context,
              icon: LucideIcons.leaf,
              title: 'Managing Your Plants',
              description:
                  'View all your plants in the Plants tab. Track their health status, last scan date, and get reminders for watering and care.',
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Features
            _buildSectionTitle('Key Features', LucideIcons.sparkles),
            const SizedBox(height: 12),
            _buildGuideCard(
              context,
              icon: LucideIcons.bell,
              title: 'Notifications',
              description:
                  'Stay updated with plant care reminders, watering schedules, and health alerts. Check the notification icon on the home screen.',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              context,
              icon: LucideIcons.checkSquare,
              title: 'Tasks & Reminders',
              description:
                  'Create and manage daily, weekly, and monthly tasks for plant care. Track your progress and earn points for completed tasks.',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              context,
              icon: LucideIcons.wallet,
              title: 'Wallet & Rewards',
              description:
                  'Earn points for scanning plants and completing tasks. Redeem points for rewards or withdraw to JazzCash/EasyPaisa.',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              context,
              icon: LucideIcons.messageCircle,
              title: 'AI Chat Assistant',
              description:
                  'Chat with SeedScan AI for plant care advice, disease information, and gardening tips. Send photos for instant analysis.',
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Best Practices
            _buildSectionTitle('Best Practices', LucideIcons.lightbulb),
            const SizedBox(height: 12),
            _buildTipCard(
              context,
              '📸',
              'Take clear, well-lit photos - For accurate disease detection, ensure leaves are in focus with good lighting.',
              isDark,
            ),
            const SizedBox(height: 8),
            _buildTipCard(
              context,
              '⏰',
              'Set regular reminders - Create recurring tasks to maintain a consistent plant care schedule.',
              isDark,
            ),
            const SizedBox(height: 8),
            _buildTipCard(
              context,
              '📍',
              'Enable location services - Location data helps track where plants are located and provides better care recommendations.',
              isDark,
            ),
            const SizedBox(height: 8),
            _buildTipCard(
              context,
              '🔔',
              'Enable notifications - Never miss important plant care reminders and health alerts.',
              isDark,
            ),
            const SizedBox(height: 24),

            // Safety & Privacy
            _buildSectionTitle('Safety & Privacy', LucideIcons.shield),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.lock,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Privacy Matters',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Your data is encrypted and secure\n'
                    '• We never share your personal information\n'
                    '• Location data is only used for plant tracking\n'
                    '• You can delete your account anytime\n'
                    '• Review our Privacy Policy for details',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support
            _buildSectionTitle('Need Help?', LucideIcons.helpCircle),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.mail,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Email Support',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'support@seedscan.com',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.messageSquare,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Live Chat',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Chat with our support team',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.globe,
                          color: Colors.purple,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Visit Website',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'www.seedscan.com/help',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF0B6E4F),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B6E4F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF0B6E4F),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context,
    String emoji,
    String tip,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
