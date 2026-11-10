import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/boot/boot_page.dart';
import '../../features/boot/suspended_page.dart';
import '../../features/catalog/presentation/product_form_page.dart';
import '../../features/customers/presentation/customers_page.dart';
import '../../features/documents/presentation/documents_pages.dart';
import '../../features/home/home_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/orders/presentation/orders_pages.dart';
import '../../features/pos/presentation/cart_page.dart';
import '../../features/pos/presentation/payment_page.dart';
import '../../features/pos/presentation/pos_page.dart';
import '../../features/pos/presentation/receipt_page.dart';
import '../../features/referentials/referential_pages.dart';
import '../../features/settings/appearance_page.dart';
import '../../features/settings/settings_pages.dart';
import '../../features/stock/presentation/stock_adjust_page.dart';
import '../../features/stock/presentation/stock_entry_page.dart';
import '../../features/stock/presentation/variant_stock_page.dart';
import '../../features/sync/sync_page.dart';

abstract final class Routes {
  static const login = '/connexion';
  static const boot = '/demarrage';
  static const onboarding = '/assistant';
  static const suspended = '/suspendu';
  static const home = '/';
  static const sale = '/vente';
  static const cart = '/panier';
  static const payment = '/paiement';
  static const receipt = '/recu';
  static const productForm = '/produit';
  static const stockEntry = '/stock/entree';
  static const stockOut = '/stock/sortie';
  static const inventory = '/stock/inventaire';
  static const variantStock = '/stock/variante';
  static const customers = '/clientes';
  static const customerDetail = '/clientes/detail';
  static const orders = '/commandes';
  static const orderDetail = '/commandes/detail';
  static const documents = '/factures';
  static const documentDetail = '/factures/detail';
  static const referentials = '/referentiels';
  static const settings = '/parametres';
  static const appearance = '/apparence';
  static const notifications = '/notifications';
  static const sync = '/synchronisation';
}

/// Redirige vers la connexion si aucune session n'est ouverte.
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) => Get.find<AuthController>().isSignedIn ? null : const RouteSettings(name: Routes.login);
}

abstract final class AppPages {
  static GetPage<void> _page(String name, Widget Function() page) => GetPage<void>(name: name, page: page, middlewares: [AuthGuard()]);

  static final routes = <GetPage<void>>[
    GetPage<void>(name: Routes.login, page: LoginPage.new),
    _page(Routes.boot, BootPage.new),
    _page(Routes.onboarding, OnboardingPage.new),
    _page(Routes.suspended, SuspendedPage.new),
    _page(Routes.home, HomePage.new),
    _page(Routes.sale, () => const PosPage(standalone: true)),
    _page(Routes.cart, CartPage.new),
    _page(Routes.payment, PaymentPage.new),
    _page(Routes.receipt, ReceiptPage.new),
    _page(Routes.productForm, ProductFormPage.new),
    _page(Routes.stockEntry, StockEntryPage.new),
    _page(Routes.stockOut, () => const StockAdjustPage(inventory: false)),
    _page(Routes.inventory, () => const StockAdjustPage(inventory: true)),
    _page(Routes.variantStock, VariantStockPage.new),
    _page(Routes.customers, CustomersPage.new),
    _page(Routes.customerDetail, CustomerDetailPage.new),
    _page(Routes.orders, OrdersPage.new),
    _page(Routes.orderDetail, OrderDetailPage.new),
    _page(Routes.documents, DocumentsPage.new),
    _page(Routes.documentDetail, DocumentDetailPage.new),
    _page(Routes.referentials, ReferentialsPage.new),
    _page(Routes.settings, SettingsPage.new),
    _page(Routes.appearance, AppearancePage.new),
    _page(Routes.notifications, NotificationsPage.new),
    _page(Routes.sync, SyncPage.new),
  ];
}
