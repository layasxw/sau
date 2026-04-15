import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:rehab_assist/services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class _Log {
  final String id;
  final DateTime date;
  final Map<String, int> symptoms;
  final String mood, notes;
  final Map<String, dynamic>? aiAnalysis;
  _Log({
    required this.id,
    required this.date,
    required this.symptoms,
    required this.mood,
    required this.notes,
    this.aiAnalysis,
  });
  int get avg => symptoms.isEmpty
      ? 0
      : (symptoms.values.fold(0, (s, v) => s + v) / symptoms.length).round();
}

class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({super.key});
  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  bool _list = true;
  List<_Log> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  Future<void> _loadSymptoms() async {
    final data = await FirestoreService.getSymptoms();
    if (!mounted) return;
    setState(() {
      _logs = data.map((l) {
        return _Log(
          id: l['id'], 
          date: (l['date'] as Timestamp).toDate(), 
          symptoms: Map<String, int>.from(l['symptoms'] ?? {}), 
          mood: l['mood'] ?? '', 
          notes: l['notes'] ?? '',
          aiAnalysis: l['aiAnalysis'] != null 
            ? Map<String, dynamic>.from(l['aiAnalysis']) 
            : null
        );
      }).toList();
    });
  } 

  void _showSheet() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            _CheckInSheet(onSave: (l, aiResult) async {
              await FirestoreService.saveSymptom({
                'date': l.date,
                'symptoms': l.symptoms,
                'mood': l.mood,
                'notes': l.notes,
                'aiAnalysis': aiResult,
              });
              _loadSymptoms();
            }),
      );

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 100;
    
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Symptom Tracking', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 4),
              Text('Monitor your daily symptoms and track your recovery progress', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              Row(
                children: [
                  _Toggle(showList: _list, onChanged: (v) => setState(() => _list = v)),
                  const Spacer(),
                  _BouncingWrapper(
                    onTap: _showSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: const Row(
                        children: [
                          Icon(CupertinoIcons.add, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Check-in', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        ]
                      )
                    )
                  ),
                ]
              ),
              const SizedBox(height: 24),
              if (_logs.isEmpty)
                _empty()
              else if (_list)
                ..._logs.map((l) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _LogCard(log: l)))
              else
                _chart(),
              const SizedBox(height: 40),
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
          SizedBox(width: 80, height: 60, child: CustomPaint(painter: _HBPainter())),
          const SizedBox(height: 24),
          Text('No symptom logs yet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
              'Start tracking your daily symptoms to monitor your recovery',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.45)),
        ]),
      );

  Widget _chart() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.divider, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 40, offset: const Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Severity Trend', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _logs.take(7).toList().reversed.map((l) {
                  final h = (l.avg / 5 * 100).clamp(6.0, 100.0);
                  final c = l.avg <= 2
                      ? const Color(0xFF10B981)
                      : l.avg <= 3
                          ? const Color(0xFFF59E0B)
                          : AppColors.accent;
                  return Expanded(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                              height: h,
                              decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(6))),
                          const SizedBox(height: 8),
                          Text('${l.date.day}/${l.date.month}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        ]),
                  ));
                }).toList()),
          ),
          const SizedBox(height: 20),
          Row(children: [
            _dot(const Color(0xFF10B981), 'Mild'),
            const SizedBox(width: 16),
            _dot(const Color(0xFFF59E0B), 'Moderate'),
            const SizedBox(width: 16),
            _dot(AppColors.accent, 'Severe'),
          ]),
        ]),
      );

  Widget _dot(Color c, String l) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(l, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ]);
}

class _LogCard extends StatelessWidget {
  final _Log log;
  const _LogCard({required this.log});
  
  Color get _c => log.avg <= 2
      ? const Color(0xFF10B981)
      : log.avg <= 3
          ? const Color(0xFFF59E0B)
          : AppColors.accent;
          
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.divider, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 40, offset: const Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${log.date.day}/${log.date.month}/${log.date.year}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Spacer(),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _c.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Severity ${log.avg}/5',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _c))),
          ]),
          const SizedBox(height: 16),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: log.symptoms.entries.map((e) {
                final c = e.value <= 2
                    ? const Color(0xFF10B981)
                    : e.value <= 3
                        ? const Color(0xFFF59E0B)
                        : AppColors.accent;
                return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                    child: Text('${e.key} · ${e.value}/5',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)));
              }).toList()),
          if (log.mood.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(CupertinoIcons.smiley, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Mood: ${log.mood}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ]),
          ],
          if (log.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(log.notes, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          ],
          const SizedBox(height: 16),
          _AiTip(log: log),
        ]),
      );
}

class _AiTip extends StatelessWidget {
  final _Log log;
  const _AiTip({required this.log});

  @override
  Widget build(BuildContext context) {
    final ai = log.aiAnalysis;
    final text = ai != null 
        ? '${ai['summary'] ?? ''} ${ai['advice'] ?? ''}'.trim()
        : 'Continue monitoring your symptoms and discuss them at your next appointment.';
    final isHigh = ai?['risk'] == 'high';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isHigh ? AppColors.accent.withOpacity(0.05) : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isHigh 
                  ? AppColors.accent.withOpacity(0.2) 
                  : AppColors.primary.withOpacity(0.1))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(CupertinoIcons.sparkles, size: 18, color: isHigh ? AppColors.accent : AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isHigh ? AppColors.accent : AppColors.textPrimary, height: 1.4))),
      ]),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool showList;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.showList, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider, width: 0.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _seg('List', showList, () => onChanged(true)),
          _seg('Chart', !showList, () => onChanged(false)),
        ]),
      );
  Widget _seg(String label, bool sel, VoidCallback tap) => GestureDetector(
      onTap: tap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
              color: sel ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20)),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : AppColors.textPrimary)),
          )));
}

// ── Check-in Sheet ─────────────────────────────────────────────────────────────
class _CheckInSheet extends StatefulWidget {
  final void Function(_Log, Map<String, dynamic>?) onSave;
  const _CheckInSheet({required this.onSave});
  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  // ── Symptom categories ─────────────────────────────────────────────────────
  static const _categories = {
    'Digestive 🍽️': ['Abdominal pain', 'Nausea', 'Vomiting', 'Bloating', 'Diarrhea', 'Constipation', 'Heartburn', 'Loss of appetite'],
    'Energy & Body 💪': ['Fatigue', 'Weakness', 'Fever', 'Weight loss', 'Dizziness'],
    'Mental 🧠': ['Low mood', 'Anxiety'],
  };
  static const _moods = [
    {'emoji': '😊', 'label': 'Great'},
    {'emoji': '🙂', 'label': 'Good'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '😔', 'label': 'Low'},
    {'emoji': '😟', 'label': 'Bad'},
  ];

  final Map<String, int> _sel = {};
  String _mood = '';
  final _notes = TextEditingController();
  final _aiText = TextEditingController();
  bool _aiLoading = false;
  final _speech = stt.SpeechToText();
  bool _isListening = false;
  Map<String, dynamic>? _aiResult;
  final Set<String> _expandedCategories = {};

  Future<void> _analyzeWithAI() async {
    if (_aiText.text.trim().isEmpty) return;
    setState(() => _aiLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://sau-production.up.railway.app/symptoms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': _aiText.text.trim()}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _sel.clear();
          final symptoms = Map<String, dynamic>.from(data['symptoms'] ?? {});
          symptoms.forEach((k, v) => _sel[k] = (v as num).toInt());
          const moodMap = {
            'Great': 'Great', 'Good': 'Good',
            'Okay': 'Okay', 'Low': 'Low', 'Bad': 'Bad',
          };
          _mood = moodMap[data['mood']] ?? data['mood'] ?? '';
          _notes.text = data['notes'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('AI error: $e');
    } finally {
      setState(() => _aiLoading = false);
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      final available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          setState(() => _aiText.text = result.recognizedWords);
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _analyzeAndSave() async {
    setState(() => _aiLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://sau-production.up.railway.app/analyze-symptoms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'symptoms': _sel, 'mood': _mood, 'notes': _notes.text.trim()}),
      );
      if (response.statusCode == 200) {
        setState(() => _aiResult = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('AI error: $e');
    } finally {
      setState(() => _aiLoading = false);
    }

    // Если получили результат — показываем его, сохраняем только при нажатии Save
    if (_aiResult != null) return;

    // Если AI недоступен — сохраняем сразу
    widget.onSave(
      _Log(id: '', date: DateTime.now(), symptoms: Map.from(_sel), mood: _mood, notes: _notes.text.trim()),
      _aiResult,
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveAfterAI() async {
    widget.onSave(
      _Log(id: '', date: DateTime.now(), symptoms: Map.from(_sel), mood: _mood, notes: _notes.text.trim()),
      _aiResult,
    );
    if (mounted) Navigator.pop(context);
  }

  bool get _canSave => _sel.isNotEmpty || _mood.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Daily Check-in', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ]),
                  const Spacer(),
                  GestureDetector(
                    onTap: _listen,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isListening ? AppColors.accent.withOpacity(0.08) : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _isListening ? AppColors.accent : AppColors.divider),
                      ),
                      child: Row(children: [
                        Icon(_isListening ? CupertinoIcons.mic_solid : CupertinoIcons.mic, size: 16,
                            color: _isListening ? AppColors.accent : AppColors.textPrimary),
                        const SizedBox(width: 6),
                        Text(_isListening ? 'Listening...' : 'Voice',
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: _isListening ? AppColors.accent : AppColors.textPrimary,
                            )),
                      ]),
                    ),
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ── Voice / AI text input ──────────────────────────────
                  TextField(
                    controller: _aiText,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Опишите симптомы текстом или используйте голос...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BouncingWrapper(
                    onTap: _aiLoading ? null : _analyzeWithAI,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: _aiLoading
                        ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(CupertinoIcons.sparkles, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Заполнить через AI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.divider, thickness: 0.5),
                  const SizedBox(height: 24),
                  // ─────────────────────────────────────────────────────
                  _stepLabel('1', 'Select your symptoms'),
                  const SizedBox(height: 16),
                  ..._categories.entries.map((cat) {
                    final allSymptoms = cat.value;
                    final isExpanded = _expandedCategories.contains(cat.key);
                    final visibleSymptoms = isExpanded ? allSymptoms : allSymptoms.take(4).toList();
                    final hasMore = allSymptoms.length > 4;
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(cat.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          ...visibleSymptoms.map((s) {
                            final selected = _sel.containsKey(s);
                            return GestureDetector(
                              onTap: () => setState(() => selected ? _sel.remove(s) : _sel[s] = 2),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primary : AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
                                ),
                                child: Text(s,
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: selected ? Colors.white : AppColors.textPrimary,
                                    )),
                              ),
                            );
                          }),
                          if (hasMore)
                            GestureDetector(
                              onTap: () => setState(() =>
                                isExpanded ? _expandedCategories.remove(cat.key) : _expandedCategories.add(cat.key)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: Text(isExpanded ? 'Show less' : '+ ${allSymptoms.length - 4} more',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ]);
                  }),

                  if (_sel.isNotEmpty) ...[ 
                    const Divider(height: 1, color: AppColors.divider, thickness: 0.5),
                    const SizedBox(height: 20),
                    const Text('Severity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3)),
                    const SizedBox(height: 12),
                    ..._sel.keys.map((name) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(child: Text(name, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
                        Text('${_sel[name]}/5', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        Expanded(
                          flex: 2,
                          child: Slider(
                            min: 1, max: 5, divisions: 4,
                            value: _sel[name]!.toDouble(),
                            activeColor: AppColors.primary,
                            inactiveColor: AppColors.primaryLight,
                            onChanged: (v) => setState(() => _sel[name] = v.round()),
                          ),
                        ),
                      ]),
                    )),
                    const SizedBox(height: 12),
                  ],

                  const Divider(height: 1, color: AppColors.divider, thickness: 0.5),
                  const SizedBox(height: 24),

                  _stepLabel('2', 'Overall mood'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _moods.map((m) {
                      final sel = _mood == m['label'];
                      return GestureDetector(
                        onTap: () => setState(() => _mood = m['label']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primaryLight : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: sel ? AppColors.primary : Colors.transparent, width: 1.5),
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(m['emoji']!, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 6),
                            Text(m['label']!, style: TextStyle(
                              fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel ? AppColors.primary : AppColors.textSecondary,
                            )),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.divider, thickness: 0.5),
                  const SizedBox(height: 24),

                  _stepLabel('3', 'Add details (optional)'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notes,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Any notes for your doctor...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),

                  if (_aiResult != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _aiResult!['risk'] == 'high' ? AppColors.accent.withOpacity(0.05) : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _aiResult!['risk'] == 'high' ? AppColors.accent.withOpacity(0.3) : AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(CupertinoIcons.sparkles, size: 16, color: _aiResult!['risk'] == 'high' ? AppColors.accent : AppColors.primary),
                          const SizedBox(width: 8),
                          Text('AI Insights', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _aiResult!['risk'] == 'high' ? AppColors.accent : AppColors.primary)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _aiResult!['risk'] == 'high' ? AppColors.accent : (_aiResult!['risk'] == 'medium' ? Colors.orange : const Color(0xFF10B981)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text((_aiResult!['risk'] ?? '').toString().toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Text(_aiResult!['summary'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                        const SizedBox(height: 6),
                        Text(_aiResult!['advice'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                        const SizedBox(height: 8),
                        const Text(
                          'Это не медицинский совет. Проконсультируйтесь с вашим врачом.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 40),
                ]),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
              ),
              child: _BouncingWrapper(
                onTap: _canSave && !_aiLoading
                  ? (_aiResult != null ? _saveAfterAI : _analyzeAndSave)
                  : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: (_canSave && !_aiLoading) ? AppGradients.primary : null,
                    color: (!_canSave || _aiLoading) ? AppColors.divider : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _aiLoading
                    ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(_aiResult != null ? CupertinoIcons.checkmark_alt : CupertinoIcons.sparkles, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(_aiResult != null ? 'Save' : 'Analyze & Save', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ]),
                )
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepLabel(String step, String title) => Row(children: [
    Container(
      width: 24, height: 24,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      child: Center(child: Text(step, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
    ),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.2)),
  ]);
}

class _HBPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height * .5)
          ..lineTo(size.width * .2, size.height * .5)
          ..lineTo(size.width * .35, size.height * .1)
          ..lineTo(size.width * .5, size.height * .9)
          ..lineTo(size.width * .65, size.height * .5)
          ..lineTo(size.width, size.height * .5),
        p);
  }

  @override
  bool shouldRepaint(_) => false;
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
