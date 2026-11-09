import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/locale/locale_controller.dart';
import 'core/routing/app_pages.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

/// Application GetX : arabe par défaut (RTL), bascule en français, thèmes clair/sombre.
class BoutiquesApp extends StatelessWidget {
  const BoutiquesApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final locale = Get.find<LocaleController>();
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: locale.locale.value,
        fallbackLocale: LocaleController.fallback,
        supportedLocales: LocaleController.supported,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: initialRoute,
        getPages: AppPages.routes,
      ),
    );
  }
}
