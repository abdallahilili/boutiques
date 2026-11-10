import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Apparence de l'application : mode clair / sombre / système et couleur principale,
/// mémorisés sur l'appareil (chaque utilisatrice règle son téléphone).
class ThemeController extends GetxController {
  ThemeController(this._prefs)
      : mode = Rx<ThemeMode>(_readMode(_prefs)),
        seed = Rx<Color>(_readSeed(_prefs));

  static const _modeKey = 'theme_mode';
  static const _seedKey = 'theme_couleur';

  /// Couleur d'origine de l'application.
  static const defaultSeed = Color(0xFF8A3B5C);

  /// Couleurs proposées d'un geste ; le sélecteur libre permet toutes les autres.
  static const presets = <Color>[
    defaultSeed,
    Color(0xFFC62828),
    Color(0xFFE65100),
    Color(0xFFF9A825),
    Color(0xFF2E7D32),
    Color(0xFF00796B),
    Color(0xFF1565C0),
    Color(0xFF4527A0),
    Color(0xFF6D4C41),
    Color(0xFF37474F),
  ];

  final SharedPreferences _prefs;
  final Rx<ThemeMode> mode;
  final Rx<Color> seed;

  static ThemeMode _readMode(SharedPreferences prefs) {
    final saved = prefs.getString(_modeKey);
    return ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
  }

  static Color _readSeed(SharedPreferences prefs) {
    final saved = prefs.getInt(_seedKey);
    return saved == null ? defaultSeed : Color(saved).withAlpha(0xFF);
  }

  Future<void> setMode(ThemeMode next) async {
    mode.value = next;
    await _prefs.setString(_modeKey, next.name);
  }

  Future<void> setSeed(Color next) async {
    final opaque = next.withAlpha(0xFF);
    seed.value = opaque;
    await _prefs.setInt(_seedKey, opaque.toARGB32());
  }

  Future<void> resetSeed() async {
    seed.value = defaultSeed;
    await _prefs.remove(_seedKey);
  }
}
