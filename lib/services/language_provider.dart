import 'package:flutter/material.dart';

enum AppLanguage { ru, kk, en }

class LanguageProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.ru; // Default to Russian as requested often in this region

  AppLanguage get currentLanguage => _currentLanguage;

  void setLanguage(AppLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  String get languageCode {
    switch (_currentLanguage) {
      case AppLanguage.ru:
        return 'ru';
      case AppLanguage.kk:
        return 'kk';
      case AppLanguage.en:
      default:
        return 'en';
    }
  }
}
