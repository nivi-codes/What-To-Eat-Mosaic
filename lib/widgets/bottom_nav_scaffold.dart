import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class BottomNavScaffold extends StatelessWidget {
  const BottomNavScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _NavTab(icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu, label: 'Eat', path: '/eat'),
    _NavTab(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Community', path: '/community'),
    _NavTab(icon: Icons.bookmark_outline, activeIcon: Icons.bookmark, label: 'Saved', path: '/saved'),
    _NavTab(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Me', path: '/me'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = navigationShell.currentIndex == i;
                final tab = _tabs[i];
                return Expanded(
                  child: InkWell(
                    onTap: () => navigationShell.goBranch(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? tab.activeIcon : tab.icon,
                          color: selected ? AppColors.primary : AppColors.textMuted,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavTab({required this.icon, required this.activeIcon, required this.label, required this.path});
}
