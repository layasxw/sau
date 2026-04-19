import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

Future<void> _loadAll() async {
  setState(() => _loading = true);
  try {
    final results = await Future.wait([
      FirestoreService.adminGetAllDoctors(),
      FirestoreService.adminGetAllPatients(),
    ]);
    print('Doctors: ${results[0]}');   // <-- добавь это
    print('Patients: ${results[1]}');  // <-- и это
    if (!mounted) return;
    setState(() {
      _doctors = results[0];
      _patients = results[1];
      _loading = false;
    });
  } catch (e) {
    print('Error loading: $e');        // <-- и это
    setState(() => _loading = false);
  }
}  // ── Verify doctor ─────────────────────────────────────────────────────────

  Future<void> _verifyDoctor(String doctorId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verify Doctor',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Grant $name access to their doctor dashboard?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await FirestoreService.adminVerifyDoctor(doctorId);
    _loadAll();
  }

  // ── Assign doctor to patient ──────────────────────────────────────────────

  Future<void> _showAssignDialog(Map<String, dynamic> patient) async {
    final verifiedDoctors =
        _doctors.where((d) => d['doctorStatus'] == 'verified').toList();

    if (verifiedDoctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No verified doctors available yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AssignDoctorSheet(
        patient: patient,
        doctors: verifiedDoctors,
        onAssign: (doctorId, doctorName) async {
          await FirestoreService.adminAssignDoctor(
              patient['id'], doctorId, doctorName);
          Navigator.pop(ctx);
          _loadAll();
        },
        onUnassign: patient['assignedDoctor'] != null
            ? () async {
                await FirestoreService.adminUnassignDoctor(patient['id']);
                Navigator.pop(ctx);
                _loadAll();
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        _doctors.where((d) => d['doctorStatus'] == 'pending').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Admin Panel',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () async {
              await AuthService.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Doctors'),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$pendingCount',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ],
              ]),
            ),
            Tab(text: 'Patients'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _DoctorsTab(
                  doctors: _doctors,
                  onVerify: _verifyDoctor,
                ),
                _PatientsTab(
                  patients: _patients,
                  onAssign: _showAssignDialog,
                ),
              ],
            ),
    );
  }
}

// ─── DOCTORS TAB ──────────────────────────────────────────────────────────────

class _DoctorsTab extends StatelessWidget {
  final List<Map<String, dynamic>> doctors;
  final Future<void> Function(String id, String name) onVerify;

  const _DoctorsTab({required this.doctors, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return const _EmptyState(
        icon: Icons.medical_services_outlined,
        text: 'No doctor accounts yet.\nDoctors register via the app.',
      );
    }

    // Sort: pending first
    final sorted = [...doctors]..sort((a, b) {
        final aP = a['doctorStatus'] == 'pending' ? 0 : 1;
        final bP = b['doctorStatus'] == 'pending' ? 0 : 1;
        return aP.compareTo(bP);
      });

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final d = sorted[i];
        final isPending = d['doctorStatus'] == 'pending';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPending
                  ? Colors.orange.withOpacity(0.4)
                  : AppColors.divider,
              width: isPending ? 1.5 : 0.5,
            ),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPending
                    ? Colors.orange.withOpacity(0.1)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.medical_services_outlined,
                  size: 22,
                  color: isPending ? Colors.orange : AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['fullName'] ?? d['email'] ?? 'Unknown',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPending
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPending ? 'Pending' : 'Verified',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPending ? Colors.orange : Colors.green),
                    ),
                  ),
                ]),
              ]),
            ),
            if (isPending)
              ElevatedButton(
                onPressed: () =>
                    onVerify(d['id'], d['fullName'] ?? 'this doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Verify'),
              ),
          ]),
        );
      },
    );
  }
}

// ─── PATIENTS TAB ─────────────────────────────────────────────────────────────

class _PatientsTab extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  final Future<void> Function(Map<String, dynamic>) onAssign;

  const _PatientsTab({required this.patients, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return const _EmptyState(
        icon: Icons.people_outline,
        text: 'No patients registered yet.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = patients[i];
        final hasDoctor = p['assignedDoctor'] != null;
        return Container(
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
              child: const Icon(Icons.person_outline,
                  size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['fullName'] ?? 'Unknown',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  hasDoctor
                      ? 'Dr. ${p['assignedDoctorName'] ?? 'Assigned'}'
                      : 'No doctor assigned',
                  style: TextStyle(
                      fontSize: 12,
                      color: hasDoctor
                          ? AppColors.primary
                          : AppColors.textSecondary),
                ),
              ]),
            ),
            GestureDetector(
              onTap: () => onAssign(p),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: hasDoctor
                      ? AppColors.background
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasDoctor ? AppColors.divider : AppColors.primary,
                  ),
                ),
                child: Text(
                  hasDoctor ? 'Change' : 'Assign',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasDoctor
                          ? AppColors.textSecondary
                          : AppColors.primary),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ─── ASSIGN DOCTOR SHEET ──────────────────────────────────────────────────────

class _AssignDoctorSheet extends StatelessWidget {
  final Map<String, dynamic> patient;
  final List<Map<String, dynamic>> doctors;
  final Future<void> Function(String doctorId, String doctorName) onAssign;
  final Future<void> Function()? onUnassign;

  const _AssignDoctorSheet({
    required this.patient,
    required this.doctors,
    required this.onAssign,
    this.onUnassign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 20),

        Text(
          'Assign doctor to ${patient['fullName'] ?? 'patient'}',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text('Select a verified doctor from the list below',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),

        ...doctors.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onAssign(d['id'], d['fullName'] ?? 'Doctor'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: d['id'] == patient['assignedDoctor']
                        ? AppColors.primaryLight
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: d['id'] == patient['assignedDoctor']
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(children: [
                    const Icon(Icons.medical_services_outlined,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(d['fullName'] ?? 'Unknown',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ),
                    if (d['id'] == patient['assignedDoctor'])
                      const Icon(Icons.check_circle,
                          size: 18, color: AppColors.primary),
                  ]),
                ),
              ),
            )),

        if (onUnassign != null) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: onUnassign,
            child: const Text('Remove doctor assignment',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.red,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ]),
    );
  }
}

// ─── SHARED ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 48, color: AppColors.divider),
        const SizedBox(height: 16),
        Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
      ]),
    );
  }
}