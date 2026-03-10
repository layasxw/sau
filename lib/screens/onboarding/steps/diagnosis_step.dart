import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../onboarding_data.dart';
import 'personal_info_step.dart'; // reuse FieldLabel, inputDecoration, NavButtons

class DiagnosisStep extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const DiagnosisStep({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<DiagnosisStep> createState() => _DiagnosisStepState();
}

class _DiagnosisStepState extends State<DiagnosisStep> {
  String? _selectedDiagnosis;
  late final TextEditingController _historyController;

  static const _diagnosisOptions = [
    'Cardiac Rehabilitation',
    'Post-Surgery Recovery',
    'Stroke Rehabilitation',
    'Orthopedic Injury',
    'Neurological Condition',
    'Respiratory Condition',
    'Diabetes Management',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDiagnosis = widget.data.diagnosis.isEmpty
        ? null
        : widget.data.diagnosis;
    _historyController =
        TextEditingController(text: widget.data.medicalHistory);
  }

  @override
  void dispose() {
    _historyController.dispose();
    super.dispose();
  }

  void _saveAndContinue() {
    if (_selectedDiagnosis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your primary diagnosis')),
      );
      return;
    }

    widget.data.diagnosis = _selectedDiagnosis!;
    widget.data.medicalHistory = _historyController.text.trim();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Your diagnosis',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Help us understand your rehabilitation needs',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 32),

          const FieldLabel('Primary Diagnosis'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedDiagnosis,
            hint: const Text(
              'Select your diagnosis',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            decoration: inputDecoration(''),
            isExpanded: true,
            items: _diagnosisOptions
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (value) => setState(() => _selectedDiagnosis = value),
          ),
          const SizedBox(height: 20),

          const Row(
            children: [
              FieldLabel('Medical History'),
              SizedBox(width: 6),
              Text(
                '(optional)',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _historyController,
            maxLines: null,
            minLines: 5,
            keyboardType: TextInputType.multiline,
            decoration: inputDecoration(
              'Brief medical history, previous treatments, surgeries, etc.',
            ),
          ),

          const SizedBox(height: 48),

          NavButtons(onBack: widget.onBack, onNext: _saveAndContinue),
        ],
      ),
    );
  }
}
