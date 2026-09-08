import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/language_provider.dart';
import '../l10n/translations.dart';

class PatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _symptoms = [];
  List<Map<String, dynamic>> _meals = [];
  List<Map<String, dynamic>> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final patientId = widget.patient['id'] as String;
      final results = await Future.wait([
        FirestoreService.getPatientSymptomsWeek(patientId),
        FirestoreService.getPatientMealsWeek(patientId),
        FirestoreService.getPatientTodayReminders(patientId),
      ]);
      if (!mounted) return;
      setState(() {
        _symptoms = results[0];
        _meals = results[1];
        _reminders = results[2];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    final name = widget.patient['fullName'] ?? Translations.get(lang, 'patient_fallback_cap');
    final age = widget.patient['age'];
    final gender = widget.patient['gender'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (age != null || gender != null)
            Text('$age ${Translations.get(lang, 'years_old_suffix')} • $gender',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: [
            Tab(text: Translations.get(lang, 'nav_symptoms')),
            Tab(text: Translations.get(lang, 'nav_nutrition')),
            Tab(text: Translations.get(lang, 'nav_reminders')),
            Tab(text: Translations.get(lang, 'tab_message')),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _SymptomsTab(logs: _symptoms),
                _FoodTab(meals: _meals),
                _RemindersTab(reminders: _reminders),
                _MessageTab(patientId: widget.patient['id'] as String),
              ],
            ),
    );
  }
}

// ─── SYMPTOMS TAB ─────────────────────────────────────────────────────────────

class _SymptomsTab extends StatefulWidget {
  final List<Map<String, dynamic>> logs;
  const _SymptomsTab({required this.logs});

  @override
  State<_SymptomsTab> createState() => _SymptomsTabState();
}

class _SymptomsTabState extends State<_SymptomsTab> {
  final Set<String> _expanded = {};

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  String _dayLabel(DateTime d, AppLanguage lang) {
    const keys = ['day_monday', 'day_tuesday', 'day_wednesday', 'day_thursday', 'day_friday', 'day_saturday', 'day_sunday'];
    return Translations.get(lang, keys[d.weekday - 1]);
  }

  String _monthShort(int m, AppLanguage lang) {
    const keys = [
      'month_short_jan','month_short_feb','month_short_mar','month_short_apr',
      'month_short_may','month_short_jun','month_short_jul','month_short_aug',
      'month_short_sep','month_short_oct','month_short_nov','month_short_dec',
    ];
    return Translations.get(lang, keys[m - 1]);
  }

  @override
  void initState() {
    super.initState();
    _expanded.add(_dateKey(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    if (widget.logs.isEmpty) {
      return _EmptyState(
        icon: Icons.monitor_heart_outlined,
        text: Translations.get(lang, 'no_symptoms_7d'),
      );
    }

    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day - i));

    final logsByDay = <String, Map<String, dynamic>>{};
    for (final l in widget.logs) {
      final d = (l['date'] as Timestamp).toDate();
      logsByDay[_dateKey(d)] = l;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _SectionHeader(title: Translations.get(lang, 'by_day')),
        const SizedBox(height: 12),
        ...days.map((day) {
          final key = _dateKey(day);
          final log = logsByDay[key];
          final isToday = key == _dateKey(now);
          final isExpanded = _expanded.contains(key);
          final hasData = log != null;

          final symptoms = hasData
              ? Map<String, dynamic>.from(log['symptoms'] ?? {})
              : <String, dynamic>{};
          final ai = hasData ? log['aiAnalysis'] as Map<String, dynamic>? : null;
          final risk = ai?['risk'] as String?;
          final riskColor = risk == 'high'
              ? Colors.red
              : risk == 'medium'
                  ? Colors.orange
                  : Colors.green;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                if (isExpanded) {
                  _expanded.remove(key);
                } else {
                  _expanded.add(key);
                }
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday ? AppColors.primary.withOpacity(0.4) : AppColors.divider,
                    width: isToday ? 1.5 : 0.5,
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isToday ? AppColors.primaryLight : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isToday ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _monthShort(day.month, lang),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isToday ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            isToday ? Translations.get(lang, 'today') : _dayLabel(day, lang),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isToday ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (!hasData)
                            Text(Translations.get(lang, 'not_logged'),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
                          else if (symptoms.isEmpty)
                            Text(Translations.get(lang, 'no_symptoms_recorded'),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
                          else
                            Wrap(
                              spacing: 4,
                              children: symptoms.entries.take(3).map((e) {
                                final v = (e.value as num).toInt();
                                final c = v <= 2
                                    ? Colors.green
                                    : v <= 3
                                        ? Colors.orange
                                        : Colors.red;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: c.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('${e.key} $v',
                                      style: TextStyle(
                                          fontSize: 10, fontWeight: FontWeight.w600, color: c)),
                                );
                              }).toList(),
                            ),
                        ]),
                      ),
                      if (risk != null)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(risk.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700, color: riskColor)),
                        ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ]),
                  ),
                  if (isExpanded && hasData) ...[
                    Divider(height: 1, color: AppColors.divider),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _SymptomCardExpanded(log: log),
                    ),
                  ],
                ]),
              ),
            ),
          );
        }),

        const SizedBox(height: 28),
        _SectionHeader(title: Translations.get(lang, 'trends_7_days')),
        const SizedBox(height: 12),
        _SymptomAvgChart(logs: widget.logs),
      ],
    );
  }
}

// ─── SYMPTOM CARD EXPANDED ────────────────────────────────────────────────────

class _SymptomCardExpanded extends StatelessWidget {
  final Map<String, dynamic> log;
  const _SymptomCardExpanded({required this.log});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    final symptoms = Map<String, dynamic>.from(log['symptoms'] ?? {});
    final mood = log['mood'] as String? ?? '';
    final notes = log['notes'] as String? ?? '';
    final ai = log['aiAnalysis'] as Map<String, dynamic>?;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (symptoms.isNotEmpty) ...[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: symptoms.entries
              .map((e) => _SymptomChip(name: e.key, value: e.value as int))
              .toList(),
        ),
        const SizedBox(height: 12),
      ],
      if (mood.isNotEmpty)
        Row(children: [
          const Icon(Icons.mood, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('${Translations.get(lang, 'mood_prefix')}$mood',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ]),
      if (notes.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(notes,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
      ],
      if (ai?['summary'] != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.auto_awesome, size: 13, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(Translations.get(lang, 'ai_analysis_short'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ]),
            const SizedBox(height: 6),
            Text(ai!['summary'] ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4)),
          ]),
        ),
      ],
    ]);
  }
}

// ─── SYMPTOM CHIP ─────────────────────────────────────────────────────────────

class _SymptomChip extends StatelessWidget {
  final String name;
  final int value;
  const _SymptomChip({required this.name, required this.value});

  Color get _color {
    if (value <= 2) return Colors.green;
    if (value <= 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text('$name · $value/5',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _color)),
    );
  }
}

// ─── AVG SEVERITY CHART ───────────────────────────────────────────────────────

class _SymptomAvgChart extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  const _SymptomAvgChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));

    final values = days.map((day) {
      final match = logs.where((l) {
        final d = (l['date'] as Timestamp).toDate();
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).toList();
      if (match.isEmpty) return -1.0;
      final symptoms = match.first['symptoms'] as Map? ?? {};
      if (symptoms.isEmpty) return -1.0;
      final nums = symptoms.values.map((v) => (v as num).toDouble()).toList();
      return nums.reduce((a, b) => a + b) / nums.length;
    }).toList();

    final filled = values.where((v) => v >= 0).toList();
    String? trend;
    if (filled.length >= 2) {
      final diff = filled.last - filled.first;
      if (diff > 0.3) {
        trend = Translations.get(lang, 'trend_worse');
      } else if (diff < -0.3) {
        trend = Translations.get(lang, 'trend_improving');
      } else {
        trend = Translations.get(lang, 'trend_stable');
      }
    }
    final trendColor = trend == null
        ? AppColors.textSecondary
        : trend.startsWith('↑')
            ? Colors.red
            : trend.startsWith('↓')
                ? Colors.green
                : AppColors.textSecondary;

    final weekDays = [
      Translations.get(lang, 'weekday_short_mo'), Translations.get(lang, 'weekday_short_tu'),
      Translations.get(lang, 'weekday_short_we'), Translations.get(lang, 'weekday_short_th'),
      Translations.get(lang, 'weekday_short_fr'), Translations.get(lang, 'weekday_short_sa'),
      Translations.get(lang, 'weekday_short_su'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(Translations.get(lang, 'avg_severity'),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          if (trend != null)
            Text(trend,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: trendColor)),
        ]),
        const SizedBox(height: 4),
        Text(Translations.get(lang, 'avg_severity_subtitle'),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final v = values[i];
              final hasData = v >= 0;
              final isToday = i == 6;
              final barHeight = hasData ? (v / 5) * 80 : 4.0;
              final color = !hasData
                  ? AppColors.divider
                  : v <= 2
                      ? Colors.green
                      : v <= 3
                          ? Colors.orange
                          : Colors.red;
              final dayLabel = weekDays[days[i].weekday - 1];

              return Expanded(
                child: Column(children: [
                  Text(
                    hasData ? v.toStringAsFixed(1) : '—',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: hasData ? color : AppColors.divider,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 450),
                        width: isToday ? 26 : 20,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: hasData
                              ? color.withOpacity(isToday ? 1.0 : 0.65)
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isToday && hasData
                              ? [
                                  BoxShadow(
                                      color: color.withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isToday ? Translations.get(lang, 'today') : dayLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      color: isToday ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ]),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _dot(Colors.green, Translations.get(lang, 'severity_mild')),
          const SizedBox(width: 12),
          _dot(Colors.orange, Translations.get(lang, 'severity_moderate')),
          const SizedBox(width: 12),
          _dot(Colors.red, Translations.get(lang, 'severity_severe')),
        ]),
      ]),
    );
  }

  Widget _dot(Color color, String label) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]);
  }
}

// ─── FOOD TAB ─────────────────────────────────────────────────────────────────

class _FoodTab extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  const _FoodTab({required this.meals});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    if (meals.isEmpty) {
      return _EmptyState(
          icon: Icons.restaurant_outlined,
          text: Translations.get(lang, 'no_meals_7d'));
    }

    final now = DateTime.now();
    final todayMeals = meals.where((m) {
      final d = (m['date'] as Timestamp).toDate();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();

    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));
    final caloriesPerDay = days.map((day) {
      final dayMeals = meals.where((m) {
        final d = (m['date'] as Timestamp).toDate();
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).toList();
      if (dayMeals.isEmpty) return -1.0;
      return dayMeals.fold(
          0.0, (sum, m) => sum + ((m['calories'] as num?)?.toDouble() ?? 0));
    }).toList();

    final todayCalories =
        todayMeals.fold(0.0, (s, m) => s + ((m['calories'] as num?)?.toDouble() ?? 0));
    final todayProtein =
        todayMeals.fold(0.0, (s, m) => s + ((m['protein'] as num?)?.toDouble() ?? 0));
    final todayCarbs =
        todayMeals.fold(0.0, (s, m) => s + ((m['carbs'] as num?)?.toDouble() ?? 0));
    final todayFat =
        todayMeals.fold(0.0, (s, m) => s + ((m['fat'] as num?)?.toDouble() ?? 0));

    final weekDays = [
      Translations.get(lang, 'weekday_short_mo'), Translations.get(lang, 'weekday_short_tu'),
      Translations.get(lang, 'weekday_short_we'), Translations.get(lang, 'weekday_short_th'),
      Translations.get(lang, 'weekday_short_fr'), Translations.get(lang, 'weekday_short_sa'),
      Translations.get(lang, 'weekday_short_su'),
    ];
    final maxCal =
        caloriesPerDay.where((v) => v >= 0).fold(0.0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(title: Translations.get(lang, 'today')),
        const SizedBox(height: 12),
        if (todayMeals.isEmpty)
          _InfoCard(
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.orange,
              text: Translations.get(lang, 'patient_no_meals_today'))
        else ...[
          Row(children: [
            _NutrientBox(
                label: Translations.get(lang, 'calories_label'),
                value: '${todayCalories.toInt()}',
                unit: Translations.get(lang, 'calories'),
                color: const Color(0xFFFF9800)),
            const SizedBox(width: 8),
            _NutrientBox(
                label: Translations.get(lang, 'protein'),
                value: '${todayProtein.toInt()}',
                unit: Translations.get(lang, 'grams'),
                color: const Color(0xFFE53935)),
            const SizedBox(width: 8),
            _NutrientBox(
                label: Translations.get(lang, 'carbs'),
                value: '${todayCarbs.toInt()}',
                unit: Translations.get(lang, 'grams'),
                color: Colors.green),
            const SizedBox(width: 8),
            _NutrientBox(
                label: Translations.get(lang, 'fat'),
                value: '${todayFat.toInt()}',
                unit: Translations.get(lang, 'grams'),
                color: AppColors.primary),
          ]),
          const SizedBox(height: 12),
          ...todayMeals.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MealRow(meal: m, lang: lang),
              )),
        ],
        const SizedBox(height: 24),
        _SectionHeader(title: Translations.get(lang, 'calories_7d_title')),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = caloriesPerDay[i];
                final hasData = v >= 0;
                final barH = hasData && maxCal > 0 ? (v / maxCal) * 72 : 4.0;
                final dayLabel = weekDays[days[i].weekday - 1];
                return Expanded(
                  child: Column(children: [
                    Text(hasData ? '${v.toInt()}' : '—',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: hasData
                                ? const Color(0xFFFF9800)
                                : AppColors.divider)),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 22,
                          height: barH,
                          decoration: BoxDecoration(
                            color: hasData
                                ? const Color(0xFFFF9800).withOpacity(0.8)
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(dayLabel,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                  ]),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _NutrientBox extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _NutrientBox(
      {required this.label,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(unit, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final Map<String, dynamic> meal;
  final AppLanguage lang;
  const _MealRow({required this.meal, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(meal['name'] ?? '',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            Text(meal['type'] ?? '',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
        Text('${meal['calories'] ?? 0} ${Translations.get(lang, 'calories')}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF9800))),
      ]),
    );
  }
}

// ─── REMINDERS TAB ────────────────────────────────────────────────────────────

class _RemindersTab extends StatelessWidget {
  final List<Map<String, dynamic>> reminders;
  const _RemindersTab({required this.reminders});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    if (reminders.isEmpty) {
      return _EmptyState(
          icon: Icons.notifications_none_outlined,
          text: Translations.get(lang, 'no_reminders_set'));
    }

    final completed = reminders.where((r) => r['completed'] == true).length;
    final total = reminders.length;
    final percent = total > 0 ? completed / total : 0.0;
    final color = percent >= 0.7
        ? Colors.green
        : percent >= 0.4
            ? Colors.orange
            : Colors.red;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(Translations.get(lang, 'completed_today'),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              Text('$completed / $total',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        ...reminders.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ReminderRow(reminder: r),
            )),
      ],
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final Map<String, dynamic> reminder;
  const _ReminderRow({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final done = reminder['completed'] == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 20,
          color: done ? Colors.green : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reminder['title'] ?? '',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: done ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null)),
            Text(reminder['type'] ?? '',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
        Text(reminder['time'] ?? '',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }
}

// ─── SHARED ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      if (subtitle != null) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(subtitle!,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange)),
        ),
      ],
    ]);
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  const _InfoCard({required this.icon, required this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13, color: iconColor, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 48, color: AppColors.divider),
        const SizedBox(height: 16),
        Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _MessageTab extends StatefulWidget {
  final String patientId;
  const _MessageTab({required this.patientId});

  @override
  State<_MessageTab> createState() => _MessageTabState();
}

class _MessageTabState extends State<_MessageTab> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    await FirestoreService.sendMessageToPatient(widget.patientId, text);
    _controller.clear();
    if (mounted) setState(() => _sending = false);
    if (mounted) {
      final lang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.get(lang, 'message_sent'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Translations.get(lang, 'send_message_to_patient'),
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: Translations.get(lang, 'message_hint'),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(Translations.get(lang, 'send_btn'),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}