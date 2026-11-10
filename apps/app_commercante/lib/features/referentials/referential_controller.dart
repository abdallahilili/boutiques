import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/shop_controller.dart';
import '../../core/sync/sync_service.dart';
import 'referential_config.dart';

/// Liste et édition d'un référentiel (connexion requise). Les changements sont poussés puis le cache local est rafraîchi.
class ReferentialController extends GetxController {
  ReferentialController(this.config, this._client, this._shop, this._sync);

  final RefConfig config;
  final SupabaseClient _client;
  final ShopController _shop;
  final SyncService _sync;

  final rows = <Map<String, dynamic>>[].obs;
  final loading = false.obs;
  final error = Rxn<Object>();

  bool get canWrite => _shop.can(config.writePermission) && !_shop.readOnly;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      var query = _client.from(config.table).select().eq('boutique_id', _shop.shopId);
      if (config.softDelete) query = query.isFilter('supprime_le', null);
      rows.assignAll(await query.order(config.orderColumn, ascending: true));
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Map<String, dynamic> _clean(Map<String, dynamic> values) => {
        for (final e in values.entries) e.key: (e.value is String && (e.value as String).trim().isEmpty) ? null : e.value,
      };

  Future<Map<String, dynamic>> save(Map<String, dynamic> values, {String? id}) async {
    final payload = _clean(values);
    final Map<String, dynamic> saved;
    if (id == null) {
      if (config.reorderable) payload['ordre'] = rows.length + 1;
      saved = await _client.from(config.table).insert({...payload, 'boutique_id': _shop.shopId, if (config.tracksAuthor) 'cree_par': _shop.userId}).select().single();
    } else {
      saved = await _client.from(config.table).update(payload).eq('id', id).select().single();
    }
    await load();
    _sync.syncAll();
    return saved;
  }

  Future<void> setActive(Map<String, dynamic> row, bool active) async {
    await _client.from(config.table).update({'actif': active}).eq('id', row['id'] as String);
    await load();
    _sync.syncAll();
  }

  /// Suppression : refusée par la base si l'élément est utilisé (clé étrangère) → `false`.
  Future<bool> delete(Map<String, dynamic> row) async {
    try {
      if (config.softDelete) {
        await _client.from(config.table).update({'supprime_le': DateTime.now().toUtc().toIso8601String()}).eq('id', row['id'] as String);
      } else {
        await _client.from(config.table).delete().eq('id', row['id'] as String);
      }
      await load();
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23503') return false;
      rethrow;
    }
  }

  /// Réordonne par glisser-déposer : renumérote `ordre` (1…n) des éléments déplacés.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final moved = rows.removeAt(oldIndex);
    rows.insert(newIndex, moved);
    final updates = <Future<void>>[];
    for (var i = 0; i < rows.length; i++) {
      if (rows[i]['ordre'] != i + 1) {
        rows[i] = {...rows[i], 'ordre': i + 1};
        updates.add(_client.from(config.table).update({'ordre': i + 1}).eq('id', rows[i]['id'] as String).then((_) {}));
      }
    }
    await Future.wait(updates);
    _sync.syncAll();
  }
}
