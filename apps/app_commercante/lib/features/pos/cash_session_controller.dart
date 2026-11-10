import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/session/shop_controller.dart';
import '../../core/sync/sync_service.dart';
import '../../core/types/database_types.dart';

/// Session de caisse : ouverture avec fond de caisse, clôture avec écart (rapport Z calculé par le serveur).
/// L'ouverture est mise en file d'attente (outbox) : les ventes de la session peuvent donc être faites hors ligne.
class CashSessionController extends GetxController {
  CashSessionController(this._client, this._db, this._shop, this._sync);

  final SupabaseClient _client;
  final AppDatabase _db;
  final ShopController _shop;
  final SyncService _sync;

  /// Identifiant de la session ouverte sur cet appareil (null = aucune).
  final sessionId = RxnString();

  String get _key => 'session_caisse:${_shop.shopId}:${_shop.userId}';

  /// Recharge la session ouverte de cet appareil (après le chargement de la boutique).
  Future<void> restore() async {
    final value = await _db.meta(_key);
    sessionId.value = (value == null || value.isEmpty) ? null : value;
  }

  Future<void> open(double float) async {
    final id = const Uuid().v4();
    await _sync.enqueue(OutboxKind.sessionOpen, id, {'p_boutique_id': _shop.shopId, 'p_id': id, 'p_fond': float, 'p_appareil_id': _shop.deviceId});
    await _db.setMeta(_key, id);
    sessionId.value = id;
  }

  /// Clôture : retourne le rapport Z (nul si hors ligne : la clôture est alors envoyée plus tard).
  Future<Map<String, dynamic>?> close(double counted, {String? notes}) async {
    final id = sessionId.value;
    if (id == null) return null;
    Map<String, dynamic>? report;
    try {
      await _sync.pushOutbox();
      report = await _client.rpc(Rpc.fermerSessionCaisse, params: {'p_session_id': id, 'p_compte': counted, 'p_notes': notes}) as Map<String, dynamic>;
    } catch (_) {
      await _sync.enqueue(OutboxKind.sessionClose, '$id-close', {'p_session_id': id, 'p_compte': counted, 'p_notes': notes});
    }
    await _db.setMeta(_key, '');
    sessionId.value = null;
    return report;
  }
}
