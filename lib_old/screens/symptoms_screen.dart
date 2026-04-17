import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Symptom Tracking',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const Text(
            'Monitor your daily symptoms and track your recovery progress',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Row(children: [
          _Toggle(showList: _list, onChanged: (v) => setState(() => _list = v)),
          const Spacer(),
          SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _showSheet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Daily Check-in'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              )),
        ]),
        const SizedBox(height: 20),
        if (_logs.isEmpty)
          _empty()
        else if (_list)
          ..._logs.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LogCard(log: l)))
        else
          _chart(),
      ]),
    );
  }

  Widget _empty() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          SizedBox(
              width: 64, height: 48, child: CustomPaint(painter: _HBPainter())),
          const SizedBox(height: 20),
          const Text('No symptom logs yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
              'Start tracking your daily symptoms to monitor your recovery',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.45)),
          const SizedBox(height: 24),
          SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                  onPressed: _showSheet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Daily Check-in'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)))),
        ]),
      );

  Widget _chart() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Severity Trend',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _logs.take(7).toList().reversed.map((l) {
                  final h = (l.avg / 5 * 80).clamp(6.0, 80.0);
                  final c = l.avg <= 2
                      ? Colors.green
                      : l.avg <= 3
                          ? const Color(0xFFFF9800)
                          : AppColors.accent;
                  return Expanded(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                              height: h,
                              decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(6))),
                          const SizedBox(height: 6),
                          Text('${l.date.day}/${l.date.month}',
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.textSecondary)),
                        ]),
                  ));
                }).toList()),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _dot(Colors.green, 'Mild'),
            const SizedBox(width: 16),
            _dot(const Color(0xFFFF9800), 'Moderate'),
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
        Text(l,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]);
}

class _LogCard extends StatelessWidget {
  final _Log log;
  const _LogCard({required this.log});
  Color get _c => log.avg <= 2
      ? Colors.green
      : log.avg <= 3
          ? const Color(0xFFFF9800)
          : AppColors.accent;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${log.date.day}/${log.date.month}/${log.date.year}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const Spacer(),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _c.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Severity ${log.avg}/5',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: _c))),
          ]),
          const SizedBox(height: 10),
          Wrap(
              spacing: 8,
              runSpacing: 6,
              children: log.symptoms.entries.map((e) {
                final c = e.value <= 2
                    ? Colors.green
                    : e.value <= 3
                        ? const Color(0xFFFF9800)
                        : AppColors.accent;
                final bg = e.value <= 2
                    ? const Color(0xFFE8F5E9)
                    : e.value <= 3
                        ? const Color(0xFFFFF3E0)
                        : const Color(0xFFFFEBEE);
                return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: bg, borderRadius: BorderRadius.circular(20)),
                    child: Text('${e.key} · ${e.value}/5',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c)));
              }).toList()),
          if (log.mood.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.sentiment_satisfied_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Mood: ${log.mood}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ]),
          ],
          if (log.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(log.notes,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          ],
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: isHigh ? Colors.red.withOpacity(0.05) : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isHigh 
                  ? Colors.red.withOpacity(0.3) 
                  : AppColors.primary.withOpacity(0.2))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.auto_awesome, size: 16, 
            color: isHigh ? Colors.red : AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, 
                    color: isHigh ? Colors.red : AppColors.primary, 
                    height: 1.45))),
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
        height: 44,
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.divider)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _seg('List', showList, () => onChanged(true)),
          _seg('Chart', !showList, () => onChanged(false)),
        ]),
      );
  Widget _seg(String label, bool sel, VoidCallback tap) => GestureDetector(
      onTap: tap,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
              color: sel ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(25)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppColors.textPrimary))));
}

// ── Check-in Sheet ─────────────────────────────────────────────────────────────
class _CheckInSheet extends StatefulWidget {
  final void Function(_Log, Map<String, dynamic>?) onSave;
  const _CheckInSheet({required this.onSave});
  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  static const _opts = [
    'Abdominal pain',
    'Nausea',
    'Vomiting',
    'Fatigue',
    'Weakness',
    'Fever',
    'Loss of appetite',
    'Weight loss',
    'Bloating',
    'Diarrhea',
    'Constipation',
    'Heartburn',
    'Dizziness',
    'Low mood',
    'Anxiety'
  ];
  static const _moods = ['Great 😊', 'Good 🙂', 'Okay 😐', 'Low 😔', 'Bad 😟'];
  final Map<String, int> _sel = {};
  String _mood = '';
  final _notes = TextEditingController();
  final _aiText = TextEditingController();
  bool _aiLoading = false;
  final _speech = stt.SpeechToText();
  bool _isListening = false;
  Map<String, dynamic>? _aiResult;
  bool _aiAnalyzing = false;

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
            'Great': 'Great 😊', 'Good': 'Good 🙂',
            'Okay': 'Okay 😐', 'Low': 'Low 😔', 'Bad': 'Bad 😟',
          };
          _mood = moodMap[data['mood']] ?? data['mood'] ?? '';
          _notes.text = data['notes'] ?? '';
        });
      }
    } catch (e) {
      print('AI error: $e');
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

Future<void> _analyzeSymptoms() async {
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
}
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
          const Text('Daily Check-in',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          const Text('Describe how you feel',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          
          Row(
          children: [
            Expanded(
              child: 
                TextField(
                  controller: _aiText,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. I have a headache for 2 days and feel nauseous...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  )),
              ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _listen,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : AppColors.primary,
              ),
            ),
          ],
        ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _aiLoading ? null : _analyzeWithAI,
              icon: _aiLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_aiLoading ? 'Analyzing...' : 'Analyze with AI'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Symptoms today',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _opts.map((s) {
                final sel = _sel.containsKey(s);
                return GestureDetector(
                    onTap: () =>
                        setState(() => sel ? _sel.remove(s) : _sel[s] = 2),
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color:
                                sel ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.divider)),
                        child: Text(s,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textPrimary))));
              }).toList()),
          if (_sel.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Severity',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            ..._sel.keys.map((name) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary))),
                    Text('${_sel[name]}/5',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ]),
                  Slider(
                      min: 1,
                      max: 5,
                      divisions: 4,
                      value: _sel[name]!.toDouble(),
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _sel[name] = v.round())),
                ])),
          ],
          const SizedBox(height: 16),
          const Text('Overall mood',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moods.map((m) {
                final sel = m == _mood;
                return GestureDetector(
                    onTap: () => setState(() => _mood = m),
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primaryLight
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.divider)),
                        child: Text(m,
                            style: TextStyle(
                                fontSize: 13,
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight:
                                    sel ? FontWeight.w600 : FontWeight.w400))));
              }).toList()),
          const SizedBox(height: 16),
          const Text('Notes',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
              controller: _notes,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any other observations for your doctor...',
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
              )),
          const SizedBox(height: 24),
          if (_aiResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _aiResult!['risk'] == 'high'
                    ? Colors.red.withOpacity(0.05)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _aiResult!['risk'] == 'high'
                      ? Colors.red.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.auto_awesome, size: 16,
                      color: _aiResult!['risk'] == 'high' ? Colors.red : AppColors.primary),
                  const SizedBox(width: 6),
                  Text('AI Analysis',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _aiResult!['risk'] == 'high' ? Colors.red : AppColors.primary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _aiResult!['risk'] == 'high'
                          ? Colors.red
                          : _aiResult!['risk'] == 'medium'
                              ? Colors.orange
                              : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_aiResult!['risk']!.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(_aiResult!['summary'] ?? '',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                const SizedBox(height: 6),
                Text(_aiResult!['advice'] ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                const SizedBox(height: 8),
                const Text(
                  'Это не медицинский совет. Проконсультируйтесь с вашим врачом.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
              ]),
            ),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_sel.isEmpty && _mood.isEmpty)
                  ? null
                  : _aiResult == null
                      ? () async {
                          await _analyzeSymptoms();
                        }
                      : () {
                          widget.onSave(_Log(
                              id: '',
                              date: DateTime.now(),
                              symptoms: Map.from(_sel),
                              mood: _mood,
                              notes: _notes.text.trim()),
                              _aiResult,
                          );
                          Navigator.pop(context);
                        },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.divider,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0),
              child: _aiAnalyzing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_aiResult == null ? 'Analyze & Save' : 'Confirm & Save',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),       
         ])),
      );
}

class _HBPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFCDD5DA)
      ..strokeWidth = 2.5
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
