import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../routing/app_pages.dart';
import '../session/shop_controller.dart';
import '../types/database_types.dart';
import '../widgets/common.dart';

/// Destination ouverte quand la commerçante touche une notification push (selon le `type` des données).
({String route, Object? arguments}) routeForPush(Map<String, dynamic> data) {
  final id = data['transfert_id'] as String?;
  return switch (data['type']) {
    'commande' || 'commande_statut' => (route: Routes.orders, arguments: null),
    'transfert' when id != null => (route: Routes.transferDetail, arguments: id),
    'transfert' => (route: Routes.transfers, arguments: null),
    'ecart_stock' => (route: Routes.sync, arguments: null),
    'impaye_echu' => (route: Routes.customers, arguments: null),
    'abonnement' => (route: Routes.settings, arguments: null),
    _ => (route: Routes.notifications, arguments: null),
  };
}

/// Notifications push (Firebase Cloud Messaging). La configuration Firebase est fournie à la compilation
/// (`--dart-define`, voir `.env.example`) : sans elle, le service reste inactif et les notifications in-app
/// continuent de fonctionner. Le jeton de l'appareil est enregistré côté serveur (`appareils.jeton_fcm`).
class PushService extends GetxService {
  PushService(this._client, this._shop);

  final SupabaseClient _client;
  final ShopController _shop;

  final enabled = false.obs;
  StreamSubscription<String>? _refresh;
  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;

  bool get supported => Env.pushConfigured && (Platform.isAndroid || Platform.isIOS);

  /// À appeler une fois l'appareil enregistré (après la connexion). Les erreurs ne bloquent jamais l'application.
  Future<void> start() async {
    if (!supported) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(apiKey: Env.fcmApiKey, appId: Env.fcmAppId, messagingSenderId: Env.fcmSenderId, projectId: Env.fcmProjectId),
        );
      }
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;
      enabled.value = true;
      // Jeton d'enregistrement FCM classique, accepté par l'API HTTP v1 utilisée par `send-notification`.
      // L'API `register()` / `onRegistered` (identifiant d'installation) est volontairement non utilisée : le
      // serveur envoie à un jeton d'enregistrement.
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) await _register(token);
      // ignore: deprecated_member_use
      _refresh ??= messaging.onTokenRefresh.listen((t) => unawaited(_register(t)));
      _foreground ??= FirebaseMessaging.onMessage.listen(_onForeground);
      _opened ??= FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
      final initial = await messaging.getInitialMessage();
      if (initial != null) _open(initial.data);
    } catch (e) {
      if (kDebugMode) debugPrint('Push désactivé : $e');
    }
  }

  Future<void> _register(String token) async {
    try {
      await _client.rpc(Rpc.enregistrerJetonFcm, params: {'p_appareil': _shop.deviceId, 'p_jeton': token});
    } catch (e) {
      if (kDebugMode) debugPrint('Jeton FCM non enregistré : $e');
    }
  }

  void _onForeground(RemoteMessage message) {
    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title != null || body != null) showMessage([?title, ?body].join(' — '));
  }

  void _open(Map<String, dynamic> data) {
    final target = routeForPush(data);
    Get.toNamed<void>(target.route, arguments: target.arguments);
  }

  @override
  void onClose() {
    _refresh?.cancel();
    _foreground?.cancel();
    _opened?.cancel();
    super.onClose();
  }
}
