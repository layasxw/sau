import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
    final name = widget.patient['fullName'] ?? 'Patient';
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
            Text('$age y.o. • $gender',
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
          tabs: const [
            Tab(text: 'Symptoms'),
            Tab(text: 'Nutrition'),
            Tab(text: 'Reminders'),
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

  String _dayLabel(DateTime d) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[d.weekday - 1];
  }

  String _monthShort(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  @override
  void initState() {
    super.initState();
    _expanded.add(_dateKey(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.logs.isEmpty) {
      return const _EmptyState(
        icon: Icons.monitor_heart_outlined,
        text: 'No symptoms logged in the last 7 days',
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
        const _SectionHeader(title: 'By Day'),
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
                            _monthShort(day.month),
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
                            isToday ? 'Today' : _dayLabel(day),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isToday ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (!hasData)
                            const Text('Not logged',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                          else if (symptoms.isEmpty)
                            const Text('No symptoms recorded',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
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
        const _SectionHeader(title: 'Trends — Last 7 Days'),
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
          Text('Mood: $mood',
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
            const Row(children: [
              Icon(Icons.auto_awesome, size: 13, color: AppColors.primary),
              SizedBox(width: 6),
              Text('AI Analysis',
                  style: TextStyle(
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
        trend = '↑ Getting worse';
      } else if (diff < -0.3) {
        trend = '↓ Improving';
      } else {
        trend = '→ Stable';
      }
    }
    final trendColor = trend == null
        ? AppColors.textSecondary
        : trend.startsWith('↑')
            ? Colors.red
            : trend.startsWith('↓')
                ? Colors.green
                : AppColors.textSecondary;

    const weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Average Severity',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          if (trend != null)
            Text(trend,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: trendColor)),
        ]),
        const SizedBox(height: 4),
        const Text('Mean score across all symptoms · last 7 days',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                    isToday ? 'Today' : dayLabel,
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
          _dot(Colors.green, '1–2 Mild'),
          const SizedBox(width: 12),
          _dot(Colors.orange, '3 Moderate'),
          const SizedBox(width: 12),
          _dot(Colors.red, '4–5 Severe'),
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
    if (meals.isEmpty) {
      return const _EmptyState(
          icon: Icons.restaurant_outlined,
          text: 'No meals logged in the last 7 days');
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

    const weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final maxCal =
        caloriesPerDay.where((v) => v >= 0).fold(0.0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionHeader(title: 'Today'),
        const SizedBox(height: 12),
        if (todayMeals.isEmpty)
          const _InfoCard(
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.orange,
              text: 'Patient has not logged meals today')
        else ...[
          Row(children: [
            _NutrientBox(
                label: 'Calories',
                value: '${todayCalories.toInt()}',
                unit: 'kcal',
                color: const Color(0xFFFF9800)),
            const SizedBox(width: 8),
            _NutrientBox(
                label: 'Protein',
                value: '${todayProtein.toInt()}',
                unit: 'g',
                color: const Color(0xFFE53935)),
            const SizedBox(width: 8),
            _NutrientBox(
                label: 'Carbs',
                value: '${todayCarbs.toInt()}',
                unit: 'g',
                color: Colors.green),
            const SizedBox(width: 8),
            _NutrientBox(
                label: 'Fat',
                value: '${todayFat.toInt()}',
                unit: 'g',
                color: AppColors.primary),
          ]),
          const SizedBox(height: 12),
          ...todayMeals.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MealRow(meal: m),
              )),
        ],
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Calories — Last 7 Days'),
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
  const _MealRow({required this.meal});

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
        Text('${meal['calories'] ?? 0} kcal',
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
    if (reminders.isEmpty) {
      return const _EmptyState(
          icon: Icons.notifications_none_outlined,
          text: 'Patient has no reminders set');
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
              const Text('Completed today',
                  style: TextStyle(
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