import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/shop_controller.dart';
import '../../core/types/database_types.dart';

/// Transitions autorisées par le serveur (`changer_statut_commande`) : le serveur reste juge, l'app n'affiche que les suites valides.
const Map<String, List<String>> orderTransitions = {
  'nouvelle': ['confirmee', 'annulee'],
  'confirmee': ['en_preparation', 'annulee'],
  'en_preparation': ['prete', 'annulee'],
  'prete': ['expediee', 'livree', 'annulee'],
  'expediee': ['livree'],
};

List<String> nextStatuses(String status, {required bool canManage, required bool canPrepare}) {
  final next = orderTransitions[status] ?? const <String>[];
  if (canManage) return next;
  return canPrepare ? next.where((s) => s == 'en_preparation' || s == 'prete').toList() : const [];
}

/// Commandes en ligne : liste, temps réel (nouvelle commande → alerte sonore et message), repli sur interrogation périodique.
class OrdersController extends GetxController {
  OrdersController(this._client, this._shop);

  final SupabaseClient _client;
  final ShopController _shop;

  final orders = <Map<String, dynamic>>[].obs;
  final loading = false.obs;
  final error = Rxn<Object>();
  final statusFilter = RxnString();
  final realtimeConnected = false.obs;

  RealtimeChannel? _channel;
  Timer? _poll;

  /// Appelé à l'arrivée d'une nouvelle commande (affichage d'un message par la page).
  void Function(Map<String, dynamic> order)? onNewOrder;

  @override
  void onInit() {
    super.onInit();
    load();
    _subscribe();
    // Repli : si le temps réel est coupé, on interroge toutes les 30 s.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!realtimeConnected.value) load(silent: true);
    });
  }

  @override
  void onClose() {
    _channel?.unsubscribe();
    _poll?.cancel();
    super.onClose();
  }

  void _subscribe() {
    _channel = _client
        .channel('commandes-${_shop.shopId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: Tables.commandes,
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'boutique_id', value: _shop.shopId),
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.insert) {
              SystemSound.play(SystemSoundType.alert);
              onNewOrder?.call(payload.newRecord);
            }
            load(silent: true);
          },
        )
        .subscribe((status, _) => realtimeConnected.value = status == RealtimeSubscribeStatus.subscribed);
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) loading.value = true;
    try {
      var q = _client.from(Tables.commandes).select();
      if (statusFilter.value != null) q = q.eq('statut', statusFilter.value!);
      orders.assignAll(await q.order('cree_le', ascending: false).limit(100));
      error.value = null;
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> changeStatus(String orderId, String status, {String? note}) async {
    await _client.rpc(Rpc.changerStatutCommande, params: {'p_commande_id': orderId, 'p_statut': status, 'p_note': note});
    await load(silent: true);
  }

  Future<Map<String, dynamic>> generateInvoice(String orderId, String documentId) async {
    final result = await _client.rpc(Rpc.genererDocumentCommande, params: {
      'p_donnees': {'commande_id': orderId, 'id': documentId},
    }) as Map<String, dynamic>;
    await load(silent: true);
    return result;
  }
}
