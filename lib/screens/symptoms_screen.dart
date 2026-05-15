import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:rehab_assist/services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'speech_service.dart';
import '../services/language_provider.dart';
import 'package:provider/provider.dart';
import '../l10n/translations.dart';
import '../services/api_config.dart';

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

  final _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  @override
  void dispose() {
    if (kIsWeb) WebSpeechService.stop();
    super.dispose();
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
                : null);
      }).toList();
    });
  }

  Future<void> _listen() async {
    if (kIsWeb) {
      if (_isListening) {
        WebSpeechService.stop();
        setState(() => _isListening = false);
        return;
      }
      _showSheet();
      return;
    }

    // Native
    if (!_isListening) {
      final available = await _speech.initialize(
        onError: (e) { if (mounted) setState(() => _isListening = false); },
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) {
            setState(() => _isListening = false);
          }
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _showSheet();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Микрофон недоступен. Разрешите доступ.')),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _showSheet() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CheckInSheet(
            autoListen: true,
            onSave: (l, aiResult) async {
              await FirestoreService.saveSymptom({
                'date': l.date,
                'symptoms': l.symptoms,
                'mood': l.mood,
                'notes': l.notes,
                'aiAnalysis': aiResult,
              });
              _loadSymptoms();
            }),
      ).then((_) {
        if (mounted) setState(() => _isListening = false);
      });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 100;

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(Translations.get(lang, 'nav_symptoms'),
                      style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 4),
                  Text(
                      Translations.get(lang, 'symptoms_subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  Row(children: [
                    _Toggle(
                        showList: _list,
                        onChanged: (v) => setState(() => _list = v)),
                    const Spacer(),
                    _BouncingWrapper(
                        onTap: _showSheet,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                                gradient: AppGradients.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ]),
                            child: Row(children: [
                              const Icon(CupertinoIcons.add,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(Translations.get(lang, 'log_symptom_btn'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                            ]))),
                  ]),
                  const SizedBox(height: 24),
                  if (_logs.isEmpty)
                    _empty(lang)
                  else if (_list)
                    ..._logs.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _LogCard(log: l, lang: lang)))
                  else
                    _chart(lang),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 110,
          right: 24,
          child: _MicFab(isListening: _isListening, onTap: _listen),
        ),
      ],
    );
  }

  Widget _empty(AppLanguage lang) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.divider, width: 0.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 40,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(children: [
          SizedBox(
              width: 80, height: 60, child: CustomPaint(painter: _HBPainter())),
          const SizedBox(height: 24),
          Text(Translations.get(lang, 'no_symptoms_logged'),
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
              Translations.get(lang, 'symptoms_subtitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.45)),
        ]),
      );

  Widget _chart(AppLanguage lang) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.divider, width: 0.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 40,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Translations.get(lang, 'view_trends'), style: Theme.of(context).textTheme.titleLarge),
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
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
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
        Text(l,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      ]);
}

// ── Floating Mic FAB ───────────────────────────────────────────────────────────
class _MicFab extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  const _MicFab({required this.isListening, required this.onTap});
  @override
  State<_MicFab> createState() => _MicFabState();
}

class _MicFabState extends State<_MicFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 1.0, end: 1.65).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.4, end: 0.0).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_MicFab old) {
    super.didUpdateWidget(old);
    if (widget.isListening && !old.isListening) {
      _pulse.repeat();
    } else if (!widget.isListening && old.isListening) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () { widget.onTap(); HapticFeedback.mediumImpact(); },
        child: SizedBox(
          width: 72, height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isListening)
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withOpacity(_opacity.value)),
                    ),
                  ),
                ),
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.isListening
                      ? LinearGradient(
                          colors: [AppColors.accent, AppColors.accent.withOpacity(0.75)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : AppGradients.primary,
                  boxShadow: [
                    BoxShadow(
                        color: (widget.isListening ? AppColors.accent : AppColors.primary)
                            .withOpacity(0.38),
                        blurRadius: 18, offset: const Offset(0, 6)),
                  ],
                ),
                child: Icon(
                    widget.isListening ? CupertinoIcons.mic_solid : CupertinoIcons.mic,
                    size: 26, color: Colors.white),
              ),
            ],
          ),
        ),
      );
}

// ── Log Card ──────────────────────────────────────────────────────────────────
class _LogCard extends StatelessWidget {
  final _Log log;
  final AppLanguage lang;
  const _LogCard({required this.log, required this.lang});

  Color get _c => log.avg <= 2
      ? const Color(0xFF10B981)
      : log.avg <= 3 ? const Color(0xFFF59E0B) : AppColors.accent;

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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const Spacer(),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${Translations.get(lang, 'symptom_severity')} ${log.avg}/5',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _c))),
          ]),
          const SizedBox(height: 16),
          Wrap(
              spacing: 8, runSpacing: 8,
              children: log.symptoms.entries.map((e) {
                final c = e.value <= 2
                    ? const Color(0xFF10B981)
                    : e.value <= 3 ? const Color(0xFFF59E0B) : AppColors.accent;
                final name = _translateSymptom(e.key, lang);
                return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                    child: Text('$name · ${e.value}/5',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)));
              }).toList()),
          if (log.mood.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(CupertinoIcons.smiley, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Mood: ${_translateMood(log.mood, lang)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ]),
          ],
          if (log.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(log.notes, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          ],
          const SizedBox(height: 16),
          _AiTip(log: log, lang: lang),
        ]),
      );
}

class _AiTip extends StatelessWidget {
  final _Log log;
  final AppLanguage lang;
  const _AiTip({required this.log, required this.lang});

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
              color: isHigh ? AppColors.accent.withOpacity(0.2) : AppColors.primary.withOpacity(0.1))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(CupertinoIcons.sparkles, size: 18, color: isHigh ? AppColors.accent : AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: isHigh ? AppColors.accent : AppColors.textPrimary, height: 1.4))),
      ]),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool showList;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.showList, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    return Container(
        height: 40,
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider, width: 0.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _seg(Translations.get(lang, 'filter_all'), showList, () => onChanged(true)),
          _seg(Translations.get(lang, 'view_trends'), !showList, () => onChanged(false)),
        ]),
      );
  }

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
  final bool autoListen;
  const _CheckInSheet({required this.onSave, this.autoListen = false});
  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  @override
  void initState() {
    super.initState();
    if (widget.autoListen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
    }
  }

  static const _categories = {
    'Digestive 🍽️': [
      'Abdominal pain', 'Nausea', 'Vomiting (single)', 'Vomiting (multiple)',
      'Bloating', 'Diarrhea', 'Constipation', 'Heartburn', 'Loss of appetite'
    ],
    'Energy & Body 💪': [
      'Fatigue', 'Weakness', 'Fever', 'Weight loss', 'Dizziness'
    ],
  };
  


  final Map<String, int> _sel = {};
  String _mood = '';
  final _notes = TextEditingController();
  final _aiText = TextEditingController();
  bool _aiLoading = false;
  Map<String, dynamic>? _aiResult;
  final Set<String> _expandedCategories = {};
  final _scrollController = ScrollController();

  // Native speech
  final _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void dispose() {
    _notes.dispose();
    _aiText.dispose();
    _scrollController.dispose();
    if (kIsWeb) WebSpeechService.stop();
    super.dispose();
  }

  Future<void> _listen() async {
    // ── Web ──────────────────────────────────────────────────────────────────
    if (kIsWeb) {
      if (_isListening) {
        WebSpeechService.stop();
        setState(() => _isListening = false);
        return;
      }
      setState(() => _isListening = true);
      WebSpeechService.start(
        lang: 'ru-RU',
        onResult: (text) {
          if (!mounted) return;
          final cur = _aiText.text.trim();
          setState(() => _aiText.text = cur.isEmpty ? text : '$cur $text');
        },
        onEnd: () {
          // Auto-restart loop while still listening
          if (mounted && _isListening) {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted && _isListening) {
                WebSpeechService.start(
                  lang: 'ru-RU',
                  onResult: (text) {
                    if (!mounted) return;
                    final cur = _aiText.text.trim();
                    setState(() => _aiText.text = cur.isEmpty ? text : '$cur $text');
                  },
                  onEnd: () {},
                  onError: () {
                    if (mounted) setState(() => _isListening = false);
                  },
                );
              }
            });
          }
        },
        onError: () {
          if (mounted) setState(() => _isListening = false);
        },
      );
      return;
    }

    // ── Native (Android / iOS) ────────────────────────────────────────────────
    if (!_isListening) {
      final available = await _speech.initialize(
        onError: (e) { if (mounted) setState(() => _isListening = false); },
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) {
            setState(() => _isListening = false);
          }
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            if (!result.finalResult) return;
            final recognized = result.recognizedWords.trim();
            if (recognized.isEmpty) return;
            final current = _aiText.text.trim();
            setState(() {
              _aiText.text = current.isEmpty ? recognized : '$current $recognized';
            });
          },
          listenFor: Duration.zero,
          pauseFor: const Duration(seconds: 3),
          localeId: 'ru_RU',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Микрофон недоступен. Разрешите доступ.')),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _analyzeWithAI() async {
    if (_aiText.text.trim().isEmpty) return;
    setState(() => _aiLoading = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.symptomsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': _aiText.text.trim()}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI не смог обработать запрос, попробуй ещё раз')),
          );
          return;
        }
        setState(() {
          _sel.clear();
          final symptoms = Map<String, dynamic>.from(data['symptoms'] ?? {});
          symptoms.forEach((k, v) => _sel[k] = (v as num).toInt());
          const moodMap = {'Great': 'Great', 'Good': 'Good', 'Okay': 'Okay', 'Low': 'Low', 'Bad': 'Bad'};
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

  Future<void> _analyzeSymptoms() async {
    setState(() => _aiLoading = true);
    try {
      final profile = await FirestoreService.getUserProfile();
      final medical = await FirestoreService.getMedicalProfile();

      int? daysSinceSurgery;
      final raw = medical?['surgeryDate'];
      if (raw != null) {
        final surgeryDate = (raw as Timestamp).toDate();
        daysSinceSurgery = DateTime.now().difference(surgeryDate).inDays;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.analyzeSymptomsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'symptoms': _sel,
          'mood': _mood,
          'notes': _notes.text.trim(),
          'diagnosis': medical?['diagnosis'],
          'days_since_surgery': daysSinceSurgery,
          'restrictions': {'allergies': profile?['allergies'] ?? []},
        }),
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
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
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
                    Text(Translations.get(lang, 'new_reminder').replaceAll('Reminder', 'Check-in'), style: Theme.of(context).textTheme.headlineMedium),
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
                        Icon(_isListening ? CupertinoIcons.mic_solid : CupertinoIcons.mic,
                            size: 16, color: _isListening ? AppColors.accent : AppColors.textPrimary),
                        const SizedBox(width: 6),
                        Text(_isListening ? (lang == AppLanguage.en ? 'Listening...' : 'Слушаю...') : (lang == AppLanguage.en ? 'Voice' : 'Голос'),
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: _isListening ? AppColors.accent : AppColors.textPrimary)),
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
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextField(
                    controller: _aiText,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Опишите симптомы текстом или используйте голос...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      filled: true, fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BouncingWrapper(
                    onTap: _aiText.text.trim().isNotEmpty && !_aiLoading ? _analyzeWithAI : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: _aiLoading
                          ? const Center(child: SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
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
                  _stepLabel('1', Translations.get(lang, 'new_reminder').replaceAll('New Reminder', 'Select symptoms')),
                  const SizedBox(height: 16),
                  ..._categories.entries.map((cat) {
                    final allSymptoms = cat.value;
                    final isExpanded = _expandedCategories.contains(cat.key);
                    final visibleSymptoms = isExpanded ? allSymptoms : allSymptoms.take(4).toList();
                    final hasMore = allSymptoms.length > 4;
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(cat.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
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
                              child: Text(_translateSymptom(s, lang), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : AppColors.textPrimary)),
                            ),
                          );
                        }),
                        if (hasMore)
                          GestureDetector(
                            onTap: () => setState(() => isExpanded
                                ? _expandedCategories.remove(cat.key)
                                : _expandedCategories.add(cat.key)),
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
                      ]),
                      const SizedBox(height: 20),
                    ]);
                  }),
                  if (_sel.containsKey('Vomiting (multiple)') && _sel['Vomiting (multiple)']! > 0) ...[
                    _VomitingWarning(lang: lang),
                    const SizedBox(height: 20),
                  ],
                  if (_sel.isNotEmpty) ...[
                    if (_sel.keys.any((k) => !k.toLowerCase().contains('vomiting'))) ...[
                      const Divider(height: 1, color: AppColors.divider, thickness: 0.5),
                      const SizedBox(height: 20),
                      const Text('Severity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3)),
                      const SizedBox(height: 12),
                      ..._sel.keys.where((k) => !k.toLowerCase().contains('vomiting')).map((name) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              Expanded(child: Text(_translateSymptom(name, lang), style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
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
                  ],
                  if (_sel.containsKey('Vomiting (multiple)')) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.accent, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Critical Warning', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accent)),
                                const SizedBox(height: 4),
                                Text('Multiple vomiting episodes can cause severe dehydration. Please CALL YOUR DOCTOR or GO TO THE HOSPITAL immediately.', style: TextStyle(fontSize: 13, color: AppColors.accent.withOpacity(0.9), height: 1.4, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Divider(height: 1, color: AppColors.divider, thickness: 0.5),
                  const SizedBox(height: 24),
                  _stepLabel('2', Translations.get(lang, 'profile_title')),
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
                            Text(_translateMood(m['label']!, lang), style: TextStyle(fontSize: 12,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                color: sel ? AppColors.primary : AppColors.textSecondary)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.divider, thickness: 0.5),
                  const SizedBox(height: 24),
                  _stepLabel('3', Translations.get(lang, 'biometry')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notes,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: lang == AppLanguage.en ? 'Any notes for your doctor...' : 'Любые заметки для врача...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      filled: true, fillColor: AppColors.background,
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
                        border: Border.all(
                            color: _aiResult!['risk'] == 'high'
                                ? AppColors.accent.withOpacity(0.3)
                                : AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(CupertinoIcons.sparkles, size: 16,
                              color: _aiResult!['risk'] == 'high' ? AppColors.accent : AppColors.primary),
                          const SizedBox(width: 8),
                          Text('AI Insights', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: _aiResult!['risk'] == 'high' ? AppColors.accent : AppColors.primary)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _aiResult!['risk'] == 'high' ? AppColors.accent
                                  : (_aiResult!['risk'] == 'medium' ? Colors.orange : const Color(0xFF10B981)),
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
                        const Text('This is not medical advice. Please consult your doctor.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
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
                  onTap: _canSave && !_aiLoading ? (_aiResult != null ? _saveAfterAI : _analyzeSymptoms) : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: (_canSave && !_aiLoading) ? AppGradients.primary : null,
                      color: (!_canSave || _aiLoading) ? AppColors.divider : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _aiLoading
                        ? const Center(child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(_aiResult != null ? CupertinoIcons.checkmark_alt : CupertinoIcons.sparkles,
                                size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(_aiResult != null ? Translations.get(lang, 'save_symptoms') : (lang == AppLanguage.en ? 'Analyze & Save' : 'Анализ и сохранение'),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          ]),
                  )),
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

String _translateSymptom(String s, AppLanguage lang) {
  if (lang == AppLanguage.en) return s;
  final map = {
    'Abdominal pain': {'ru': 'Боль в животе', 'kk': 'Іштің ауыруы'},
    'Nausea': {'ru': 'Тошнота', 'kk': 'Жүрек айнуы'},
    'Vomiting (single)': {'ru': 'Рвота (однократная)', 'kk': 'Құсу (бір рет)'},
    'Vomiting (multiple)': {'ru': 'Рвота (многократная)', 'kk': 'Құсу (көп мәрте)'},
    'Bloating': {'ru': 'Вздутие', 'kk': 'Іштің кебуі'},
    'Diarrhea': {'ru': 'Диарея', 'kk': 'Іш өту'},
    'Constipation': {'ru': 'Запор', 'kk': 'Іш қату'},
    'Heartburn': {'ru': 'Изжога', 'kk': 'Зардап'},
    'Loss of appetite': {'ru': 'Потеря аппетита', 'kk': 'Тәбеттің жоғалуы'},
    'Fatigue': {'ru': 'Усталость', 'kk': 'Шаршау'},
    'Weakness': {'ru': 'Слабость', 'kk': 'Әлсіздік'},
    'Fever': {'ru': 'Жар', 'kk': 'Қызу'},
    'Weight loss': {'ru': 'Потеря веса', 'kk': 'Салмақ жоғалту'},
    'Dizziness': {'ru': 'Головокружение', 'kk': 'Бас айналу'},
  };
  return map[s]?[lang == AppLanguage.ru ? 'ru' : 'kk'] ?? s;
}

String _translateCategory(String c, AppLanguage lang) {
  if (lang == AppLanguage.en) return c;
  if (c.contains('Digestive')) return lang == AppLanguage.ru ? 'Пищеварение 🍽️' : 'Ас қорыту 🍽️';
  if (c.contains('Energy')) return lang == AppLanguage.ru ? 'Энергия и тело 💪' : 'Энергия және дене 💪';
  return c;
}

String _translateMood(String m, AppLanguage lang) {
  if (lang == AppLanguage.en) return m;
  final moods = {
    'Great': {'ru': 'Отлично', 'kk': 'Керемет'},
    'Good': {'ru': 'Хорошо', 'kk': 'Жақсы'},
    'Okay': {'ru': 'Нормально', 'kk': 'Қалыпты'},
    'Low': {'ru': 'Так себе', 'kk': 'Төмен'},
    'Bad': {'ru': 'Плохо', 'kk': 'Жаман'},
  };
  return moods[m]?[lang == AppLanguage.ru ? 'ru' : 'kk'] ?? m;
}

final _moods = [
  {'emoji': '😇', 'label': 'Great'},
  {'emoji': '😊', 'label': 'Good'},
  {'emoji': '😐', 'label': 'Okay'},
  {'emoji': '😕', 'label': 'Low'},
  {'emoji': '😫', 'label': 'Bad'},
];

class _VomitingWarning extends StatelessWidget {
  final AppLanguage lang;
  const _VomitingWarning({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.accent, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  Translations.get(lang, 'critical_warning_title'),
                  style: const TextStyle(color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Translations.get(lang, 'vomiting_multiple_warning'),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.45),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
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
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => widget.onTap != null ? _controller.forward() : null,
        onTapUp: (_) {
          if (widget.onTap != null) {
            _controller.reverse();
            widget.onTap!();
            HapticFeedback.lightImpact();
          }
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(scale: _scale, child: widget.child),
      );
}