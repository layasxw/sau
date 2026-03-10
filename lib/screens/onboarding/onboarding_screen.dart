import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';
import 'onboarding_data.dart';
import 'steps/personal_info_step.dart';
import 'steps/body_metrics_step.dart';
import 'steps/diagnosis_step.dart';
import 'steps/restrictions_step.dart';

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
  void _next() {
    if (_currentStep < 3) {
      // Still more steps to go — just advance
      setState(() => _currentStep++);
    } else {
      // Last step done — go to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(data: _data)),
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
    (icon: Icons.person_outline, label: 'Personal Info'),
    (icon: Icons.monitor_heart_outlined, label: 'Body Metrics'),
    (icon: Icons.favorite_border, label: 'Diagnosis'),
    (icon: Icons.apple_outlined, label: 'Restrictions'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false, // only respect top safe area (notch/status bar)
        child: Column(
          children: [
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
                        _steps[i].label,
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
