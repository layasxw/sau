import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static Future<void> logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok != true) return;
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(40)),
                child: const Icon(Icons.person_outline,
                    size: 42, color: AppColors.primary)),
            const SizedBox(height: 14),
            const Text('Ayaulym',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                child: const Text('Patient',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary))),
          ]),
        ),
        const SizedBox(height: 16),

        const _Card(
            title: 'Personal Information',
            icon: Icons.person_outline,
            children: [
              _Row('Full Name', 'Ayaulym'),
              _Row('Email', 'aya.09nice@gmail.com'),
              _Row('Age', '25'),
              _Row('Gender', 'Female'),
              _Row('Age category', 'Adult (18–45)'),
            ]),
        const SizedBox(height: 16),

        const _Card(
            title: 'Medical Profile',
            icon: Icons.local_hospital_outlined,
            children: [
              _Row('Diagnosis', 'Gastrointestinal cancer'),
              _Row('Treatment started', '01.02.2025'),
              _Row('Treating physician', 'Dr. Nurlan Bekov'),
              _Row('Clinic', 'Astana Oncology Center'),
              _Row('Stage', 'Stage II — under active treatment'),
            ]),
        const SizedBox(height: 16),

        const _Card(
            title: 'Medical History',
            icon: Icons.history_outlined,
            children: [
              _Row('Previous conditions', 'Hypertension (2023)',
                  multiline: true),
              _Row('Surgeries', 'Endoscopy — January 2025', multiline: true),
              _Row(
                  'Current treatment', 'Chemotherapy cycle 2 + dietary therapy',
                  multiline: true),
            ]),
        const SizedBox(height: 16),

        const _Card(
            title: 'Body Metrics',
            icon: Icons.monitor_heart_outlined,
            children: [
              _Row('Height', '170 cm'),
              _Row('Weight', '70 kg'),
              _Row('BMI', '24.2 (Normal)'),
            ]),
        const SizedBox(height: 16),

        const _Card(
            title: 'Health Restrictions',
            icon: Icons.block_outlined,
            children: [
              _ChipRow('Allergies', ['Milk', 'Sulfa drugs']),
              SizedBox(height: 12),
              _ChipRow('Chronic conditions', ['Hypertension']),
              SizedBox(height: 12),
              _ChipRow('Dietary restrictions',
                  ['Gluten-free', 'Low-fat', 'Low-sodium']),
            ]),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Card(
      {required this.title, required this.icon, required this.children});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          ...children,
        ]),
      );
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool multiline;
  const _Row(this.label, this.value, {this.multiline = false});
  @override
  Widget build(BuildContext context) {
    if (multiline) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
          ]));
    }
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary))),
        ]));
  }
}

class _ChipRow extends StatelessWidget {
  final String label;
  final List<String> values;
  const _ChipRow(this.label, this.values);
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 6,
            children: values
                .map((v) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(v,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary)),
                    ))
                .toList()),
      ]);
}
