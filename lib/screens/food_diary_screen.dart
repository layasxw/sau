import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import './onboarding/onboarding_data.dart';
import '../services/firestore_service.dart';
import './nutrition_calculator.dart';
import './food_product.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class _Meal {
  final String id;
  final String name, type;
  final int calories;
  final double protein, carbs, fat;
  final DateTime date;
  
  _Meal({
    required this.id,
    required this.name,
    required this.type,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.date,
  });
}

class FoodDiaryScreen extends StatefulWidget {
  const FoodDiaryScreen({super.key});
  
  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  int _dayOffset = 0;
  List<_Meal> _logs = [];
  Map<String, dynamic>? _aiMealData;
  bool _aiMealLoading = false;

  double _dailyCalories = 0;
  double _dailyProtein = 0;
  double _dailyCarbs = 0;
  double _dailyFat = 0;

  @override
  void initState() {
    super.initState();
    _loadNutritionTargets();
  }

  Future<void> _loadNutritionTargets() async {
    final profile = await FirestoreService.getUserProfile();
    if (profile == null) return;
    List<Map<String, dynamic>> meals = await FirestoreService.getMeals();

    final data = OnboardingData();
    data.height = (profile['height'] as num?)?.toDouble() ?? 170;
    data.weight = (profile['weight'] as num?)?.toDouble() ?? 70;
    data.age = (profile['age'] as num?)?.toInt() ?? 30;
    data.gender = profile['gender'] as String? ?? 'Male';

    NutritionCalculator.calculate(data);
    setState(() {
      _dailyCalories = data.dailyCalories;
      _dailyProtein = data.dailyProtein;
      _dailyCarbs = data.dailyCarbs;
      _dailyFat = data.dailyFat;
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

    await _analyzeMeals();
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

  List<DateTime> get _tabs =>
      List.generate(5, (i) => DateTime.now().add(Duration(days: i - 4)));
  String _day(DateTime d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];

  void _showAddSheet() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddMealSheet(
            date: _date,
            onAdd: (m) async {
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

  Future<void> _analyzeMeals() async {
    if (_todayMeals.isEmpty) return;
    setState(() => _aiMealLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://sau-production.up.railway.app/analyze-meal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'meals': _todayMeals.map((m) => {'name': m.name, 'type': m.type, 'calories': m.calories}).toList(),
          'total_calories': _cals,
          'total_protein': _protein,
          'total_carbs': _carbs,
          'total_fat': _fat,
        }),
      );
      if (response.statusCode == 200) {
        setState(() => _aiMealData = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('AI error: $e');
    } finally {
      setState(() => _aiMealLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 100;
    final today = _todayMeals;
    
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Food Diary', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 4),
              Text('Track your meals and get AI-powered nutrition insights', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              Row(
                children: [
                   Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _tabs.asMap().entries.map((e) {
                          final offset = e.key - 4;
                          final sel = offset == _dayOffset;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _dayOffset = offset);
                                HapticFeedback.selectionClick();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                    color: sel ? AppColors.primary : AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: sel ? AppColors.primary : AppColors.divider, width: 0.5)),
                                child: Text('${_day(e.value)} ${e.value.day}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: sel ? Colors.white : AppColors.textPrimary)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
                padding: EdgeInsets.zero,
                children: [
                  _NutrCard(
                      icon: CupertinoIcons.flame,
                      bg: AppColors.calorieBg,
                      color: const Color(0xFFFF9800),
                      value: '$_cals kcal',
                      label: 'Calories',
                      target: _dailyCalories > 0 ? '${_dailyCalories.toInt()} kcal' : null),
                  _NutrCard(
                      icon: Icons.egg_outlined,
                      bg: AppColors.proteinBg,
                      color: AppColors.accent,
                      value: '${_protein.toStringAsFixed(1)}g',
                      label: 'Protein',
                      target: _dailyProtein > 0 ? '${_dailyProtein.toStringAsFixed(0)}g' : null),
                  _NutrCard(
                      icon: Icons.grain,
                      bg: AppColors.carbsBg,
                      color: AppColors.primary,
                      value: '${_carbs.toStringAsFixed(1)}g',
                      label: 'Carbs',
                      target: _dailyCarbs > 0 ? '${_dailyCarbs.toStringAsFixed(0)}g' : null),
                  _NutrCard(
                      icon: CupertinoIcons.drop,
                      bg: AppColors.fatBg,
                      color: const Color(0xFFFF7043),
                      value: '${_fat.toStringAsFixed(1)}g',
                      label: 'Fat',
                      target: _dailyFat > 0 ? '${_dailyFat.toStringAsFixed(0)}g' : null),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Logged Meals', style: Theme.of(context).textTheme.titleLarge),
                  _BouncingWrapper(
                    onTap: _showAddSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.add, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Add Meal', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        ]
                      )
                    )
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (today.isNotEmpty) ...[
                _AiBanner(aiData: _aiMealData, loading: _aiMealLoading),
                const SizedBox(height: 20),
                ...today.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MealCard(
                        meal: m,
                        onDelete: () async {
                          await FirestoreService.deleteMeal(m.id);
                          setState(() => _logs.remove(m));
                        }))),
              ] else
                _empty(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _empty() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.divider, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 40, offset: const Offset(0, 10))],
        ),
        child: Column(children: [
          const Icon(CupertinoIcons.square_list, size: 48, color: AppColors.divider),
          const SizedBox(height: 24),
          Text('No meals logged', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
              'Start tracking your nutrition to get AI-powered insights.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.45)),
        ]),
      );
}

class _NutrCard extends StatelessWidget {
  final IconData icon;
  final Color bg, color;
  final String value, label;
  final String? target;
  const _NutrCard({
    required this.icon,
    required this.bg,
    required this.color,
    required this.value,
    required this.label,
    this.target,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider, width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 20, offset: const Offset(0, 8))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 16)),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ],
            ),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5)),
            if (target != null)
              Text(
                'goal: $target',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.75)),
              ),
        ]),
      );
}

class _MealCard extends StatelessWidget {
  final _Meal meal;
  final VoidCallback onDelete;
  const _MealCard({required this.meal, required this.onDelete});
  
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 40, offset: const Offset(0, 10))],
        ),
        child: Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(CupertinoIcons.info,
                  color: AppColors.primary, size: 24)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(meal.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2)),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(meal.type,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700))),
                  const SizedBox(width: 10),
                  Text('${meal.calories} kcal',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ]),
              ])),
          _BouncingWrapper(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.delete,
                  size: 18, color: AppColors.accent),
            ),
          ),
        ]),
      );
}

class _AiBanner extends StatelessWidget {
  final Map<String, dynamic>? aiData;
  final bool loading;
  const _AiBanner({this.aiData, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.1))),
        child: const Row(children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          SizedBox(width: 16),
          Text('Analyzing your nutrition...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ]),
      );
    }

    final msg = aiData?['summary'] ?? 'Log more meals to unlock personalized AI nutrition insights.';
    final advice = aiData?['advice'] ?? '';
    final rating = aiData?['rating'] ?? 'good';
    final isLow = rating == 'low';
    final isHigh = rating == 'high';

    final badgeColor = isLow ? const Color(0xFFF59E0B) : isHigh ? AppColors.accent : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withOpacity(0.1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(CupertinoIcons.sparkles, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          const Text('AI Nutrition Insights',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -0.2)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(rating.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45, fontWeight: FontWeight.w500)),
        if (advice.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(advice, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        ],
        const SizedBox(height: 8),
        const Text(
          'This is not medical advice. Please consult your doctor.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
        ),
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
  final _gramsController = TextEditingController(text: '100');

  String _mealType = 'Breakfast';
  FoodProduct? _selected;
  String _searchQuery = '';

  static const _types = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  List<FoodProduct> get _filtered {
    if (_searchQuery.isEmpty) return foodDatabase;
    return foodDatabase
        .where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  double get _gramsValue => double.tryParse(_gramsController.text) ?? 100;
  double get _calcCalories => (_selected?.caloriesPer100g ?? 0) * _gramsValue / 100;
  double get _calcProtein => (_selected?.proteinPer100g ?? 0) * _gramsValue / 100;
  double get _calcCarbs => (_selected?.carbsPer100g ?? 0) * _gramsValue / 100;
  double get _calcFat => (_selected?.fatPer100g ?? 0) * _gramsValue / 100;

  void _onSave() {
    if (_selected == null) return;
    widget.onAdd(_Meal(
      id: '',
      name: _selected!.name,
      type: _mealType,
      calories: _calcCalories.round(),
      protein: _calcProtein,
      carbs: _calcCarbs,
      fat: _calcFat,
      date: widget.date,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Log a Meal', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.date.day}/${widget.date.month}/${widget.date.year}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider, thickness: 0.5),
            
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Meal Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _types.map((t) {
                        final sel = t == _mealType;
                        return GestureDetector(
                          onTap: () => setState(() => _mealType = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                                color: sel ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: sel ? AppColors.primary : AppColors.divider)),
                            child: Text(t,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : AppColors.textPrimary)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    const Text('Search Food', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. chicken, rice, soup...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: const Icon(CupertinoIcons.search, size: 18, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider)),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final food = _filtered[i];
                          final isSelected = _selected?.name == food.name;
                          return GestureDetector(
                            onTap: () => setState(() => _selected = food),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                                border: Border(bottom: BorderSide(color: AppColors.divider.withOpacity(0.5))),
                              ),
                              child: Row(children: [
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(food.name,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(food.category,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                )),
                                Text('${food.caloriesPer100g.toInt()} kcal',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? AppColors.primary : AppColors.textSecondary)),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_selected != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Portion:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _gramsController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                suffixText: 'g',
                                suffixStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(16)),
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
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
              ),
              child: _BouncingWrapper(
                onTap: _selected == null ? null : _onSave,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _selected != null ? AppGradients.primary : null,
                    color: _selected == null ? AppColors.divider : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Log Meal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ]
                  ),
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrPreview extends StatelessWidget {
  final String value, label;
  const _NutrPreview(this.value, this.label);
  
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
    const SizedBox(height: 2),
    Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
  ]);
}

class _BouncingWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _BouncingWrapper({super.key, required this.child, this.onTap});

  @override
  State<_BouncingWrapper> createState() => _BouncingWrapperState();
}

class _BouncingWrapperState extends State<_BouncingWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  
  @override
  void dispose() {  
    _controller.dispose(); 
    super.dispose(); 
  }
  
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => widget.onTap != null ? _controller.forward() : null,
    onTapUp: (_) { if (widget.onTap != null) { _controller.reverse(); widget.onTap!(); HapticFeedback.lightImpact(); } },
    onTapCancel: () => _controller.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}