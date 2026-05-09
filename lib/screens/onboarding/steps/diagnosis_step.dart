import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../theme/app_theme.dart';
import '../onboarding_data.dart';
import 'personal_info_step.dart';

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
  late final TextEditingController _otherDiagnosisController;
  DateTime? _surgeryDate;
  String? _attachedFileName;
  PlatformFile? _attachedFile;
  String _surgicalPeriod = 'pre';

  static const _diagnosisOptions = [
    'Stomach cancer (Stage 1)',
    'Stomach cancer (Stage 2)',
    'Stomach cancer (Stage 3)',
    'Gastric lymphoma (MALT / DLBCL)',
    'Gastrointestinal stromal tumor (GIST)',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final saved = widget.data.diagnosis;
    if (saved.isEmpty || _diagnosisOptions.contains(saved)) {
      _selectedDiagnosis = saved.isEmpty ? null : saved;
      _otherDiagnosisController = TextEditingController();
    } else {
      _selectedDiagnosis = 'Other';
      _otherDiagnosisController = TextEditingController(text: saved);
    }
    _historyController = TextEditingController(text: widget.data.medicalHistory);
    _surgeryDate = widget.data.surgeryDate;
    _attachedFileName = widget.data.medicalFileName;
    _surgicalPeriod = widget.data.surgicalPeriod;
  }

  @override
  void dispose() {
    _historyController.dispose();
    _otherDiagnosisController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _surgeryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select surgery date',
    );
    if (picked != null) setState(() => _surgeryDate = picked);
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFile = result.files.first;
          _attachedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file picker')),
        );
      }
    }
  }

  void _removeFile() {
    setState(() {
      _attachedFile = null;
      _attachedFileName = null;
    });
    widget.data.medicalFileName = null;
    widget.data.medicalFileUrl = null;
  }

  void _saveAndContinue() {
    if (_selectedDiagnosis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your primary diagnosis')),
      );
      return;
    }
    if (_selectedDiagnosis == 'Other' &&
        _otherDiagnosisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your diagnosis')),
      );
      return;
    }
    if (_historyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in your medical history')),
      );
      return;
    }

    widget.data.diagnosis = _selectedDiagnosis == 'Other'
        ? _otherDiagnosisController.text.trim()
        : _selectedDiagnosis!;
    widget.data.medicalHistory = _historyController.text.trim();
    widget.data.surgeryDate = _surgeryDate;
    widget.data.medicalFileName = _attachedFileName;
    widget.data.surgicalPeriod = _surgicalPeriod;
    // Actual upload to Firebase Storage happens in the onboarding screen
    // using _attachedFile?.bytes after onNext() completes.
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
            value: _selectedDiagnosis,
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

          if (_selectedDiagnosis == 'Other') ...[
            const SizedBox(height: 16),
            const FieldLabel('Please describe your diagnosis'),
            const SizedBox(height: 8),
            TextField(
              controller: _otherDiagnosisController,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDecoration('Enter your diagnosis'),
            ),
          ],

          const SizedBox(height: 20),

          const FieldLabel('Surgical Period'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _surgicalPeriod = 'pre'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _surgicalPeriod == 'pre' ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _surgicalPeriod == 'pre' ? AppColors.primary : AppColors.divider),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Pre-rehabilitation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _surgicalPeriod == 'pre' ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _surgicalPeriod = 'post'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _surgicalPeriod == 'post' ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _surgicalPeriod == 'post' ? AppColors.primary : AppColors.divider),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Rehabilitation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _surgicalPeriod == 'post' ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const FieldLabel('Surgery Date'),
          const SizedBox(height: 4),
          const Text(
            'optional',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    _surgeryDate == null
                        ? 'Select date'
                        : '${_surgeryDate!.day.toString().padLeft(2, '0')}.${_surgeryDate!.month.toString().padLeft(2, '0')}.${_surgeryDate!.year}',
                    style: TextStyle(
                      color: _surgeryDate == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  if (_surgeryDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _surgeryDate = null),
                      child: const Icon(Icons.close,
                          size: 18, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const FieldLabel('Medical History'),
          const SizedBox(height: 4),
          const Text(
            'required — previous treatments, surgeries, chemotherapy, etc.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _historyController,
            maxLines: null,
            minLines: 5,
            keyboardType: TextInputType.multiline,
            decoration: inputDecoration(
              'E.g. Gastrectomy in March 2024, 6 cycles of FOLFOX chemotherapy...',
            ),
          ),

          const SizedBox(height: 20),

          // ── Medical Document Attachment ──────────────────────────────────
          const FieldLabel('Attach Medical Document'),
          const SizedBox(height: 4),
          const Text(
            'optional — discharge summary, test results, referral (PDF, image, Word)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),

          if (_attachedFileName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _attachedFileName!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _removeFile,
                    child: const Icon(Icons.close,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file_outlined,
                        size: 20, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text(
                      'Choose file',
                      style: TextStyle(
                          fontSize: 15, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 48),

          NavButtons(onBack: widget.onBack, onNext: _saveAndContinue),
        ],
      ),
    );
  }
}