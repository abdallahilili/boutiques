import 'dart:ui';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Langue de l'application : arabe par défaut (RTL), bascule en français mémorisée sur l'appareil.
class LocaleController extends GetxController {
  LocaleController(this._prefs) : locale = Rx<Locale>(_readSaved(_prefs));

  static const _key = 'langue';
  static const supported = [Locale('ar'), Locale('fr')];
  static const fallback = Locale('ar');

  final SharedPreferences _prefs;
  final Rx<Locale> locale;

  static Locale _readSaved(SharedPreferences prefs) {
    final code = prefs.getString(_key);
    return supported.firstWhere((l) => l.languageCode == code, orElse: () => fallback);
  }

  bool get isArabic => locale.value.languageCode == 'ar';

  Future<void> setLocale(Locale next) async {
    if (!supported.contains(next)) return;
    locale.value = next;
    await _prefs.setString(_key, next.languageCode);
  }
}
