// Conditional import: uses web impl on web, stub on mobile/desktop
export 'speech_service_stub.dart'
    if (dart.library.html) 'speech_service_web.dart';