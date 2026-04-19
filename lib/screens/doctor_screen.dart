import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rehab_assist/screens/patient_screen.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});
  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages =  [
    _PatientsTab(), 
    _AlertsTab(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Patients',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications,
                  label: 'Flags',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TAB 1: PATIENTS ─────────────────────────────────────────────────────────

class _PatientsTab extends StatefulWidget {
  const _PatientsTab();

  @override
  State<_PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends State<_PatientsTab> {
  List<Map<String, dynamic>> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final patients = await FirestoreService.getAllPatients();
    for (var p in patients) {
      final symptoms = await FirestoreService.getPatientSymptoms(p['id']);
      p['recentSymptoms'] = symptoms;
    }
    if (mounted) {
      setState(() {
        _patients = patients;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('My Patients',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPatients,
              child: _patients.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Column(children: [
                          Icon(Icons.people_outline, size: 48, color: AppColors.divider),
                          SizedBox(height: 16),
                          Text('No Patients Yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          SizedBox(height: 8),
                          Text('Share your invite code from the profile tab',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        ]),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _patients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _PatientCard(
                        patient: _patients[i],
                        onRefresh: _loadPatients,
                      ),
                    ),
            ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onRefresh;
  const _PatientCard({required this.patient, required this.onRefresh});
  @override
  Widget build(BuildContext context) {
    final symptoms = patient['recentSymptoms'] as List? ?? [];
    final latest = symptoms.isNotEmpty ? symptoms.first : null;
    final aiAnalysis = latest?['aiAnalysis'] as Map<String, dynamic>?;
    final risk = aiAnalysis?['risk'] as String?;
    final riskColor = risk == 'high'
        ? Colors.red
        : risk == 'medium'
            ? Colors.orange
            : Colors.green;

    return GestureDetector(
      onTap: () {
        debugPrint('tapped: ${patient['fullName']}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailScreen(patient: patient),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_outline, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(patient['fullName'] ?? 'Unknown',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text('${patient['age'] ?? '—'} y.o. • ${patient['gender'] ?? '—'}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ]),
          ),
          if (risk != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(risk.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: riskColor)),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
        ]),
      ),
    );
  }
}

// ─── TAB 2: ALERTS ───────────────────────────────────────────────────────────

const _redFlagKeywords = ['blood', 'vomiting', 'кровь', 'рвота', 'bleeding'];

class _AlertsTab extends StatefulWidget {
  const _AlertsTab();

  @override
  State<_AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<_AlertsTab> {
  List<Map<String, dynamic>> _flagged = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFlags();
  }

  Future<void> _loadFlags() async {
    setState(() => _loading = true);
    try {
      final patients = await FirestoreService.getAllPatients();
      final flagged = <Map<String, dynamic>>[];

      await Future.wait(patients.map((p) async {
        final symptoms = await FirestoreService.getPatientSymptomsWeek(p['id']);
        if (symptoms.isEmpty) {
          // Inactive — no logs in 7 days
          flagged.add({...p, '_flagReason': 'inactive', '_flagSeverity': 'inactive'});
          return;
        }

        // Check red flag keywords
        for (final log in symptoms) {
          final s = Map<String, dynamic>.from(log['symptoms'] ?? {});
          for (final key in s.keys) {
            if (_redFlagKeywords.any((f) => key.toLowerCase().contains(f))) {
              flagged.add({...p, '_flagReason': 'Red flag symptom: $key', '_flagSeverity': 'critical'});
              return;
            }
          }
        }

        // Check avg severity > 3.5
        double totalAvg = 0;
        int daysWithData = 0;
        for (final log in symptoms) {
          final s = Map<String, dynamic>.from(log['symptoms'] ?? {});
          if (s.isEmpty) continue;
          final avg = s.values.map((v) => (v as num).toDouble()).reduce((a, b) => a + b) / s.length;
          totalAvg += avg;
          daysWithData++;
        }
        if (daysWithData > 0 && totalAvg / daysWithData > 3.5) {
          flagged.add({
            ...p,
            '_flagReason': 'High avg severity (${(totalAvg / daysWithData).toStringAsFixed(1)}/5)',
            '_flagSeverity': 'high',
          });
        }
      }));

      // Sort: critical first, then high, then inactive
      flagged.sort((a, b) {
        const order = {'critical': 0, 'high': 1, 'inactive': 2};
        return (order[a['_flagSeverity']] ?? 3).compareTo(order[b['_flagSeverity']] ?? 3);
      });

      if (mounted) setState(() { _flagged = flagged; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(children: [
          const Text('Flags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (!_loading && _flagged.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text('${_flagged.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadFlags,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _flagged.isEmpty
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_outline, size: 48, color: AppColors.divider),
                    SizedBox(height: 16),
                    Text('No Active Flags',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    SizedBox(height: 8),
                    Text('All patients are doing well',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _flagged.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _FlagCard(patient: _flagged[i]),
                ),
    );
  }
}

class _FlagCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  const _FlagCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final severity = patient['_flagSeverity'] as String;
    final reason = patient['_flagReason'] as String;

    final color = severity == 'critical'
        ? Colors.red
        : severity == 'high'
            ? Colors.orange
            : AppColors.textSecondary;

    final icon = severity == 'critical'
        ? Icons.warning_rounded
        : severity == 'high'
            ? Icons.trending_up_rounded
            : Icons.notifications_off_outlined;

    final label = severity == 'critical'
        ? 'CRITICAL'
        : severity == 'high'
            ? 'HIGH RISK'
            : 'INACTIVE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(patient['fullName'] ?? 'Unknown',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(reason,
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
        ),
      ]),
    );
  }
}

// ─── TAB 3: PROFILE ──────────────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  String? _inviteCode;
  bool _loading = false;
  bool _codeCopied = false;

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () async {
              await AuthService.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Invite code card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.link, size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Invite code for patients',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: Text(
                          _inviteCode ?? '——',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          // TODO: copy to clipboard
                          setState(() => _codeCopied = true);
                          await Future.delayed(const Duration(seconds: 2));
                          if (mounted) setState(() => _codeCopied = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _codeCopied ? Colors.green.withOpacity(0.1) : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            Icon(
                              _codeCopied ? Icons.check : Icons.copy,
                              size: 14,
                              color: _codeCopied ? Colors.green : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _codeCopied ? 'Copied' : 'Copy',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _codeCopied ? Colors.green : AppColors.primary),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    const Text('Share this code with your patient — they enter it in their profile',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                  ]),
                ),

                const SizedBox(height: 12),

                // Regenerate code
                
              ],
            ),
    );
  }
}