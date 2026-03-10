import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import './onboarding/onboarding_data.dart';

class _Meal {
  final String name, type;
  final int calories;
  final double protein, carbs, fat;
  final DateTime date;
  _Meal(
      {required this.name,
      required this.type,
      required this.calories,
      required this.protein,
      required this.carbs,
      required this.fat,
      required this.date});
}

class FoodDiaryScreen extends StatefulWidget {
  final OnboardingData data;

  const FoodDiaryScreen({
    super.key,
    required this.data,
  });
  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

  

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  int _dayOffset = 0;
  final List<_Meal> _meals = [];

  

  DateTime get _date => DateTime.now().add(Duration(days: _dayOffset));
  List<_Meal> get _todayMeals => _meals
      .where((m) =>
          m.date.year == _date.year &&
          m.date.month == _date.month &&
          m.date.day == _date.day)
      .toList();

  int get _cals => _todayMeals.fold(0, (s, m) => s + m.calories);
  double get _protein => _todayMeals.fold(0.0, (s, m) => s + m.protein);
  double get _carbs => _todayMeals.fold(0.0, (s, m) => s + m.carbs);
  double get _fat => _todayMeals.fold(0.0, (s, m) => s + m.fat);

  double get _calorieProgress =>
      widget.data.dailyCalories == 0
          ? 0
          : _cals / widget.data.dailyCalories;

  double get _proteinProgress =>
      widget.data.dailyProtein == 0
          ? 0
          : _protein / widget.data.dailyProtein;

  double get _carbProgress =>
      widget.data.dailyCarbs == 0
          ? 0
          : _carbs / widget.data.dailyCarbs;

  double get _fatProgress =>
      widget.data.dailyFat == 0
          ? 0
          : _fat / widget.data.dailyFat;
  List<DateTime> get _tabs =>
      List.generate(5, (i) => DateTime.now().add(Duration(days: i - 4)));
  String _day(DateTime d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];

  void _showAddSheet() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddMealSheet(
            date: _date, onAdd: (m) => setState(() => _meals.add(m))),
      );

  @override
  Widget build(BuildContext context) {
    final today = _todayMeals;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Food Diary',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const Text('Track your meals and get AI-powered nutrition insights',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
              onPressed: _showAddSheet,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Meal'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600))),
        ),
        const SizedBox(height: 16),
        // Date tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: _tabs.asMap().entries.map((e) {
            final offset = e.key - 4;
            final sel = offset == _dayOffset;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _dayOffset = offset),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? AppColors.primary : AppColors.divider)),
                  child: Text('${_day(e.value)} ${e.value.day}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: sel ? Colors.white : AppColors.textPrimary)),
                ),
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 20),
        // Nutrition grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.65,
          children: [
            _NutrCard(
                icon: Icons.local_fire_department_outlined,
                bg: AppColors.calorieBg,
                color: const Color(0xFFFF9800),
                value: '$_cals / ${widget.data.dailyCalories.toStringAsFixed(0)}',
                label: 'Calories'),
            _NutrCard(
                icon: Icons.egg_outlined,
                bg: AppColors.proteinBg,
                color: AppColors.accent,
                value: '${_protein.toStringAsFixed(1)}g',
                label: 'Protein'),
            _NutrCard(
                icon: Icons.grain,
                bg: AppColors.carbsBg,
                color: AppColors.primary,
                value: '${_carbs.toStringAsFixed(1)}g / ${widget.data.dailyCarbs.toStringAsFixed(0)}g',
                label: 'Carbs'),
            _NutrCard(
                icon: Icons.opacity,
                bg: AppColors.fatBg,
                color: const Color(0xFFFF7043),
                value: '${_fat.toStringAsFixed(1)}g / ${widget.data.dailyFat.toStringAsFixed(0)}g',
                label: 'Fat'),
          ],
        ),
        const SizedBox(height: 20),
        if (today.isNotEmpty) ...[
          _AiBanner(calories: _cals),
          const SizedBox(height: 20),
          const Text("Logged meals",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...today.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MealCard(
                  meal: m, onDelete: () => setState(() => _meals.remove(m))))),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.restaurant_menu_outlined,
                  size: 56, color: AppColors.divider),
              const SizedBox(height: 16),
              const Text('No meals logged',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                  'Start tracking your nutrition by adding your first meal',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                  onPressed: _showAddSheet,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Meal'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24))),
            ]),
          ),
      ]),
    );
  }
}

class _NutrCard extends StatelessWidget {
  final IconData icon;
  final Color bg, color;
  final String value, label;
  const _NutrCard(
      {required this.icon,
      required this.bg,
      required this.color,
      required this.value,
      required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.1)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ]),
        ]),
      );
}

class _MealCard extends StatelessWidget {
  final _Meal meal;
  final VoidCallback onDelete;
  const _MealCard({required this.meal, required this.onDelete});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.restaurant_menu_outlined,
                  color: AppColors.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(meal.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(meal.type,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600))),
                  const SizedBox(width: 8),
                  Text('${meal.calories} kcal',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ])),
          GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.textSecondary)),
        ]),
      );
}

class _AiBanner extends StatelessWidget {
  final int calories;
  const _AiBanner({required this.calories});
  @override
  Widget build(BuildContext context) {
    final msg = calories < 1200
        ? 'Calorie intake is low. For GI cancer recovery, eat small frequent meals — try adding a soft snack like yogurt or a banana.'
        : calories > 2200
            ? 'High intake today. Prioritize light, easily digestible foods and avoid heavy fats or spicy items.'
            : 'Good balance today! Continue with soft, nutrient-dense foods. Avoid raw vegetables and high-fiber items.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.2))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AI Nutrition Analysis',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(msg,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.primary, height: 1.4)),
        ])),
      ]),
    );
  }
}

// ── Add Meal Sheet ─────────────────────────────────────────────────────────────
class _AddMealSheet extends StatefulWidget {
  final DateTime date;
  final void Function(_Meal) onAdd;
  const _AddMealSheet({required this.date, required this.onAdd});
  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final _name = TextEditingController(),
      _cal = TextEditingController(),
      _prot = TextEditingController(),
      _carb = TextEditingController(),
      _fat = TextEditingController();
  String _type = 'Breakfast';
  static const _types = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Log a Meal',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Wrap(
              spacing: 8,
              children: _types.map((t) {
                final sel = t == _type;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                sel ? AppColors.primary : AppColors.divider)),
                    child: Text(t,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : AppColors.textPrimary)),
                  ),
                );
              }).toList()),
          const SizedBox(height: 16),
          const Text('Food name',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
              controller: _name,
              decoration: _dec('e.g. Chicken soup'),
              textCapitalization: TextCapitalization.sentences),
          const SizedBox(height: 16),
          const Text('Nutrition (optional)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _cal,
                    decoration: _dec('kcal'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _prot,
                    decoration: _dec('Protein g'),
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _carb,
                    decoration: _dec('Carbs g'),
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _fat,
                    decoration: _dec('Fat g'),
                    keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_name.text.trim().isEmpty) return;
                widget.onAdd(_Meal(
                    name: _name.text.trim(),
                    type: _type,
                    calories: int.tryParse(_cal.text) ?? 0,
                    protein: double.tryParse(_prot.text) ?? 0,
                    carbs: double.tryParse(_carb.text) ?? 0,
                    fat: double.tryParse(_fat.text) ?? 0,
                    date: widget.date));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0),
              child: const Text('Save Meal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ])),
      );
}
