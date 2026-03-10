import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _Reminder {
  final IconData icon;
  final Color iconBg, iconColor;
  String title, recurrence, time, description;
  bool hasAiBadge, completed;
  _Reminder(
    {required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.recurrence,
    required this.time,
    required this.description,
    this.hasAiBadge = false,
    this.completed = false});
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  int _filter = 0;
  static const _filters = ['All', 'Today', 'Upcoming', 'Completed'];

  final List<_Reminder> _items = [
    _Reminder(
        icon: Icons.medication_outlined,
        iconBg: const Color(0xFFEDE7F6),
        iconColor: const Color(0xFF7E57C2),
        title: 'Morning Medication',
        recurrence: 'Daily',
        time: '8:00 AM',
        description:
            'Take prescribed medications with water before breakfast.'),
    _Reminder(
        icon: Icons.monitor_heart_outlined,
        iconBg: const Color(0xFFFFF8E1),
        iconColor: const Color(0xFFFF9800),
        title: 'Evening Symptom Log',
        recurrence: 'Daily',
        time: '9:00 PM',
        description:
            'Record any abdominal pain, nausea, or changes in digestion.',
        hasAiBadge: true),
    _Reminder(
        icon: Icons.bedtime_outlined,
        iconBg: const Color(0xFFE8F7F6),
        iconColor: AppColors.primary,
        title: 'Sleep Hygiene Routine',
        recurrence: 'Daily',
        time: '10:00 PM',
        description:
            'Follow your wind-down routine. Adequate sleep supports immune recovery.'),
  ];

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

  void _showAddSheet() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            _AddSheet(onAdd: (r) => setState(() => _items.insert(0, r))),
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
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                          color: sel ? Colors.white : AppColors.textPrimary)),
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
                  style:
                      TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            ]),
          )
        else
          ...list.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _Card(
                    item: r,
                    onDelete: () => setState(() => _items.remove(r)),
                    onToggle: () => setState(() => r.completed = !r.completed)),
              )),
      ]),
    );
  }
}

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
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                      item.completed ? Icons.check_circle_outline : item.icon,
                      color: item.completed ? Colors.green : item.iconColor,
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
                                color: AppColors.primary.withOpacity(0.25))),
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
                            fontSize: 13, color: AppColors.textSecondary)),
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

// ── Add Reminder Bottom Sheet ─────────────────────────────────────────────────
class _AddSheet extends StatefulWidget {
  final void Function(_Reminder) onAdd;
  const _AddSheet({required this.onAdd});
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _type = 'Medication', _rec = 'Daily';
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  static const _types = [
    'Medication',
    'Doctor appointment',
    'Lab test',
    'Physical activity',
    'Dietary',
    'Sleep',
    'Other'
  ];
  static const _recs = ['Once', 'Daily', 'Weekly', 'Monthly'];
  static const _meta = {
    'Medication': (
      Icons.medication_outlined,
      Color(0xFFEDE7F6),
      Color(0xFF7E57C2)
    ),
    'Doctor appointment': (
      Icons.local_hospital_outlined,
      Color(0xFFFFEBEE),
      Color(0xFFE53935)
    ),
    'Lab test': (Icons.science_outlined, Color(0xFFFFF3E0), Color(0xFFFF9800)),
    'Physical activity': (
      Icons.directions_run,
      Color(0xFFE8F5E9),
      Colors.green
    ),
    'Dietary': (
      Icons.restaurant_menu_outlined,
      Color(0xFFE8F7F6),
      AppColors.primary
    ),
    'Sleep': (Icons.bedtime_outlined, Color(0xFFE8F7F6), AppColors.primary),
    'Other': (
      Icons.notifications_outlined,
      Color(0xFFF0F4F5),
      AppColors.textSecondary
    ),
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
                          .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)))
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
                                fontSize: 15, color: AppColors.textPrimary)),
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
                widget.onAdd(_Reminder(
                  icon: m.$1,
                  iconBg: m.$2,
                  iconColor: m.$3,
                  title: _title.text.trim(),
                  recurrence: _rec,
                  time: _time.format(context),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ])),
      );
}
