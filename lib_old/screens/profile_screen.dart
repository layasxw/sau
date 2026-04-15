import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();

  static Future<void> logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Sign out from Firebase — clears the saved session
    await AuthService.signOut();

    if (context.mounted) {
      // Remove everything from the stack — user can't press Back to get back in
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── In a real app, this would come from Firestore and be editable in the UI ──
  String? _fullName;
  int?    _age;
  String? _gender;
  double? _height;
  double? _weight;
  bool    _isLoading = true;

  String? _diagnosis;
  String? _medicalHistory;

  List<String> _allergies = [];
  List<String> _chronicDiseases = [];
  List<String> _dietaryRestrictions = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final results = await Future.wait([
      FirestoreService.getUserProfile(),
      FirestoreService.getMedicalProfile(),
      FirestoreService.getRestrictions(),
    ]);

    final profile      = results[0];
    final medical      = results[1];
    final restrictions = results[2];

    setState(() {
      _fullName = profile?['fullName'] as String?;
      _age      = profile?['age'] as int?;
      _gender   = profile?['gender'] as String?;
      _height   = (profile?['height'] as num?)?.toDouble();
      _weight   = (profile?['weight'] as num?)?.toDouble();

      _diagnosis      = medical?['diagnosis'] as String?;
      _medicalHistory = medical?['medicalHistory'] as String?;

      _allergies = List<String>.from(restrictions?['allergies'] ?? []);
      _chronicDiseases = List<String>.from(restrictions?['chronicDiseases'] ?? []);
      _dietaryRestrictions = List<String>.from(restrictions?['dietaryRestrictions'] ?? []);

      _isLoading = false;
    });

    
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user's email from Firebase Auth
    final email = AuthService.currentUser?.email ?? 'Unknown';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header card
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Container(width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(40)),
              child: const Icon(Icons.person_outline, size: 42, color: AppColors.primary)),
            const SizedBox(height: 14),
            Text(_fullName ?? 'No name',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            // Show the real Firebase email
            Text(email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
              child: const Text('Patient',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        _Card(title: 'Personal Information', icon: Icons.person_outline, children: [
          _Row('Full Name', _fullName ?? '-'),
          _Row('Age', _age?.toString() ?? '-'),
          _Row('Gender', _gender ?? '-'),
          _Row('Height', _height != null ? '${_height!.toStringAsFixed(1)} cm' : '-'),
          _Row('Weight', _weight != null ? '${_weight!.toStringAsFixed(1)} kg' : '-'),
        ]),
        const SizedBox(height: 16),

        _Card(title: 'Medical Profile', icon: Icons.local_hospital_outlined, children: [
          _Row('Diagnosis', _diagnosis ?? '-'),
          _Row('Medical history', _medicalHistory ?? '-', multiline: true),
        ]),
        const SizedBox(height: 16),

        _Card(title: 'Health Restrictions', icon: Icons.block_outlined, children: [
          _ChipRow('Allergies', _allergies),
          SizedBox(height: 12),
          _ChipRow('Chronic conditions', _chronicDiseases),
          SizedBox(height: 12),
          _ChipRow('Dietary restrictions', _dietaryRestrictions),
        ]),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity, height: 52,
          child: OutlinedButton.icon(
            onPressed: () => ProfileScreen.logout(context),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
    );
  }
}
// ── Shared widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title; final IconData icon; final List<Widget> children;
  const _Card({required this.title, required this.icon, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ]),
      const SizedBox(height: 14),
      const Divider(color: AppColors.divider, height: 1),
      const SizedBox(height: 12),
      ...children,
    ]),
  );
}

class _Row extends StatelessWidget {
  final String label, value; final bool multiline;
  const _Row(this.label, this.value, {this.multiline = false});
  @override
  Widget build(BuildContext context) {
    if (multiline) return Padding(padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
      ]));
    return Padding(padding: const EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Flexible(child: Text(value, textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
      ]));
  }
}

class _ChipRow extends StatelessWidget {
  final String label; final List<String> values;
  const _ChipRow(this.label, this.values);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    const SizedBox(height: 8),
    Wrap(spacing: 8, runSpacing: 6, children: values.map((v) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
      child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
    )).toList()),
  ]);
}
