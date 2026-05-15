class ApiConfig {
  static const String baseUrl = 'https://sau-6iuc.onrender.com';

  static String get analyzeUrl => '$baseUrl/analyze';
  static String get symptomsUrl => '$baseUrl/symptoms';
  static String get analyzeSymptomsUrl => '$baseUrl/analyze-symptoms';
  static String get suggestRemindersUrl => '$baseUrl/suggest-reminders';
  static String get analyzeMealUrl => '$baseUrl/analyze-meal';
  static String get recognizeFoodUrl => '$baseUrl/recognize-food';
}
