import 'package:flutter/material.dart';
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
    _Tab(Icons.dashboard_outlined, Icons.dashboard, 'Home'),
    _Tab(Icons.notifications_outlined, Icons.notifications, 'Reminders'),
    _Tab(Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Food'),
    _Tab(Icons.monitor_heart_outlined, Icons.monitor_heart, 'Symptoms'),
    _Tab(Icons.person_outline, Icons.person, 'Profile'),
  ];

  static const _titles = [
    'Dashboard',
    'Reminders',
    'Food Diary',
    'Symptom Tracking',
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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.favorite, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(_titles[_selectedIndex],
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(onNavigate: navigateTo),
          const RemindersScreen(),
          FoodDiaryScreen(),
          const SymptomsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        tabs: _tabs,
        onTap: navigateTo,
      ),
    );
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
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: sel ? 46 : 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary.withOpacity(0.13)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(sel ? tabs[i].activeIcon : tabs[i].icon,
                            size: 21,
                            color: sel
                                ? AppColors.primary
                                : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 3),
                      Text(tabs[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                            color: sel
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          )),
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
