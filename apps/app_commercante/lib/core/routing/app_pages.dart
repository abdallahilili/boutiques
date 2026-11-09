import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/home/home_page.dart';

abstract final class Routes {
  static const login = '/connexion';
  static const home = '/';
}

/// Redirige vers la connexion si aucune session n'est ouverte.
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) => Get.find<AuthController>().isSignedIn ? null : const RouteSettings(name: Routes.login);
}

abstract final class AppPages {
  static final routes = [
    GetPage(name: Routes.login, page: LoginPage.new),
    GetPage(name: Routes.home, page: HomePage.new, middlewares: [AuthGuard()]),
  ];
}
