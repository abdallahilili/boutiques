import 'package:app_commercante/core/theme/app_theme.dart';
import 'package:app_commercante/core/theme/theme_controller.dart';
import 'package:app_commercante/core/widgets/color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('par défaut : mode automatique et couleur d\'origine', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController(await SharedPreferences.getInstance());
    expect(controller.mode.value, ThemeMode.system);
    expect(controller.seed.value, ThemeController.defaultSeed);
  });

  test('le mode sombre et la couleur choisis sont mémorisés sur l\'appareil', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = ThemeController(prefs);
    await controller.setMode(ThemeMode.dark);
    await controller.setSeed(const Color(0xFF1565C0));

    final reloaded = ThemeController(prefs);
    expect(reloaded.mode.value, ThemeMode.dark);
    expect(reloaded.seed.value, const Color(0xFF1565C0));
  });

  test('une valeur enregistrée invalide retombe sur les défauts ; la couleur est toujours opaque', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'violet', 'theme_couleur': 0x001565C0});
    final controller = ThemeController(await SharedPreferences.getInstance());
    expect(controller.mode.value, ThemeMode.system);
    expect(controller.seed.value.a, 1.0);
  });

  test('réinitialiser rend la couleur d\'origine', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = ThemeController(prefs);
    await controller.setSeed(Colors.green);
    await controller.resetSeed();
    expect(controller.seed.value, ThemeController.defaultSeed);
    expect(prefs.containsKey('theme_couleur'), isFalse);
  });

  test('la couleur choisie colore le thème clair et le thème sombre', () {
    const seed = Color(0xFF1565C0);
    final light = AppTheme.light(seed).colorScheme;
    final dark = AppTheme.dark(seed).colorScheme;
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.primary, isNot(AppTheme.light().colorScheme.primary));
  });

  test('codes hexadécimaux : aller-retour et rejet des codes invalides', () {
    expect(colorToHex(const Color(0xFF1565C0)), '#1565C0');
    expect(colorFromHex('#1565c0'), const Color(0xFF1565C0));
    expect(colorFromHex('1565C0'), isNull);
    expect(colorFromHex('#12'), isNull);
  });

  testWidgets('le sélecteur : une pastille choisit la couleur, glisser sur le carré la modifie', (tester) async {
    Color? changed;
    Color? ended;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ColorPicker(color: const Color(0xFFFF0000), onChanged: (c) => changed = c, onChangeEnd: (c) => ended = c),
        ),
      ),
    ));

    // Pastille « vert » des couleurs rapides.
    final swatches = find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).color == const Color(0xFF43A047));
    await tester.tap(swatches);
    expect(ended, const Color(0xFF43A047));

    // Un geste sur le carré saturation / luminosité change la couleur (coin en haut à gauche = blanc).
    changed = null;
    final square = tester.getTopLeft(find.descendant(of: find.byType(ColorPicker), matching: find.byType(CustomPaint)).first);
    final gesture = await tester.startGesture(square + const Offset(2, 2));
    await gesture.up();
    expect(changed, isNotNull);
    expect(HSVColor.fromColor(changed!).saturation, lessThan(0.1));
  });
}
