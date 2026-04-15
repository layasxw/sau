import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            ),
            child: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await AuthService.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _fullName;
  int? _age;
  String? _gender;
  double? _height;
  double? _weight;
  bool _isLoading = true;

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

    final profile = results[0];
    final medical = results[1];
    final restrictions = results[2];

    setState(() {
      _fullName = profile?['fullName'] as String?;
      _age = profile?['age'] as int?;
      _gender = profile?['gender'] as String?;
      _height = (profile?['height'] as num?)?.toDouble();
      _weight = (profile?['weight'] as num?)?.toDouble();

      _diagnosis = medical?['diagnosis'] as String?;
      _medicalHistory = medical?['medicalHistory'] as String?;

      _allergies = List<String>.from(restrictions?['allergies'] ?? []);
      _chronicDiseases = List<String>.from(restrictions?['chronicDiseases'] ?? []);
      _dietaryRestrictions = List<String>.from(restrictions?['dietaryRestrictions'] ?? []);

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? 'Unknown';
    final bottomPadding = MediaQuery.of(context).padding.bottom + 100;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Profile', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 24),
              
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5)
                    ),
                    child: const Icon(CupertinoIcons.person_fill, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(_fullName ?? 'Patient Name',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(email, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: const Text('Verified Patient',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              _Card(title: 'Personal Information', icon: CupertinoIcons.person_crop_circle, children: [
                _Row('Full Name', _fullName ?? '-'),
                _Row('Age', _age?.toString() ?? '-'),
                _Row('Gender', _gender ?? '-'),
                _Row('Height', _height != null ? '${_height!.toStringAsFixed(1)} cm' : '-'),
                _Row('Weight', _weight != null ? '${_weight!.toStringAsFixed(1)} kg' : '-'),
              ]),
              const SizedBox(height: 16),

              _Card(title: 'Medical Profile', icon: CupertinoIcons.heart_solid, children: [
                _Row('Diagnosis', _diagnosis ?? '-'),
                _Row('Medical history', _medicalHistory ?? '-', multiline: true),
              ]),
              const SizedBox(height: 16),

              _Card(title: 'Health Restrictions', icon: CupertinoIcons.exclamationmark_shield, children: [
                _ChipRow('Allergies', _allergies),
                if (_allergies.isNotEmpty) const SizedBox(height: 16),
                _ChipRow('Chronic conditions', _chronicDiseases),
                if (_chronicDiseases.isNotEmpty) const SizedBox(height: 16),
                _ChipRow('Dietary restrictions', _dietaryRestrictions),
              ]),
              const SizedBox(height: 32),

              _BouncingWrapper(
                onTap: () => ProfileScreen.logout(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(CupertinoIcons.arrow_right_square, size: 20, color: AppColors.accent),
                      SizedBox(width: 8),
                      Text('Sign out', style: TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title; 
  final IconData icon; 
  final List<Widget> children;
  
  const _Card({required this.title, required this.icon, required this.children});
  
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, 
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.surface, 
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.divider, width: 0.5),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 40, offset: const Offset(0, 10))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.2)),
      ]),
      const SizedBox(height: 16),
      const Divider(color: AppColors.divider, height: 0.5),
      const SizedBox(height: 16),
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
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.45, fontWeight: FontWeight.w500)),
        ])
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(value, 
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)
            )
          ),
      ])
    );
  }
}

class _ChipRow extends StatelessWidget {
  final String label; 
  final List<String> values;
  
  const _ChipRow(this.label, this.values);
  
  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('None', style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      );
    }
    
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, 
        runSpacing: 8, 
        children: values.map((v) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05), 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.1))
          ),
          child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
        )).toList()
      ),
    ]);
  }
}

class _BouncingWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _BouncingWrapper({super.key, required this.child, this.onTap});

  @override
  State<_BouncingWrapper> createState() => _BouncingWrapperState();
}

class _BouncingWrapperState extends State<_BouncingWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  
  @override
  void dispose() {  
    _controller.dispose(); 
    super.dispose(); 
  }
  
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => widget.onTap != null ? _controller.forward() : null,
    onTapUp: (_) { if (widget.onTap != null) { _controller.reverse(); widget.onTap!(); HapticFeedback.lightImpact(); } },
    onTapCancel: () => _controller.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}
