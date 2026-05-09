// Web implementation — uses dart:html SpeechRecognition
import 'dart:async';
import 'package:universal_html/html.dart' as html;

class WebSpeechService {
  static bool get isSupported => true;

  static html.SpeechRecognition? _recognition;
  static StreamSubscription? _srResult;
  static StreamSubscription? _srError;
  static StreamSubscription? _srEnd;

  static void start({
    required void Function(String) onResult,
    required void Function() onEnd,
    required void Function() onError,
    String lang = 'ru-RU',
  }) {
    stop();

    final r = html.SpeechRecognition();
    r.lang = lang;
    r.interimResults = false;
    r.continuous = false;
    _recognition = r;

    _srResult = r.onResult.listen((event) {
      final results = event.results;
      if (results == null || results.length == 0) return;
      final last = results[results.length - 1];
      if (last == null || last.isFinal != true) return;
      final t = last.item(0)?.transcript?.trim() ?? '';
      if (t.isNotEmpty) onResult(t);
    });

    _srError = r.onError.listen((_) {
      stop();
      onError();
    });

    _srEnd = r.onEnd.listen((_) {
      onEnd();
    });

    try {
      r.start();
    } catch (e) {
      stop();
      onError();
    }
  }

  static void stop() {
    _srResult?.cancel();
    _srError?.cancel();
    _srEnd?.cancel();
    _srResult = null;
    _srError = null;
    _srEnd = null;
    _recognition?.stop();
    _recognition = null;
  }
}