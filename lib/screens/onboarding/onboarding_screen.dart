import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';
import 'onboarding_data.dart';
import 'steps/personal_info_step.dart';
import 'steps/body_metrics_step.dart';
import 'steps/diagnosis_step.dart';
import 'steps/restrictions_step.dart';
import '../../services/firestore_service.dart';
import '../../services/language_provider.dart';
import 'package:provider/provider.dart';
import '../../l10n/translations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHELL — owns _currentStep and _data, renders header + active step
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Which step we're on right now (0 = Personal Info … 3 = Restrictions)
  int _currentStep = 0;

  

  // One shared data object — every step writes its answers into this
  final _data = OnboardingData();

  // Called when the user taps "Continue" on any step
  void _next() async{
    if (_currentStep < 3) {
      // Still more steps to go — just advance
      setState(() => _currentStep++);
    } else {
      // Save everything to Firestore before navigating
      await FirestoreService.saveUserData(_data);
      await FirestoreService.saveMedicalProfile(_data);
      await FirestoreService.saveRestrictions(_data);
      await FirestoreService.completeOnboarding();
      // Last step done — go to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    }
  }

  // Called when the user taps "Back" on any step
  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // Returns the widget for whichever step is currently active
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return PersonalInfoStep(data: _data, onNext: _next, onBack: _back);
      case 1:
        return BodyMetricsStep(data: _data, onNext: _next, onBack: _back);
      case 2:
        return DiagnosisStep(data: _data, onNext: _next, onBack: _back);
      case 3:
        return RestrictionsStep(data: _data, onFinish: _next, onBack: _back);
      default:
        return PersonalInfoStep(data: _data, onNext: _next, onBack: _back);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // The 4 icons + progress bar at the top
          _StepHeader(currentStep: _currentStep),

          // The actual form for the current step, scrollable
          Expanded(child: _buildCurrentStep()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP HEADER — 4 icon bubbles + animated progress bar
// Kept in this file because it's tightly coupled to the shell
// ─────────────────────────────────────────────────────────────────────────────
class _StepHeader extends StatelessWidget {
  final int currentStep;

  const _StepHeader({required this.currentStep});

  // Metadata for each step bubble: icon + label
  // Using a simple list of records (Dart 3 syntax)
  static const _steps = [
    (icon: Icons.person_outline, labelKey: 'step_personal'),
    (icon: Icons.monitor_heart_outlined, labelKey: 'step_metrics'),
    (icon: Icons.favorite_border, labelKey: 'step_diagnosis'),
    (icon: Icons.apple_outlined, labelKey: 'step_restrictions'),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false, // only respect top safe area (notch/status bar)
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LanguageToggle(),
                ],
              ),
            ),
            // ── 4 step bubbles ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                // Space the 4 bubbles evenly across the row
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_steps.length, (i) {
                  final isDone = i < currentStep; // step already completed
                  final isActive = i == currentStep; // step currently on

                  return Column(
                    children: [
                      // ── Icon bubble ──────────────────────────────────────
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF4CAF50) // green when done
                              : isActive
                                  ? AppColors.primary // teal when active
                                  : const Color(0xFFF0F4F5), // grey when future
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isDone ? Icons.check : _steps[i].icon,
                          color: (isDone || isActive)
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ── Label under bubble ───────────────────────────────
                      Text(
                        Translations.get(lang, _steps[i].labelKey),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            // ── Animated progress bar ────────────────────────────────────────
            // value goes: 0.25 → 0.50 → 0.75 → 1.00 as steps complete
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (currentStep + 1) / 4),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: const Color(0xFFE0E6EA),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final langProv = Provider.of<LanguageProvider>(context);
    final current = langProv.currentLanguage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langBtn(context, AppLanguage.ru, 'RU', current == AppLanguage.ru),
          _langBtn(context, AppLanguage.kk, 'KZ', current == AppLanguage.kk),
          _langBtn(context, AppLanguage.en, 'EN', current == AppLanguage.en),
        ],
      ),
    );
  }

  Widget _langBtn(BuildContext context, AppLanguage lang, String label, bool active) {
    return GestureDetector(
      onTap: () => Provider.of<LanguageProvider>(context, listen: false).setLanguage(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active ? [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

