import 'dart:ui';

import 'package:app_commercante/core/locale/locale_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('arabe par défaut (RTL)', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = LocaleController(await SharedPreferences.getInstance());
    expect(controller.locale.value, const Locale('ar'));
    expect(controller.isArabic, isTrue);
  });

  test('la bascule en français est mémorisée', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await LocaleController(prefs).setLocale(const Locale('fr'));
    expect(prefs.getString('langue'), 'fr');
    expect(LocaleController(prefs).locale.value, const Locale('fr'));
  });

  test('une langue non gérée est ignorée', () async {
    SharedPreferences.setMockInitialValues({'langue': 'xx'});
    final controller = LocaleController(await SharedPreferences.getInstance());
    expect(controller.locale.value, const Locale('ar'));
    await controller.setLocale(const Locale('en'));
    expect(controller.locale.value, const Locale('ar'));
  });
}
