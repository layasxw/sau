import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    setState(() {
      _patients = patients;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Doctor Dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () async {
              await AuthService.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('My Patients',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('${_patients.length} patients under your care',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                if (_patients.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                        color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                    child: const Column(children: [
                      Icon(Icons.people_outline, size: 48, color: AppColors.divider),
                      SizedBox(height: 16),
                      Text('No patients yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      SizedBox(height: 8),
                      Text('Patients will appear here once they register', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ]),
                  )
                else
                  ..._patients.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _PatientCard(patient: p, onRefresh: _loadPatients),
                  )),
              ]),
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
    final riskColor = risk == 'high' ? Colors.red : risk == 'medium' ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person_outline, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(patient['fullName'] ?? 'Unknown',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('Age ${patient['age'] ?? '—'} • ${patient['gender'] ?? '—'}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ])),
          if (risk != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: riskColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(risk.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: riskColor)),
            ),
        ]),
        if (latest != null) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Latest symptoms',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: (Map<String, dynamic>.from(latest['symptoms'] ?? {})).entries.map((e) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20)),
                child: Text('${e.key} · ${e.value}/5',
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
              )
            ).toList(),
          ),
          if (aiAnalysis != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('AI Analysis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ]),
                const SizedBox(height: 6),
                Text(aiAnalysis['summary'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4)),
                const SizedBox(height: 4),
                Text(aiAnalysis['advice'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(patient['id'])
                          .collection('symptomLogs')
                          .doc(latest['id'])
                          .update({'aiAnalysis.doctorStatus': 'approved'});
                      onRefresh();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.check, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      ]),
                    ),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: GestureDetector(
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(patient['id'])
                          .collection('symptomLogs')
                          .doc(latest['id'])
                          .update({'aiAnalysis.doctorStatus': 'review'});
                      onRefresh();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.flag_outlined, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Needs Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      ]),
                    ),
                  )),
                ]),
                if (aiAnalysis['doctorStatus'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    aiAnalysis['doctorStatus'] == 'approved' ? '✓ Approved by doctor' : '⚠ Marked for review',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: aiAnalysis['doctorStatus'] == 'approved' ? Colors.green : Colors.orange),
                  ),
                ],
              ]),
            ),
          ],
        ],
      ]),
    );
  }
}