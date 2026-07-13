import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../screens/home/home_screen.dart';
import '../screens/music/music_screen.dart';
import '../screens/runs/runs_screen.dart';
import '../screens/settings/credits_screen.dart';

enum AppTab { home, music, runs }

/// Wraps every main screen with the shared radial-glow background, the
/// top bar (title + hamburger/star menu icon), and the bottom pill nav
/// with dots + an icon for the active tab, as seen across all 3 mockups.
class AppShell extends StatelessWidget {
  final String title;
  final AppTab activeTab;
  final Widget body;

  const AppShell({
    super.key,
    required this.title,
    required this.activeTab,
    required this.body,
  });

  void _navigateTo(BuildContext context, AppTab tab) {
    if (tab == activeTab) return;
    late final Widget screen;
    switch (tab) {
      case AppTab.home:
        screen = const HomeScreen();
        break;
      case AppTab.music:
        screen = const MusicScreen();
        break;
      case AppTab.runs:
        screen = const RunsScreen();
        break;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.screenBackground,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreditsScreen()),
                      ),
                      icon: const Icon(Icons.menu_rounded, color: AppColors.accentPink, size: 28),
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: _BottomPillNav(
                  activeTab: activeTab,
                  onTabSelected: (tab) => _navigateTo(context, tab),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomPillNav extends StatelessWidget {
  final AppTab activeTab;
  final ValueChanged<AppTab> onTabSelected;

  const _BottomPillNav({required this.activeTab, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final tabs = [AppTab.music, AppTab.home, AppTab.runs];
    final icons = {
      AppTab.music: Icons.music_note_rounded,
      AppTab.home: Icons.home_rounded,
      AppTab.runs: Icons.directions_run_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs.map((tab) {
          final isActive = tab == activeTab;
          return GestureDetector(
            onTap: () => onTabSelected(tab),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.accentPink : Colors.transparent,
              ),
              child: Icon(
                icons[tab],
                color: isActive ? Colors.black : AppColors.textSecondary,
                size: 20,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}