import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/language_provider.dart';
import 'package:provider/provider.dart';
import '../l10n/translations.dart';
import '../services/api_config.dart';

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// HELPER FUNCTION вЂ” converts a type string into icon + colors
// Lives outside all classes because it's just a pure utility function.
// Can't save IconData to Firestore, so we store the type string ("Medication")
// and convert it back to an icon every time we load from Firestore.
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
({IconData icon, Color bg, Color color}) _iconForType(String type) {
  switch (type) {
    case 'Medication':
      return (icon: Icons.medication_outlined,      bg: Color(0xFFEDE7F6), color: Color(0xFF7E57C2));
    case 'Doctor appointment':
      return (icon: Icons.local_hospital_outlined,  bg: Color(0xFFFFEBEE), color: Color(0xFFE53935));
    case 'Lab test':
      return (icon: Icons.science_outlined,         bg: Color(0xFFFFF3E0), color: Color(0xFFFF9800));
    case 'Physical activity':
      return (icon: Icons.directions_run,           bg: Color(0xFFE8F5E9), color: Colors.green);
    case 'Dietary':
      return (icon: Icons.restaurant_menu_outlined, bg: Color(0xFFE8F7F6), color: AppColors.primary);
    case 'Sleep':
      return (icon: Icons.bedtime_outlined,         bg: Color(0xFFE8F7F6), color: AppColors.primary);
    default:
      return (icon: Icons.notifications_outlined,   bg: Color(0xFFF0F4F5), color: AppColors.textSecondary);
  }
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// DATA MODEL
// Represents one reminder in memory (not in Firestore вЂ” that's a Map).
// type is stored so we can save it to Firestore and recreate icons on load.
// id comes from Firestore document id вЂ” needed for delete and update.
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _Reminder {
  final String id;
  final String type;
  final IconData icon;
  final Color iconBg, iconColor;
  String title, recurrence, time, description;
  DateTime? onceDate;
  bool hasAiBadge, completed;

  _Reminder({
    required this.id,
    required this.type,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.recurrence,
    required this.time,
    required this.description,
    this.onceDate,
    this.hasAiBadge = false,
    this.completed = false,
  });
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// SCREEN
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  // _items holds all reminders loaded from Firestore.
  // Starts empty вЂ” filled by _loadReminders() in initState.
  List<_Reminder> _items = [];
  int _filter = 0;
  static const _filterKeys = ['filter_all', 'filter_today', 'filter_upcoming', 'filter_completed'];
  List<Map<String, dynamic>> _suggestedReminders = [];
  bool _suggestionsLoading = false;
  // _visible is a getter вЂ” it re-filters _items every time build() runs.
  // A getter is like a variable that computes its value on demand.
  List<_Reminder> get _visible {
    switch (_filter) {
      case 1:
      case 2:
        return _items.where((r) => !r.completed).toList();
      case 3:
        return _items.where((r) => r.completed).toList();
      default:
        return _items;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReminders(); // load from Firestore as soon as screen opens
    _loadSuggestions();
  }

  // Fetches all reminders from Firestore and puts them into _items.
  // data comes back as List<Map<String, dynamic>> from FirestoreService.
  // We convert each Map into a _Reminder object so the UI can use it easily.
  Future<void> _loadReminders() async {
    final data = await FirestoreService.getReminders();
    setState(() {
      // No var here вЂ” we're assigning to the class-level _items, not creating new local variable
      _items = data.map((r) {
        final meta = _iconForType(r['type'] ?? 'Other');
        return _Reminder(
          id:          r['id'],
          type:        r['type'] ?? 'Other',
          icon:        meta.icon,
          iconBg:      meta.bg,
          iconColor:   meta.color,
          title:       r['title'] ?? '',
          recurrence:  r['recurrence'] ?? '',
          time:        r['time'] ?? '',
          description: r['description'] ?? '',
          hasAiBadge:  r['hasAiBadge'] ?? false,
          completed:   r['completed'] ?? false,
        );
      }).toList();
    });
  }

  void _showAddSheet() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddSheet(
          onAddMultiple: (reminders) async {
            for (final r in reminders) {
              await FirestoreService.addReminder({
                'title':       r.title,
                'type':        r.type,
                'recurrence':  r.recurrence,
                'time':        r.time,
                'description': r.description,
                'hasAiBadge':  false,
                'completed':   false,
                'createdAt':   FieldValue.serverTimestamp(),
              });
            }
            _loadReminders();
          },
        ),
      );

      Future<void> _loadSuggestions() async {
        setState(() => _suggestionsLoading = true);
        try {
          debugPrint('=== loadSuggestions start ===');
          final cached = await FirestoreService.getTodaySuggestedReminders();
          debugPrint('=== cached: $cached ===');
          if (cached != null && cached.isNotEmpty) {
            setState(() => _suggestedReminders = cached);
            return;
          }
          final symptoms = await FirestoreService.getSymptoms();
          debugPrint('=== symptoms count: ${symptoms.length} ===');
          final meals = await FirestoreService.getMeals();
          debugPrint('=== meals count: ${meals.length} ===');
  
        final now = DateTime.now();

        // null-safe: skip docs without a valid date
        final todaySymptoms = symptoms.where((s) {
          final date = (s['date'] as Timestamp?)?.toDate();
          if (date == null) return false;
          return date.year == now.year && date.month == now.month && date.day == now.day;
        }).toList();

        final todayMeals = meals.where((m) {
          final date = (m['date'] as Timestamp?)?.toDate();
          if (date == null) return false;
          return date.year == now.year && date.month == now.month && date.day == now.day;
        }).toList();

        // Only call AI if there's actually data today
        if (todaySymptoms.isEmpty && todayMeals.isEmpty) return;

        final lang = Provider.of<LanguageProvider>(context, listen: false).languageCode;
        final response = await http.post(
          Uri.parse(ApiConfig.suggestRemindersUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'symptoms': {
              for (var s in todaySymptoms)
                ...Map<String, dynamic>.from(s['symptoms'] ?? {})
            },
            'meals': todayMeals.map((m) => m['name']).toList(),
            'mood': todaySymptoms.isNotEmpty ? todaySymptoms.first['mood'] : null,
            'lang': lang,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          debugPrint('=== suggest-reminders response: $data ==='); // РІСЂРµРјРµРЅРЅРѕ
          final raw = data['reminders'];
          if (raw == null) return; // в†ђ РґРѕР±Р°РІСЊ СЌС‚Рѕ
          final reminders = List<Map<String, dynamic>>.from(raw);
          await FirestoreService.saveSuggestedReminders(reminders);
          setState(() => _suggestedReminders = reminders);
        }
      } catch (e) {
        debugPrint('AI suggestions error: $e');
      } finally {
        setState(() => _suggestionsLoading = false);
      }
    }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    final list = _visible;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(Translations.get(lang, 'nav_reminders'),
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(Translations.get(lang, 'reminders_subtitle'),
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _showAddSheet,
            icon: const Icon(Icons.add, size: 20),
            label: Text(Translations.get(lang, 'add_reminder_btn')),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        if (_suggestionsLoading) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
              Text(Translations.get(lang, 'ai_suggestions_loading'), style: const TextStyle(fontSize: 13, color: AppColors.primary)),
            ]),
          ),
        ] else if (_suggestedReminders.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text(Translations.get(lang, 'ai_suggestions_title'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ]),
              const SizedBox(height: 4),
              Text(Translations.get(lang, 'ai_suggestions_desc'),
                  style: const TextStyle(fontSize: 12, color: AppColors.primary)),
              const SizedBox(height: 12),
              ..._suggestedReminders.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r['title'] ?? '', style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(r['description'] ?? '', style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                  ])),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await FirestoreService.addReminder({
                        'title': r['title'],
                        'type': 'Other',
                        'recurrence': 'Once',
                        'time': '09:00',
                        'description': r['description'],
                        'hasAiBadge': true,
                        'completed': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      setState(() => _suggestedReminders.remove(r));
                      _loadReminders();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(Translations.get(lang, 'add_btn'), style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ]),
              )),
              const SizedBox(height: 12),
              Text(
                Translations.get(lang, 'medical_advice_disclaimer'),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: List.generate(_filterKeys.length, (i) {
            final sel = i == _filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                        color: sel ? AppColors.primary : AppColors.divider),
                  ),
                  child: Text(Translations.get(lang, _filterKeys[i]),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              sel ? Colors.white : AppColors.textPrimary)),
                ),
              ),
            );
          })),
        ),
        const SizedBox(height: 24),
        if (list.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.notifications_off_outlined,
                  size: 48, color: AppColors.divider),
              const SizedBox(height: 12),
              Text(Translations.get(lang, 'no_reminders'),
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textSecondary)),
            ]),
          )
        else
          ...list.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _Card(
                  item: r,
                  // Delete: remove from Firestore first, then update UI
                  onDelete: () async {
                    await FirestoreService.deleteReminder(r.id);
                    setState(() => _items.remove(r));
                  },
                  // Toggle: update the completed field in Firestore, then update UI
                  onToggle: () async {
                    await FirestoreService.updateReminderCompleted(
                        r.id, !r.completed);
                    setState(() => r.completed = !r.completed);
                  },
                ),
              )),
      ]),
    );
  }
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// REMINDER CARD
// A StatelessWidget вЂ” receives a _Reminder and two callbacks.
// Doesn't know anything about Firestore. Just displays data and calls callbacks.
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _Card extends StatelessWidget {
  final _Reminder item;
  final VoidCallback onDelete, onToggle;
  const _Card(
      {required this.item, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: item.completed ? 0.5 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16)),
          child:
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: item.completed
                          ? const Color(0xFFE8F5E9)
                          : item.iconBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                      item.completed
                          ? Icons.check_circle_outline
                          : item.icon,
                      color:
                          item.completed ? Colors.green : item.iconColor,
                      size: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(item.title,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                decoration: item.completed
                                    ? TextDecoration.lineThrough
                                    : null))),
                    if (item.hasAiBadge)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    AppColors.primary.withOpacity(0.25))),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 12, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('AI',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                            ]),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline,
                            size: 20, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                            item.recurrence == 'Once' && item.onceDate != null
                                ? 'Once В· ${item.onceDate!.day.toString().padLeft(2, '0')}.${item.onceDate!.month.toString().padLeft(2, '0')}.${item.onceDate!.year}'
                                : item.recurrence,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary))),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(item.time,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 6),
                  Text(item.description,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.45)),
                ])),
          ]),
        ),
      );
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// ADD REMINDER SHEET вЂ” supports multiple daily doses for medications
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _AddSheet extends StatefulWidget {
  final void Function(List<_Reminder>) onAddMultiple;
  const _AddSheet({required this.onAddMultiple});
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _title = TextEditingController();
  final _desc  = TextEditingController();
  String _type = 'Medication', _rec = 'Daily';
  DateTime? _onceDate;

  // Multi-dose state: 1 to 4 times per day
  int _timesPerDay = 1;
  // Parallel list of times for each dose
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];

  static const _types = [
    'Medication', 'Doctor appointment', 'Lab test',
    'Physical activity', 'Dietary', 'Sleep', 'Other'
  ];
  static const _recKeys = ['recurrence_once', 'recurrence_daily', 'recurrence_weekly', 'recurrence_monthly'];
  static const _recs    = ['Once', 'Daily', 'Weekly', 'Monthly'];

  // Default time presets for each dose count (index 0 = 1x/day, etc.)
  static const _defaultTimes = [
    [TimeOfDay(hour: 8, minute: 0)],
    [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 0)],
    [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 20, minute: 0)],
    [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 12, minute: 0), TimeOfDay(hour: 17, minute: 0), TimeOfDay(hour: 21, minute: 0)],
  ];

  static const _commonMeds = [
    'Omeprazole',
    'Pantoprazole',
    'Ondansetron (Zofran)',
    'Metoclopramide (Reglan)',
    'Ibuprofen',
    'Paracetamol / Acetaminophen',
    'Vitamin D3',
    'Iron Supplements',
    'Digestive Enzymes',
    'Other (enter manually)'
  ];
  String? _selectedMed;

  static const _meta = {
    'Medication':         (Icons.medication_outlined,      Color(0xFFEDE7F6), Color(0xFF7E57C2)),
    'Doctor appointment': (Icons.local_hospital_outlined,  Color(0xFFFFEBEE), Color(0xFFE53935)),
    'Lab test':           (Icons.science_outlined,         Color(0xFFFFF3E0), Color(0xFFFF9800)),
    'Physical activity':  (Icons.directions_run,           Color(0xFFE8F5E9), Colors.green),
    'Dietary':            (Icons.restaurant_menu_outlined, Color(0xFFE8F7F6), AppColors.primary),
    'Sleep':              (Icons.bedtime_outlined,         Color(0xFFE8F7F6), AppColors.primary),
    'Other':              (Icons.notifications_outlined,   Color(0xFFF0F4F5), AppColors.textSecondary),
  };

  void _setTimesPerDay(int n) {
    setState(() {
      _timesPerDay = n;
      _times = List<TimeOfDay>.from(_defaultTimes[n - 1]);
      // Auto-set recurrence to Daily for multi-dose
      if (n > 1) _rec = 'Daily';
    });
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked != null) setState(() => _times[index] = picked);
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    final isMed = _type == 'Medication';
    return Container(
        decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          // Drag handle
          Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(Translations.get(lang, 'new_reminder'),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 20),

          // в”Ђв”Ђ Medication picker or text field в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
          Text(Translations.get(lang, 'reminder_title_label'),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          if (isMed) ...[
            DropdownButtonFormField<String>(
              value: _selectedMed,
              decoration: _dec(Translations.get(lang, 'select_medication')),
              isExpanded: true,
              items: _commonMeds
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedMed = v;
                  if (v != null && v != 'Other (enter manually)') {
                    _title.text = v;
                  } else {
                    _title.clear();
                  }
                });
              },
            ),
            if (_selectedMed == 'Other (enter manually)') const SizedBox(height: 8),
          ],
          if (!isMed || _selectedMed == 'Other (enter manually)')
            TextField(
                controller: _title,
                decoration: _dec(isMed
                    ? Translations.get(lang, 'enter_medication')
                    : 'e.g. Morning medication'),
                textCapitalization: TextCapitalization.sentences),
          const SizedBox(height: 16),

          // в”Ђв”Ђ Type в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
          Text(Translations.get(lang, 'type'),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: _dec(''),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() {
                    _type = v!;
                    if (_type != 'Medication') {
                      _selectedMed = null;
                      _title.clear();
                      _timesPerDay = 1;
                      _times = [const TimeOfDay(hour: 8, minute: 0)];
                    }
                  })),
          const SizedBox(height: 16),

          // в”Ђв”Ђ Times per day (medication only) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
          if (isMed) ...[
            Text(Translations.get(lang, 'times_per_day'),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(4, (i) {
                final n = i + 1;
                final sel = n == _timesPerDay;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _setTimesPerDay(n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 56, height: 44,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel ? AppColors.primary : AppColors.divider),
                      ),
                      child: Center(
                        child: Text('${n}Г—',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textSecondary)),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // в”Ђв”Ђ Dose time slots в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
            Text(Translations.get(lang, 'dose_times'),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_timesPerDay, (i) {
                return GestureDetector(
                  onTap: () => _pickTime(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Dose ${i + 1}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(_times[i].format(context),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ]),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],

          // в”Ђв”Ђ Repeat & single time (non-medication) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
          if (!isMed) ...[
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(Translations.get(lang, 'repeat'),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                        initialValue: _rec,
                        decoration: _dec(''),
                        items: List.generate(
                            _recs.length,
                            (i) => DropdownMenuItem(
                                value: _recs[i],
                                child: Text(
                                    Translations.get(lang, _recKeys[i])))),
                        onChanged: (v) => setState(() => _rec = v!)),
                  ])),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(Translations.get(lang, 'time'),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickTime(0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider)),
                        child: Row(children: [
                          const Icon(Icons.access_time,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(_times[0].format(context),
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textPrimary)),
                        ]),
                      ),
                    ),
                  ])),
            ]),
          ],

          // в”Ђв”Ђ Repeat dropdown (medication) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
          if (isMed) ...[
            Text(Translations.get(lang, 'repeat'),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
                initialValue: _rec,
                decoration: _dec(''),
                items: List.generate(
                    _recs.length,
                    (i) => DropdownMenuItem(
                        value: _recs[i],
                        child:
                            Text(Translations.get(lang, _recKeys[i])))),
                onChanged: (v) => setState(() => _rec = v!)),
            const SizedBox(height: 16),
          ],

          // в”Ђв”Ђ Once date picker в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
          if (_rec == 'Once') ...[
            const SizedBox(height: 4),
            Text(Translations.get(lang, 'date'),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _onceDate ?? DateTime.now(),
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 1)),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) setState(() => _onceDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _onceDate == null
                        ? Translations.get(lang, 'select_date')
                        : '${_onceDate!.day.toString().padLeft(2, '0')}.${_onceDate!.month.toString().padLeft(2, '0')}.${_onceDate!.year}',
                    style: TextStyle(
                        fontSize: 15,
                        color: _onceDate == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary),
                  ),
                  const Spacer(),
                  if (_onceDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _onceDate = null),
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.textSecondary),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // в”Ђв”Ђ Notes в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
          Text(Translations.get(lang, 'notes'),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
              controller: _desc, maxLines: 3, decoration: _dec('')),
          const SizedBox(height: 24),

          // в”Ђв”Ђ Save button в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_title.text.trim().isEmpty) return;
                final m = _meta[_type]!;
                final desc = _desc.text.trim().isEmpty
                    ? Translations.get(lang, 'no_notes')
                    : _desc.text.trim();

                // Build one _Reminder per time slot
                final reminders = _times.map((t) => _Reminder(
                  id:          '',
                  type:        _type,
                  icon:        m.$1,
                  iconBg:      m.$2,
                  iconColor:   m.$3,
                  title:       _title.text.trim(),
                  recurrence:  _rec,
                  time:        t.format(context),
                  onceDate:    _rec == 'Once' ? _onceDate : null,
                  description: desc,
                )).toList();

                widget.onAddMultiple(reminders);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0),
              child: Text(Translations.get(lang, 'save_reminder'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ])));
  }
}
