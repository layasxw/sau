import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HELPER FUNCTION — converts a type string into icon + colors
// Lives outside all classes because it's just a pure utility function.
// Can't save IconData to Firestore, so we store the type string ("Medication")
// and convert it back to an icon every time we load from Firestore.
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// Represents one reminder in memory (not in Firestore — that's a Map).
// type is stored so we can save it to Firestore and recreate icons on load.
// id comes from Firestore document id — needed for delete and update.
// ─────────────────────────────────────────────────────────────────────────────
class _Reminder {
  final String id;
  final String type;
  final IconData icon;
  final Color iconBg, iconColor;
  String title, recurrence, time, description;
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
    this.hasAiBadge = false,
    this.completed = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  // _items holds all reminders loaded from Firestore.
  // Starts empty — filled by _loadReminders() in initState.
  List<_Reminder> _items = [];
  int _filter = 0;
  static const _filters = ['All', 'Today', 'Upcoming', 'Completed'];

  // _visible is a getter — it re-filters _items every time build() runs.
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
  }

  // Fetches all reminders from Firestore and puts them into _items.
  // data comes back as List<Map<String, dynamic>> from FirestoreService.
  // We convert each Map into a _Reminder object so the UI can use it easily.
  Future<void> _loadReminders() async {
    final data = await FirestoreService.getReminders();
    setState(() {
      // No var here — we're assigning to the class-level _items, not creating new local variable
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
        // onAdd receives a _Reminder from _AddSheet.
        // We save it to Firestore first, then reload the list.
        builder: (_) => _AddSheet(
          onAdd: (r) async {
            await FirestoreService.addReminder({
              'title':       r.title,
              'type':        r.type,   // type is now available through r.type
              'recurrence':  r.recurrence,
              'time':        r.time,
              'description': r.description,
              'hasAiBadge':  false,
              'completed':   false,
              'createdAt':   FieldValue.serverTimestamp(),
            });
            _loadReminders(); // reload so the new reminder appears
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Reminders',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const Text('Manage your medication, appointments, and daily tasks',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _showAddSheet,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Reminder'),
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
        const SizedBox(height: 16),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: List.generate(_filters.length, (i) {
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
                  child: Text(_filters[i],
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
            child: const Column(children: [
              Icon(Icons.notifications_off_outlined,
                  size: 48, color: AppColors.divider),
              SizedBox(height: 12),
              Text('No reminders here',
                  style: TextStyle(
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

// ─────────────────────────────────────────────────────────────────────────────
// REMINDER CARD
// A StatelessWidget — receives a _Reminder and two callbacks.
// Doesn't know anything about Firestore. Just displays data and calls callbacks.
// ─────────────────────────────────────────────────────────────────────────────
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
                        child: Text(item.recurrence,
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

// ─────────────────────────────────────────────────────────────────────────────
// ADD REMINDER SHEET
// Collects user input and calls onAdd with a _Reminder object.
// Doesn't talk to Firestore directly — that's the screen's job.
// ─────────────────────────────────────────────────────────────────────────────
class _AddSheet extends StatefulWidget {
  final void Function(_Reminder) onAdd;
  const _AddSheet({required this.onAdd});
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _title = TextEditingController();
  final _desc  = TextEditingController();
  String _type = 'Medication', _rec = 'Daily';
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);

  static const _types = [
    'Medication', 'Doctor appointment', 'Lab test',
    'Physical activity', 'Dietary', 'Sleep', 'Other'
  ];
  static const _recs = ['Once', 'Daily', 'Weekly', 'Monthly'];

  // _meta maps type string → (icon, bg color, icon color)
  // Used to set the correct icon when creating the _Reminder object
  static const _meta = {
    'Medication':         (Icons.medication_outlined,      Color(0xFFEDE7F6), Color(0xFF7E57C2)),
    'Doctor appointment': (Icons.local_hospital_outlined,  Color(0xFFFFEBEE), Color(0xFFE53935)),
    'Lab test':           (Icons.science_outlined,         Color(0xFFFFF3E0), Color(0xFFFF9800)),
    'Physical activity':  (Icons.directions_run,           Color(0xFFE8F5E9), Colors.green),
    'Dietary':            (Icons.restaurant_menu_outlined, Color(0xFFE8F7F6), AppColors.primary),
    'Sleep':              (Icons.bedtime_outlined,         Color(0xFFE8F7F6), AppColors.primary),
    'Other':              (Icons.notifications_outlined,   Color(0xFFF0F4F5), AppColors.textSecondary),
  };

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('New Reminder',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          const Text('Title',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
              controller: _title,
              decoration: _dec('e.g. Morning medication'),
              textCapitalization: TextCapitalization.sentences),
          const SizedBox(height: 16),
          const Text('Type',
              style: TextStyle(
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
              onChanged: (v) => setState(() => _type = v!)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Repeat',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                      initialValue: _rec,
                      decoration: _dec(''),
                      items: _recs
                          .map((r) =>
                              DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) => setState(() => _rec = v!)),
                ])),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Time',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final p = await showTimePicker(
                          context: context, initialTime: _time);
                      if (p != null) setState(() => _time = p);
                    },
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
                        Text(_time.format(context),
                            style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary)),
                      ]),
                    ),
                  ),
                ])),
          ]),
          const SizedBox(height: 16),
          const Text('Notes (optional)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
              controller: _desc,
              maxLines: 3,
              decoration: _dec('Any notes about this reminder...')),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_title.text.trim().isEmpty) return;
                final m = _meta[_type]!;
                // Pass a _Reminder to the screen's onAdd callback.
                // id is empty string here — Firestore generates the real id on save.
                widget.onAdd(_Reminder(
                  id:          '',
                  type:        _type,
                  icon:        m.$1,
                  iconBg:      m.$2,
                  iconColor:   m.$3,
                  title:       _title.text.trim(),
                  recurrence:  _rec,
                  time:        _time.format(context),
                  description: _desc.text.trim().isEmpty
                      ? 'No notes.'
                      : _desc.text.trim(),
                ));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0),
              child: const Text('Save Reminder',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ])),
      );
}
