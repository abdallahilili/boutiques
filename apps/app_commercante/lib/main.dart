import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/locale/locale_controller.dart';
import 'core/routing/app_pages.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.verify();
  await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabasePublishableKey);

  final prefs = await SharedPreferences.getInstance();
  Get.put(LocaleController(prefs), permanent: true);
  Get.put<AuthRepository>(SupabaseAuthRepository(Supabase.instance.client), permanent: true);
  final auth = Get.put(
    AuthController(
      Get.find<AuthRepository>(),
      onSignedIn: () => Get.offAllNamed(Routes.home),
      onSignedOut: () => Get.offAllNamed(Routes.login),
    ),
    permanent: true,
  );

  runApp(BoutiquesApp(initialRoute: auth.isSignedIn ? Routes.home : Routes.login));
}
