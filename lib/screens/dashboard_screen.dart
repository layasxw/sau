import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _fullName;
  String? _diagnosis;
  int _remindersCount = 0;

  void _go(int i) => widget.onNavigate?.call(i);

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }
  

  Future<void> _loadInfo() async {
    // All three requests run at the same time
    final results = await Future.wait([
      FirestoreService.getUserProfile(),
      FirestoreService.getMedicalProfile(),
      FirestoreService.getReminders(),
    ]);

    final profile  = results[0] as Map<String, dynamic>?;
    final medical  = results[1] as Map<String, dynamic>?;
    final reminders = results[2] as List<Map<String, dynamic>>;

    setState(() {
      _fullName       = profile?['fullName'] as String?;
      _diagnosis      = medical?['diagnosis'] as String?;
      _remindersCount = reminders.length;
    });
  }

  String get _todayLabel {
    final n = DateTime.now();
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['January','February','March','April','May','June','July',
        'August','September','October','November','December'];
    return '${days[n.weekday - 1]}, ${months[n.month - 1]} ${n.day}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildStatCards(),
        const SizedBox(height: 20),
        _buildAIInsights(),
        const SizedBox(height: 20),
        _buildQuickActions(),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildHeader() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back, ${_fullName ?? 'there'}! 👋',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text('$_todayLabel • Let\'s continue your recovery journey',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _PillBtn(
              icon: Icons.monitor_heart_outlined,
              label: 'Log Symptoms',
              outlined: true,
              onTap: () => _go(3))),
          const SizedBox(width: 12),
          Expanded(child: _PillBtn(
              icon: Icons.add,
              label: 'Add Meal',
              outlined: false,
              onTap: () => _go(2))),
        ]),
      ]);

  Widget _buildStatCards() => Column(children: [
        _StatCard(
            icon: Icons.calendar_today_outlined,
            iconBg: AppColors.primaryLight,
            iconColor: AppColors.primary,
            value: '$_remindersCount',
            label: "Total reminders",
            onTap: () => _go(1)),
        const SizedBox(height: 12),
        _StatCard(
            icon: Icons.restaurant_menu_outlined,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: Colors.green,
            value: 'Track',
            label: 'Your nutrition',
            bold: true,
            onTap: () => _go(2)),
        const SizedBox(height: 12),
        _StatCard(
            icon: Icons.favorite_border,
            iconBg: AppColors.proteinBg,
            iconColor: AppColors.accent,
            value: _diagnosis ?? 'Not set',
            label: 'Your diagnosis',
            bold: true),
      ]);

  Widget _buildAIInsights() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('AI Insights',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 4),
          const Text('Personalized recommendations based on your diagnosis',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          _InsightCard(
              title: 'Strict Dietary Adherence',
              subtitle:
                  'Avoid spicy, fatty, and high-fiber foods that irritate the GI tract. Choose soft, easily digestible meals like cooked vegetables, white rice, and lean protein.',
              isImportant: true,
              onTap: () => _go(2)),
          const SizedBox(height: 10),
          _InsightCard(
              title: 'Watch for Red Flags',
              subtitle:
                  'Immediately contact your doctor if you notice blood in stool, sudden weight loss, severe abdominal pain, or persistent vomiting.',
              isImportant: true,
              onTap: () => _go(3)),
          const SizedBox(height: 10),
          const _InsightCard(
              title: 'Gentle Daily Movement',
              subtitle:
                  'Short 10–15 min walks support recovery and reduce fatigue. Do not increase intensity without consulting your doctor.',
              isImportant: false),
        ]),
      );

  Widget _buildQuickActions() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Quick Actions',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _ActionCard(
                icon: Icons.restaurant_menu_outlined,
                label: 'Log Meal',
                onTap: () => _go(2))),
            const SizedBox(width: 12),
            Expanded(child: _ActionCard(
                icon: Icons.monitor_heart_outlined,
                label: 'Log Symptoms',
                onTap: () => _go(3))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ActionCard(
                icon: Icons.notifications_outlined,
                label: 'Add Reminder',
                onTap: () => _go(1))),
            const SizedBox(width: 12),
            Expanded(child: _ActionCard(
                icon: Icons.trending_up,
                label: 'View Trends',
                onTap: () => _go(3))),
          ]),
        ]),
      );
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String value, label;
  final bool bold;
  final VoidCallback? onTap;
  const _StatCard({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.value, required this.label, this.bold = false, this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: bold ? 15 : 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ])),
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ]),
        ),
      );
}

class _InsightCard extends StatelessWidget {
  final String title, subtitle;
  final bool isImportant;
  final VoidCallback? onTap;
  const _InsightCard({
    required this.title, required this.subtitle,
    required this.isImportant, this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.background, borderRadius: BorderRadius.circular(12)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.auto_awesome,
                    color: AppColors.primary, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary))),
                    if (isImportant)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text('Important',
                            style: TextStyle(color: Colors.white,
                                fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                ])),
          ]),
        ),
      );
}

class _PillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool outlined;
  final VoidCallback onTap;
  const _PillBtn({
    required this.icon, required this.label,
    required this.outlined, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: outlined ? AppColors.surface : AppColors.primary,
            borderRadius: BorderRadius.circular(25),
            border: outlined ? Border.all(color: AppColors.divider) : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: outlined ? AppColors.primary : Colors.white),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: outlined ? AppColors.primary : Colors.white)),
          ]),
        ),
      );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
              color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ]),
        ),
      );
}
