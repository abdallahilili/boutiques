import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/db/app_database.dart';
import 'core/locale/locale_controller.dart';
import 'core/routing/app_pages.dart';
import 'core/session/shop_controller.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/boot/boot_controller.dart';
import 'features/customers/customers_controller.dart';
import 'features/pos/cart_controller.dart';
import 'core/push/push_service.dart';
import 'features/pos/cash_session_controller.dart';
import 'features/printing/thermal_printer_service.dart';
import 'features/pos/data/sales_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.verify();
  await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabasePublishableKey);
  await Future.wait([initializeDateFormatting('ar'), initializeDateFormatting('fr')]);

  final client = Supabase.instance.client;
  final db = AppDatabase.open();
  final prefs = await SharedPreferences.getInstance();

  // Injection de dépendances GetX : services et contrôleurs de durée de vie « application ».
  Get.put(LocaleController(prefs), permanent: true);
  Get.put(ThemeController(prefs), permanent: true);
  Get.put(ThermalPrinterService(prefs), permanent: true);
  Get.put<SupabaseClient>(client, permanent: true);
  Get.put<AppDatabase>(db, permanent: true);
  final shop = Get.put(ShopController(client, db), permanent: true);
  final sync = Get.put(SyncService(client, db, shop), permanent: true);
  Get.put(PushService(client, shop), permanent: true);
  Get.put(CartController(db, shop, SalesService(db, shop, sync)), permanent: true);
  Get.put(CashSessionController(client, db, shop, sync), permanent: true);
  Get.put(CustomersController(client, db, shop, sync), permanent: true);
  Get.put(BootController(shop, sync, Get.find()), permanent: true);
  Get.put<AuthRepository>(SupabaseAuthRepository(client), permanent: true);
  final auth = Get.put(
    AuthController(
      Get.find<AuthRepository>(),
      onSignedIn: () => Get.offAllNamed(Routes.boot),
      onSignedOut: () {
        shop.reset();
        db.clearCache();
        Get.offAllNamed(Routes.login);
      },
    ),
    permanent: true,
  );

  runApp(BoutiquesApp(initialRoute: auth.isSignedIn ? Routes.boot : Routes.login));
}
