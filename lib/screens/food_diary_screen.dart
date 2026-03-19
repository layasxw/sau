import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import './onboarding/onboarding_data.dart';
import '../services/firestore_service.dart';
import './nutrition_calculator.dart';
import './food_product.dart';

class _Meal {
  final String id;
  final String name, type;
  final int calories;
  final double protein, carbs, fat;
  final DateTime date;
  _Meal(
      {required this.id,
      required this.name,
      required this.type,
      required this.calories,
      required this.protein,
      required this.carbs,
      required this.fat,
      required this.date});
}

class FoodDiaryScreen extends StatefulWidget {

  const FoodDiaryScreen({
    super.key,
  });
  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();

  
}

  

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  @override
  void initState() {
    super.initState();
    _loadNutritionTargets();
  }
  int _dayOffset = 0;
  List<_Meal> _logs = [];

  double _dailyCalories = 0;
  double _dailyProtein = 0;
  double _dailyCarbs = 0;
  double _dailyFat = 0;

  Future<void> _loadNutritionTargets() async {
    final profile = await FirestoreService.getUserProfile();
    if (profile == null) return;
    List<Map<String, dynamic>> meals = await FirestoreService.getMeals();

    final data = OnboardingData();
    data.height = (profile['height'] as num).toDouble();
    data.weight = (profile['weight'] as num).toDouble();
    data.age    = profile['age'] as int;
    data.gender = profile['gender'] as String;

    NutritionCalculator.calculate(data);
    double bmi = data.weight / ((data.height / 100) * (data.height / 100));
    setState(() {
      _dailyCalories = data.dailyCalories;
      _dailyProtein  = data.dailyProtein;
      _dailyCarbs    = data.dailyCarbs;
      _dailyFat      = data.dailyFat;
    });
    setState(() {
      _logs = meals.map((m) {
        return _Meal(
          id: m['id'],
          name: m['name'],
          type: m['type'],
          calories: m['calories'],
          protein: (m['protein'] as num).toDouble(),
          carbs: (m['carbs'] as num).toDouble(),
          fat: (m['fat'] as num).toDouble(),
          date: (m['date'] as Timestamp).toDate(),
        );
      }).toList();
    });

    
  }

  DateTime get _date => DateTime.now().add(Duration(days: _dayOffset));
  List<_Meal> get _todayMeals => _logs
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
    _dailyCalories == 0 ? 0 : (_cals / _dailyCalories).clamp(0.0, 1.0);

  double get _proteinProgress =>
      _dailyProtein == 0 ? 0 : (_protein / _dailyProtein).clamp(0.0, 1.0);

  double get _carbProgress =>
      _dailyCarbs == 0 ? 0 : (_carbs / _dailyCarbs).clamp(0.0, 1.0);

  double get _fatProgress =>
      _dailyFat == 0 ? 0 : (_fat / _dailyFat).clamp(0.0, 1.0);

  List<DateTime> get _tabs =>
      List.generate(5, (i) => DateTime.now().add(Duration(days: i - 4)));
  String _day(DateTime d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];

  void _showAddSheet() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddMealSheet(
            date: _date, onAdd: (m) async {
              await FirestoreService.addMeal({
                'name': m.name,
                'type': m.type,
                'calories': m.calories,
                'protein': m.protein,
                'carbs': m.carbs,
                'fat': m.fat,
                'date': m.date,
              });
              _loadNutritionTargets();
            }),
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
                value: '$_cals / ${_dailyCalories.toStringAsFixed(0)}',
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
                value: '${_carbs.toStringAsFixed(1)}g / ${_dailyCarbs.toStringAsFixed(0)}g',
                label: 'Carbs'),
            _NutrCard(
                icon: Icons.opacity,
                bg: AppColors.fatBg,
                color: const Color(0xFFFF7043),
                value: '${_fat.toStringAsFixed(1)}g / ${_dailyFat.toStringAsFixed(0)}g',
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
                  meal: m, onDelete: () async {
                    await FirestoreService.deleteMeal(m.id);
                    setState(() => _logs.remove(m));
                  }))),
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
  final _searchController = TextEditingController();
  final _gramsController  = TextEditingController(text: '100');

  String _mealType = 'Breakfast';
  FoodProduct? _selected; // the food the user picked from the list
  String _searchQuery = '';

  static const _types = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  // Filters the database by the search query
  List<FoodProduct> get _filtered {
    if (_searchQuery.isEmpty) return foodDatabase;
    return foodDatabase
        .where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // Calculates nutrition based on selected food + entered grams
  // All values in food_product.dart are per 100g, so we scale by grams/100
  double get _gramsValue => double.tryParse(_gramsController.text) ?? 100;
  double get _calcCalories => (_selected?.caloriesPer100g ?? 0) * _gramsValue / 100;
  double get _calcProtein  => (_selected?.proteinPer100g  ?? 0) * _gramsValue / 100;
  double get _calcCarbs    => (_selected?.carbsPer100g    ?? 0) * _gramsValue / 100;
  double get _calcFat      => (_selected?.fatPer100g      ?? 0) * _gramsValue / 100;

  void _onSave() {
    if (_selected == null) return;
    widget.onAdd(_Meal(
      id:       '',
      name:     _selected!.name,
      type:     _mealType,
      calories: _calcCalories.round(),
      protein:  _calcProtein,
      carbs:    _calcCarbs,
      fat:      _calcFat,
      date:     widget.date,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          const Text('Log a Meal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),

          // ── Meal type chips ────────────────────────────────────────────────
          Wrap(
            spacing: 8,
            children: _types.map((t) {
              final sel = t == _mealType;
              return GestureDetector(
                onTap: () => setState(() => _mealType = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? AppColors.primary : AppColors.divider)),
                  child: Text(t,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textPrimary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Search field ───────────────────────────────────────────────────
          const Text('Search food',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'e.g. chicken, rice, soup...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true, fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 12),

          // ── Food list ──────────────────────────────────────────────────────
          // Shows up to 6 results — user scrolls horizontally through categories
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider)),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final food = _filtered[i];
                final isSelected = _selected?.name == food.name;
                return GestureDetector(
                  onTap: () => setState(() => _selected = food),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLight : Colors.transparent,
                      border: Border(
                          bottom: BorderSide(color: AppColors.divider.withOpacity(0.5))),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(food.name,
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                          Text(food.category,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      )),
                      Text('${food.caloriesPer100g.toInt()} kcal/100g',
                          style: TextStyle(fontSize: 12,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary)),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Grams input + calculated nutrition ────────────────────────────
          if (_selected != null) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const Text('Grams:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _gramsController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}), // recalculate on change
                  decoration: InputDecoration(
                    filled: true, fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('g', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 12),

            // Nutrition preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NutrPreview('${_calcCalories.toStringAsFixed(0)}', 'kcal'),
                  _NutrPreview('${_calcProtein.toStringAsFixed(1)}g', 'protein'),
                  _NutrPreview('${_calcCarbs.toStringAsFixed(1)}g', 'carbs'),
                  _NutrPreview('${_calcFat.toStringAsFixed(1)}g', 'fat'),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Save button ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selected == null ? null : _onSave,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.divider,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0),
              child: const Text('Save Meal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

// Small helper widget for the nutrition preview row
class _NutrPreview extends StatelessWidget {
  final String value, label;
  const _NutrPreview(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
        color: AppColors.primary)),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
  ]);
}
