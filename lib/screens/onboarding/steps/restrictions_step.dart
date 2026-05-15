import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../onboarding_data.dart';
import 'personal_info_step.dart';
import '../../../services/language_provider.dart';
import 'package:provider/provider.dart';
import '../../../l10n/translations.dart';

class RestrictionsStep extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onFinish;
  final VoidCallback onBack;

  const RestrictionsStep({
    super.key,
    required this.data,
    required this.onFinish,
    required this.onBack,
  });

  @override
  State<RestrictionsStep> createState() => _RestrictionsStepState();
}

class _RestrictionsStepState extends State<RestrictionsStep> {
  late List<String> _allergies;
  late List<String> _chronicDiseases;
  late List<String> _dietaryRestrictions;

  static const _allergyOptions = [
    {'key': 'Peanuts', 'labelKey': 'allergy_peanuts'},
    {'key': 'Tree nuts', 'labelKey': 'allergy_tree_nuts'},
    {'key': 'Milk', 'labelKey': 'allergy_milk'},
    {'key': 'Eggs', 'labelKey': 'allergy_eggs'},
    {'key': 'Wheat', 'labelKey': 'allergy_wheat'},
    {'key': 'Soy', 'labelKey': 'allergy_soy'},
    {'key': 'Fish', 'labelKey': 'allergy_fish'},
    {'key': 'Shellfish', 'labelKey': 'allergy_shellfish'},
    {'key': 'Sesame', 'labelKey': 'allergy_sesame'},
    {'key': 'Penicillin', 'labelKey': 'allergy_penicillin'},
    {'key': 'Sulfa drugs', 'labelKey': 'allergy_sulfa'},
  ];

  static const _chronicOptions = [
    {'key': 'Diabetes', 'labelKey': 'chronic_diabetes'},
    {'key': 'Hypertension', 'labelKey': 'chronic_hypertension'},
    {'key': 'Heart disease', 'labelKey': 'chronic_heart'},
    {'key': 'Asthma', 'labelKey': 'chronic_asthma'},
    {'key': 'Arthritis', 'labelKey': 'chronic_arthritis'},
    {'key': 'Thyroid disorder', 'labelKey': 'chronic_thyroid'},
    {'key': 'Kidney disease', 'labelKey': 'chronic_kidney'},
    {'key': 'COPD', 'labelKey': 'chronic_copd'},
  ];

  static const _dietaryOptions = [
    {'key': 'Vegetarian', 'labelKey': 'diet_veg'},
    {'key': 'Vegan', 'labelKey': 'diet_vegan'},
    {'key': 'Gluten-free', 'labelKey': 'diet_gluten_free'},
    {'key': 'Lactose-free', 'labelKey': 'diet_lactose_free'},
    {'key': 'Low-sodium', 'labelKey': 'diet_low_sodium'},
    {'key': 'Low-sugar', 'labelKey': 'diet_low_sugar'},
    {'key': 'Halal', 'labelKey': 'diet_halal'},
    {'key': 'Kosher', 'labelKey': 'diet_kosher'},
  ];

  @override
  void initState() {
    super.initState();
    _allergies = List.from(widget.data.allergies);
    _chronicDiseases = List.from(widget.data.chronicDiseases);
    _dietaryRestrictions = List.from(widget.data.dietaryRestrictions);
  }

  void _toggle(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  void _saveAndFinish() {
    widget.data.allergies = _allergies;
    widget.data.chronicDiseases = _chronicDiseases;
    widget.data.dietaryRestrictions = _dietaryRestrictions;
    widget.onFinish();
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
            Translations.get(lang, 'ob_rest_title'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            Translations.get(lang, 'ob_rest_subtitle'),
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 28),

          _SectionHeader(
            icon: Icons.info_outline,
            iconColor: const Color(0xFFFF9800),
            label: Translations.get(lang, 'ob_allergies'),
          ),
          const SizedBox(height: 12),
          _ChipGroup(
            options: _allergyOptions,
            selected: _allergies,
            onToggle: (v) => _toggle(_allergies, v),
            lang: lang,
          ),
          const SizedBox(height: 24),

          _SectionHeader(
            icon: Icons.favorite_border,
            iconColor: AppColors.primary,
            label: Translations.get(lang, 'ob_chronic'),
          ),
          const SizedBox(height: 12),
          _ChipGroup(
            options: _chronicOptions,
            selected: _chronicDiseases,
            onToggle: (v) => _toggle(_chronicDiseases, v),
            lang: lang,
          ),
          const SizedBox(height: 24),

          _SectionHeader(
            icon: Icons.eco_outlined,
            iconColor: const Color(0xFF4CAF50),
            label: Translations.get(lang, 'ob_dietary'),
          ),
          const SizedBox(height: 12),
          _ChipGroup(
            options: _dietaryOptions,
            selected: _dietaryRestrictions,
            onToggle: (v) => _toggle(_dietaryRestrictions, v),
            lang: lang,
          ),
          const SizedBox(height: 40),

          NavButtons(
            onBack: widget.onBack,
            onNext: _saveAndFinish,
            nextLabel: Translations.get(lang, 'generate_plan'),
            nextIcon: Icons.auto_awesome,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      );
}

class _ChipGroup extends StatelessWidget {
  final List<Map<String, String>> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final AppLanguage lang;

  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final key = option['key']!;
        final label = Translations.get(lang, option['labelKey']!);
        final isSelected = selected.contains(key);

        return GestureDetector(
          onTap: () => onToggle(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
