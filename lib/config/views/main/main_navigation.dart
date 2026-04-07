import 'package:flutter/material.dart';
import '../home/home_view.dart';
import '../scan/unified_scan_screen.dart';
import '../plants/plants_view.dart';
import '../social/chat_screen.dart';
import '../profile/profile_view.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeView(onNavigate: (i) => setState(() => index = i)),
      const PlantsView(),
      UnifiedScanScreen(
        onNavigateToChat: () => setState(() => index = 3),
      ),
      const ChatScreen(),
      const ProfileView(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: index == 3, // Only for Chat screen
      body: screens[index],
      floatingActionButton: index == 3
          ? null // Hide FAB on Chat screen
          : AnimatedScale(
              scale: index == 3 ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: 72,
                height: 72,
                child: FloatingActionButton(
                  onPressed: () => setState(() => index = 2),
                  elevation: 4,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: const CircleBorder(),
                  child: Icon(
                    Icons.qr_code_scanner,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: index == 3 ? null : const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_outlined, Icons.home, 'Home', 0),
            _navItem(Icons.forest_outlined, Icons.forest, 'Plants', 1),
            if (index != 3) const SizedBox(width: 48), // Space for FAB
            _navItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat', 3),
            _navItem(Icons.person_outline, Icons.person, 'Profile', 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData selectedIcon, String label, int i) {
    final isSelected = index == i;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final screenW = MediaQuery.of(context).size.width;
    final itemPadding = screenW < 360 ? 4.0 : 6.0;
    return InkWell(
      onTap: () => setState(() => index = i),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: EdgeInsets.all(itemPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
