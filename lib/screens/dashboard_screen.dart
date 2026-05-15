import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/language_provider.dart';
import 'package:provider/provider.dart';
import '../l10n/translations.dart';
import '../services/api_config.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _fullName;
  String? _diagnosis;
  int _remindersCount = 0;
  Map<String, dynamic>? _aiData;
  bool _aiLoading = false;

  // Motivation card state
  DateTime? _surgeryDate;
  bool _todayHasFood = false;
  bool _todaySymptomsHigh = false;
  bool _todayHasSymptoms = false;
  bool _cardLoading = true;
  String? _doctorMessage;

  void _go(int i) => widget.onNavigate?.call(i);

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  dynamic _toJson(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) return value.map((k, v) => MapEntry(k, _toJson(v)));
    if (value is List) return value.map((v) => _toJson(v)).toList();
    return value;
  }

  Future<void> _loadInfo() async {
    final results = await Future.wait([
      FirestoreService.getUserProfile(),
      FirestoreService.getMedicalProfile(),
      FirestoreService.getReminders(),
    ]);

    final profile   = results[0] as Map<String, dynamic>?;
    final medical   = results[1] as Map<String, dynamic>?;
    final reminders = results[2] as List<Map<String, dynamic>>;

    // surgery date
    DateTime? surgeryDate;
    final raw = medical?['surgeryDate'];
    if (raw is Timestamp) surgeryDate = raw.toDate();

    setState(() {
      _fullName       = profile?['fullName'] as String?;
      _diagnosis      = medical?['diagnosis'] as String?;
      _remindersCount = reminders.length;
      _surgeryDate    = surgeryDate;
    });

    final messages = await FirestoreService.getMyMessages();
    if (messages.isNotEmpty) {
      setState(() => _doctorMessage = messages.first['text'] as String?);
    }

    await _loadMotivationData();
  }

  Future<void> _loadMotivationData() async {
    setState(() => _cardLoading = true);
    try {
      final results = await Future.wait([
        FirestoreService.getSymptoms(),
        FirestoreService.getMeals(),
      ]);

      final symptoms = results[0] as List<Map<String, dynamic>>;
      final meals    = results[1] as List<Map<String, dynamic>>;

      final todayMeals = meals.where((m) {
        final date = (m['date'] as Timestamp?)?.toDate();
        return date != null && _isToday(date);
      }).toList();

      final todaySymptoms = symptoms.where((s) {
        final date = (s['date'] as Timestamp?)?.toDate();
        return date != null && _isToday(date);
      }).toList();

      // симптомы высокие если avg severity > 3
      bool symptomsHigh = false;
      if (todaySymptoms.isNotEmpty) {
        final allSeverities = <int>[];
        for (final s in todaySymptoms) {
          final syms = s['symptoms'] as Map<String, dynamic>? ?? {};
          for (final v in syms.values) {
            allSeverities.add((v as num).toInt());
          }
        }
        if (allSeverities.isNotEmpty) {
          final avg = allSeverities.reduce((a, b) => a + b) / allSeverities.length;
          symptomsHigh = avg > 3;
        }
      }

      setState(() {
        _todayHasFood      = todayMeals.isNotEmpty;
        _todayHasSymptoms  = todaySymptoms.isNotEmpty;
        _todaySymptomsHigh = symptomsHigh;
      });
    } catch (e) {
      debugPrint('Motivation card error: $e');
    } finally {
      setState(() => _cardLoading = false);
    }
  }

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _getTodayLabel(AppLanguage lang) {
    final n = DateTime.now();
    final Map<AppLanguage, List<String>> days = {
      AppLanguage.en: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      AppLanguage.ru: ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'],
      AppLanguage.kk: ['Дүйсенбі', 'Сейсенбі', 'Сәрсенбі', 'Бейсенбі', 'Жұма', 'Сенбі', 'Жексенбі'],
    };
    final Map<AppLanguage, List<String>> months = {
      AppLanguage.en: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
      AppLanguage.ru: ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'],
      AppLanguage.kk: ['қаңтар', 'ақпан', 'наурыз', 'сәуір', 'мамыр', 'маусым', 'шілде', 'тамыз', 'қыркүйек', 'қазан', 'қараша', 'желтоқсан'],
    };
    final d = days[lang]![n.weekday - 1];
    final m = months[lang]![n.month - 1];
    if (lang == AppLanguage.en) return '$d, $m ${n.day}';
    return '$d, ${n.day} $m';
  }

  // логика фразы для карточки
  String _getMotivationPhrase(AppLanguage lang) {
    if (_todaySymptomsHigh) return Translations.get(lang, 'motivation_care');
    if (_todayHasFood && _todayHasSymptoms) return Translations.get(lang, 'motivation_great');
    if (_todayHasFood && !_todayHasSymptoms) return Translations.get(lang, 'motivation_log_symptoms');
    return Translations.get(lang, 'motivation_how_feeling');
  }

  String? _getRehabDaysText(AppLanguage lang) {
    if (_surgeryDate == null) return null;
    final days = DateTime.now().difference(_surgeryDate!).inDays;
    if (days < 0) return null;
    return '${Translations.get(lang, 'rehab_day')} $days';
  }

  Future<void> _analyzeRecovery() async {
    setState(() => _aiLoading = true);
    try {
      final results = await Future.wait([
        FirestoreService.getUserProfile(),
        FirestoreService.getMedicalProfile(),
        FirestoreService.getSymptoms(),
        FirestoreService.getMeals(),
      ]);

      final profile  = results[0] as Map<String, dynamic>?;
      final medical  = results[1] as Map<String, dynamic>?;
      final symptoms = results[2] as List<Map<String, dynamic>>;
      final meals    = results[3] as List<Map<String, dynamic>>;

      final response = await http.post(
        Uri.parse(ApiConfig.analyzeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'profile':          _toJson(profile),
          'medical':          _toJson(medical),
          'recent_symptoms':  _toJson(symptoms.take(5).toList()),
          'recent_meals':     _toJson(meals.take(5).toList()),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] != null) {
          debugPrint('AI returned error: ${data['raw']}');
          return;
        }
        setState(() => _aiData = data);
      }
    } catch (e) {
      debugPrint('AI error: $e');
    } finally {
      setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(lang),
              const SizedBox(height: 24),
              _buildMotivationCard(lang),
              if (_doctorMessage != null) ...[
                const SizedBox(height: 16),
                _buildDoctorMessage(lang),
              ],
              const SizedBox(height: 24),
              _buildHealthStatus(lang),
              const SizedBox(height: 24),
              _buildAIInsights(lang),
              const SizedBox(height: 24),
              _buildQuickActionsTitle(lang),
              const SizedBox(height: 16),
              _buildQuickActions(lang),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppLanguage lang) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${Translations.get(lang, 'hello')} ${_fullName?.split(' ')[0] ?? ''}!',
                  style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 4),
              Text(_getTodayLabel(lang), style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          _CircleIconButton(icon: CupertinoIcons.bell, onTap: () => _go(1)),
        ],
      ),
    ],
  );

  Widget _buildMotivationCard(AppLanguage lang) {
    if (_cardLoading) return _LoadingCard();
    return _BouncingWrapper(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTodayLabel(lang),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_getRehabDaysText(lang) != null)
                  Text(
                    _getRehabDaysText(lang)!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _getMotivationPhrase(lang),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatus(AppLanguage lang) => Row(
    children: [
      Expanded(child: _HealthCard(
        label: Translations.get(lang, 'nav_reminders'),
        value: '$_remindersCount',
        icon: CupertinoIcons.calendar,
        color: const Color(0xFF6366F1),
        onTap: () => _go(1),
      )),
      const SizedBox(width: 16),
      Expanded(child: _HealthCard(
        label: Translations.get(lang, 'nav_symptoms'),
        value: _diagnosis ?? '—',
        icon: CupertinoIcons.heart_fill,
        color: const Color(0xFFF43F5E),
        onTap: () {},
      )),
    ],
  );

  Widget _buildAIInsights(AppLanguage lang) {
    final risk = _aiData?['risk'] as String?;
    final riskColor = risk == 'high'
        ? AppColors.accent
        : risk == 'medium' ? Colors.orange : Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => AppGradients.primary.createShader(bounds),
                      child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(Translations.get(lang, 'ai_recovery_insights'),
                        style: Theme.of(context).textTheme.titleLarge)),
                    if (risk != null) _Badge(label: risk.toUpperCase(), color: riskColor),
                  ],
                ),
                const SizedBox(height: 8),
                Text(Translations.get(lang, 'ai_analysis_desc'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                if (_aiData != null) ...[
                  const SizedBox(height: 20),
                  _AIInsightRow(icon: CupertinoIcons.graph_circle,
                      label: Translations.get(lang, 'optimization'), text: _aiData!['status'] ?? Translations.get(lang, 'ai_analyzing')),
                  _AIInsightRow(icon: CupertinoIcons.exclamationmark_triangle,
                      label: Translations.get(lang, 'concerns'), text: _aiData!['concerns'] ?? Translations.get(lang, 'ai_no_concerns')),
                  const SizedBox(height: 8),
                  Text(
                    Translations.get(lang, 'medical_advice_disclaimer'),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: _BouncingWrapper(
              onTap: _aiLoading ? null : _analyzeRecovery,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _aiLoading ? null : AppGradients.primary,
                  color: _aiLoading ? AppColors.textSecondary.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _aiLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : Text(Translations.get(lang, 'update_insights'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsTitle(AppLanguage lang) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(Translations.get(lang, 'quick_actions'), style: Theme.of(context).textTheme.headlineMedium),
        TextButton(onPressed: () {}, child: Text(Translations.get(lang, 'view_all'),
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
      ],
    ),
  );

  Widget _buildQuickActions(AppLanguage lang) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    childAspectRatio: 1.5,
    children: [
      _ActionCard(icon: CupertinoIcons.add,               label: Translations.get(lang, 'log_meal'),     color: const Color(0xFF10B981).withOpacity(0.1), iconColor: const Color(0xFF10B981), onTap: () => _go(2)),
      _ActionCard(icon: CupertinoIcons.waveform_path_ecg, label: Translations.get(lang, 'log_symptom'),  color: const Color(0xFF6366F1).withOpacity(0.1), iconColor: const Color(0xFF6366F1), onTap: () => _go(3)),
      _ActionCard(icon: CupertinoIcons.bell,              label: Translations.get(lang, 'add_reminder'), color: const Color(0xFFF59E0B).withOpacity(0.1), iconColor: const Color(0xFFF59E0B), onTap: () => _go(1)),
      _ActionCard(icon: CupertinoIcons.chart_bar_square,  label: Translations.get(lang, 'view_trends'),  color: const Color(0xFFEC4899).withOpacity(0.1), iconColor: const Color(0xFFEC4899), onTap: () => _go(3)),
    ],
  );

  Widget _buildDoctorMessage(AppLanguage lang) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.chat_bubble_2_fill, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Text(Translations.get(lang, 'doctor_message_title'),
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        Text(_doctorMessage!, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
      ],
    ),
  );
}

// ── Components ────────────────────────────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HealthCard({required this.label, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => _BouncingWrapper(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}

class _AIInsightRow extends StatelessWidget {
  final IconData icon;
  final String label, text;
  const _AIInsightRow({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, iconColor;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) => _BouncingWrapper(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: iconColor)),
        ],
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
  );
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => _BouncingWrapper(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 20),
    ),
  );
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
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => widget.onTap != null ? _controller.forward() : null,
    onTapUp: (_) { if (widget.onTap != null) { _controller.reverse(); widget.onTap!(); HapticFeedback.lightImpact(); } },
    onTapCancel: () => _controller.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      );
}