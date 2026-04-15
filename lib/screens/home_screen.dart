import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dashboard_screen.dart';
import 'reminders_screen.dart';
import 'food_diary_screen.dart';
import 'symptoms_screen.dart';
import 'profile_screen.dart';
import '../theme/app_theme.dart';
import './onboarding/onboarding_data.dart';

class HomeScreen extends StatefulWidget {
  
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    _Tab(CupertinoIcons.square_grid_2x2, CupertinoIcons.square_grid_2x2_fill, 'Home'),
    _Tab(CupertinoIcons.bell, CupertinoIcons.bell_fill, 'Reminders'),
    _Tab(CupertinoIcons.flame, CupertinoIcons.flame_fill, 'Food'),
    _Tab(CupertinoIcons.waveform_path_ecg, CupertinoIcons.waveform_path_ecg, 'Symptoms'),
    _Tab(CupertinoIcons.person, CupertinoIcons.person_fill, 'Profile'),
  ];

  static const _titles = [
    'Dashboard',
    'Reminders',
    'Food Diary',
    'Symptoms',
    'Profile'
  ];

  void navigateTo(int i) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withOpacity(0.8),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(CupertinoIcons.heart_fill, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            _titles[_selectedIndex],
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
        ]),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildPage(_selectedIndex),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomNav(
              selectedIndex: _selectedIndex,
              tabs: _tabs,
              onTap: navigateTo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return DashboardScreen(key: const ValueKey(0), onNavigate: navigateTo);
      case 1:
        return const RemindersScreen(key: ValueKey(1));
      case 2:
        return FoodDiaryScreen(key: const ValueKey(2));
      case 3:
        return const SymptomsScreen(key: ValueKey(3));
      case 4:
        return const ProfileScreen(key: ValueKey(4));
      default:
        return const SizedBox();
    }
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<_Tab> tabs;
  final ValueChanged<int> onTap;
  const _BottomNav(
      {required this.selectedIndex, required this.tabs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64, 
          child: Row(
            children: List.generate(tabs.length, (i) {
              final sel = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sel ? tabs[i].activeIcon : tabs[i].icon,
                        size: 26,
                        color: sel ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? AppColors.primary : AppColors.textSecondary,
                          letterSpacing: 0.2,
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
    );
  }
}

class _Tab {
  final IconData icon, activeIcon;
  final String label;
  const _Tab(this.icon, this.activeIcon, this.label);
}

