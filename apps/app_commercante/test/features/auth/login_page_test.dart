import 'package:app_commercante/core/locale/locale_controller.dart';
import 'package:app_commercante/features/auth/data/auth_repository.dart';
import 'package:app_commercante/features/auth/presentation/auth_controller.dart';
import 'package:app_commercante/features/auth/presentation/login_page.dart';
import 'package:app_commercante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingRepository implements AuthRepository {
  final calls = <(String, String)>[];
  LoginException? toThrow;

  @override
  bool get isSignedIn => false;

  @override
  Future<void> signIn({required String phone, required String pin}) async {
    calls.add((phone, pin));
    final error = toThrow;
    if (error != null) throw error;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  late _RecordingRepository repo;

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    Get.put(LocaleController(await SharedPreferences.getInstance()));
    repo = _RecordingRepository();
    Get.put(AuthController(repo, onSignedIn: () {}, onSignedOut: () {}));
    final locale = Get.find<LocaleController>();
    await tester.pumpWidget(
      Obx(
        () => MaterialApp(
          locale: locale.locale.value,
          supportedLocales: LocaleController.supported,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(Get.reset);

  testWidgets('écran en arabe par défaut, mise en page de droite à gauche', (tester) async {
    await pump(tester);
    expect(find.text('تسجيل الدخول'), findsWidgets);
    expect(Directionality.of(tester.element(find.byType(Scaffold))), TextDirection.rtl);
  });

  testWidgets('la bascule en français passe en gauche-droite', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(find.text('Se connecter'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(Scaffold))), TextDirection.ltr);
  });

  testWidgets('validation : téléphone et code à 4 chiffres requis', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('أدخل رقم الهاتف'), findsOneWidget);
    expect(find.text('الرمز يتكون من 4 أرقام'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('connexion : envoie le téléphone et le code, affiche l\'erreur serveur', (tester) async {
    await pump(tester);
    repo.toThrow = const LoginException(AuthFailure.invalidCredentials);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '36000001');
    await tester.enterText(fields.at(1), '1234');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(repo.calls, [('36000001', '1234')]);
    expect(find.text('رقم الهاتف أو الرمز غير صحيح'), findsOneWidget);
  });

  testWidgets('le code est limité à 4 chiffres', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).at(1), '12ab345678');
    expect(tester.widget<TextFormField>(find.byType(TextFormField).at(1)).controller!.text, '1234');
  });
}
