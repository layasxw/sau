import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import '../onboarding_data.dart';
import 'personal_info_step.dart';
import '../../nutrition_calculator.dart';
import '../../../services/language_provider.dart';
import 'package:provider/provider.dart';
import '../../../l10n/translations.dart';

class BodyMetricsStep extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const BodyMetricsStep({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<BodyMetricsStep> createState() => _BodyMetricsStepState();
}

class _BodyMetricsStepState extends State<BodyMetricsStep> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(
      text: widget.data.height == 0 ? '' : widget.data.height.toStringAsFixed(0),
    );
    _weightController = TextEditingController(
      text: widget.data.weight == 0 ? '' : widget.data.weight.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _saveAndContinue() {
    final lang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final h = double.tryParse(_heightController.text);
    final w = double.tryParse(_weightController.text);

    if (h == null || w == null || h <= 0 || w <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.get(lang, 'ob_err_metrics'))),
      );
      return;
    }

    widget.data.height = h;
    widget.data.weight = w;
    NutritionCalculator.calculate(widget.data);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            Translations.get(lang, 'ob_metrics_title'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            Translations.get(lang, 'ob_metrics_subtitle'),
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldLabel(Translations.get(lang, 'ob_height')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _heightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: inputDecoration('170'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldLabel(Translations.get(lang, 'ob_weight')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: inputDecoration('70'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          NavButtons(onBack: widget.onBack, onNext: _saveAndContinue),
        ],
      ),
    );
  }
}
