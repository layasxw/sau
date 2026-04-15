import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../onboarding_data.dart';
import 'personal_info_step.dart'; // reuse NavButtons

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
    'Peanuts', 'Tree nuts', 'Milk', 'Eggs', 'Wheat',
    'Soy', 'Fish', 'Shellfish', 'Sesame', 'Penicillin', 'Sulfa drugs',
  ];

  static const _chronicOptions = [
    'Diabetes', 'Hypertension', 'Heart disease', 'Asthma',
    'Arthritis', 'Thyroid disorder', 'Kidney disease', 'COPD',
  ];

  static const _dietaryOptions = [
    'Vegetarian', 'Vegan', 'Gluten-free', 'Lactose-free',
    'Low-sodium', 'Low-sugar', 'Halal', 'Kosher',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Health restrictions',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mark any allergies, conditions, or dietary needs',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 28),

          const _SectionHeader(
            icon: Icons.info_outline,
            iconColor: Color(0xFFFF9800),
            label: 'Allergies',
          ),
          const SizedBox(height: 12),
          _ChipGroup(
            options: _allergyOptions,
            selected: _allergies,
            onToggle: (v) => _toggle(_allergies, v),
          ),
          const SizedBox(height: 24),

          const _SectionHeader(
            icon: Icons.favorite_border,
            iconColor: AppColors.primary,
            label: 'Chronic Diseases',
          ),
          const SizedBox(height: 12),
          _ChipGroup(
            options: _chronicOptions,
            selected: _chronicDiseases,
            onToggle: (v) => _toggle(_chronicDiseases, v),
          ),
          const SizedBox(height: 24),

          const _SectionHeader(
            icon: Icons.eco_outlined,
            iconColor: Color(0xFF4CAF50),
            label: 'Dietary Restrictions',
          ),
          const SizedBox(height: 12),
          _ChipGroup(
            options: _dietaryOptions,
            selected: _dietaryRestrictions,
            onToggle: (v) => _toggle(_dietaryRestrictions, v),
          ),
          const SizedBox(height: 40),

          NavButtons(
            onBack: widget.onBack,
            onNext: _saveAndFinish,
            nextLabel: 'Generate My Plan',
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
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);

        return GestureDetector(
          onTap: () => onToggle(option),
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
              option,
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
