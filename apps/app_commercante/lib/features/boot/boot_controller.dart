import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

import '../../core/push/push_service.dart';
import '../../core/session/shop_controller.dart';
import '../pos/cash_session_controller.dart';
import '../../core/sync/sync_service.dart';

enum BootDestination { home, onboarding, suspended, noShop }

/// Démarrage après connexion : charge la boutique et les droits, enregistre l'appareil, lance la synchronisation,
/// puis choisit l'écran (assistant de démarrage, écran d'abonnement suspendu ou accueil).
class BootController extends GetxController {
  BootController(this._shop, this._sync, this._cashSession);

  final ShopController _shop;
  final SyncService _sync;
  final CashSessionController _cashSession;

  final error = Rxn<Object>();
  bool _suspendedAcknowledged = false;

  Future<BootDestination> start() async {
    error.value = null;
    await _shop.load();
    if (_shop.active.value == null) return BootDestination.noShop;
    await _cashSession.restore();
    // L'appareil est enregistré avant le jeton FCM (le jeton est rattaché à cette ligne).
    unawaited(_shop.registerDevice(Platform.isIOS ? 'ios' : 'android').then((_) async {
      if (Get.isRegistered<PushService>()) await Get.find<PushService>().start();
    }).catchError((Object _) {}));
    unawaited(_sync.syncAll());
    return destination();
  }

  BootDestination destination() {
    if (_shop.readOnly && !_suspendedAcknowledged) return BootDestination.suspended;
    if (!_shop.onboardingDone && _shop.can('parametres.gerer')) return BootDestination.onboarding;
    return BootDestination.home;
  }

  void acknowledgeSuspension() => _suspendedAcknowledged = true;
}
