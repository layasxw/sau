// Mobile/desktop stub — no web speech API available
class WebSpeechService {
  static bool get isSupported => false;

  static void start({
    required void Function(String) onResult,
    required void Function() onEnd,
    required void Function() onError,
    String lang = 'ru-RU',
  }) {}

  static void stop() {}
}