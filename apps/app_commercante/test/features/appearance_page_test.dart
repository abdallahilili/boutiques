import 'package:app_commercante/core/locale/locale_controller.dart';
import 'package:app_commercante/core/theme/theme_controller.dart';
import 'package:app_commercante/features/referentials/referential_pages.dart';
import 'package:app_commercante/features/settings/appearance_page.dart';
import 'package:app_commercante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget app(Widget home, Locale locale) => MaterialApp(
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

void main() {
  late ThemeController theme;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    theme = Get.put(ThemeController(prefs));
    Get.put(LocaleController(prefs));
  });
  tearDown(Get.reset);

  for (final locale in [const Locale('ar'), const Locale('fr')]) {
    testWidgets('page Apparence (${locale.languageCode}) : mode sombre et couleur, sans débordement sur petit écran', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app(const AppearancePage(), locale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();
      expect(theme.mode.value, ThemeMode.dark);

      // Une pastille de la palette change la couleur de l'application.
      final blue = ThemeController.presets[6];
      final swatch = find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).color == blue);
      await tester.ensureVisible(swatch);
      await tester.pumpAndSettle();
      await tester.tap(swatch);
      await tester.pumpAndSettle();
      expect(theme.seed.value, blue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('formulaire des couleurs : sélecteur visuel, le code #RRGGBB suit le choix', (tester) async {
    final controller = TextEditingController(text: '#000000');
    await tester.pumpWidget(app(Scaffold(body: SingleChildScrollView(child: ColorHexField(controller: controller, label: 'Couleur'))), const Locale('ar')));
    await tester.pumpAndSettle();

    final target = const Color(0xFFE53935);
    await tester.tap(find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).color == target));
    await tester.pump();
    expect(controller.text, '#E53935');
    expect(find.byType(TextField), findsNothing, reason: 'plus de saisie du code hexadécimal');
  });
}
