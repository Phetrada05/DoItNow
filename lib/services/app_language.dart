import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  AppLanguage._();

  static final AppLanguage instance = AppLanguage._();
  static const _prefsKey = 'app_language_code';

  Locale _locale = const Locale('th');

  Locale get locale => _locale;
  bool get isThai => _locale.languageCode == 'th';

  String text(String th, String en) {
    return isThai ? th : en;
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefsKey);
    if (savedCode == 'en' || savedCode == 'th') {
      _locale = Locale(savedCode!);
    }
  }

  Future<void> toggle() async {
    _locale = isThai ? const Locale('en') : const Locale('th');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _locale.languageCode);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'th' && languageCode != 'en') {
      return;
    }

    if (_locale.languageCode == languageCode) {
      return;
    }

    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _locale.languageCode);
    notifyListeners();
  }
}
