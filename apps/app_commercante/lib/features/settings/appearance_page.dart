import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/locale/locale_controller.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/color_picker.dart';
import '../../l10n/app_localizations.dart';

/// Apparence de l'application sur cet appareil : mode clair / sombre, langue et couleur principale.
class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  final _theme = Get.find<ThemeController>();
  final _locale = Get.find<LocaleController>();
  late Color _color = _theme.seed.value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appearance)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(l10n.themeModeTitle, style: title),
        const SizedBox(height: 8),
        Obx(() => SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined), label: Text(l10n.themeSystem)),
                ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(l10n.themeLight)),
                ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(l10n.themeDark)),
              ],
              selected: {_theme.mode.value},
              onSelectionChanged: (s) => _theme.setMode(s.first),
            )),
        const SizedBox(height: 24),
        Text(l10n.language, style: title),
        const SizedBox(height: 8),
        Obx(() => SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'ar', label: Text(l10n.arabic)),
                ButtonSegment(value: 'fr', label: Text(l10n.french)),
              ],
              selected: {_locale.locale.value.languageCode},
              onSelectionChanged: (s) => _locale.setLocale(Locale(s.first)),
            )),
        const SizedBox(height: 24),
        Text(l10n.appColor, style: title),
        const SizedBox(height: 4),
        Text(l10n.appColorHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        ColorPicker(
          color: _color,
          presets: ThemeController.presets,
          onChanged: (c) => setState(() => _color = c),
          onChangeEnd: _theme.setSeed,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () async {
              await _theme.resetSeed();
              setState(() => _color = _theme.seed.value);
            },
            icon: const Icon(Icons.restart_alt),
            label: Text(l10n.resetColor),
          ),
        ),
      ]),
    );
  }
}
