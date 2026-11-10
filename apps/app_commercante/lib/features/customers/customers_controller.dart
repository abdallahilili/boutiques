import 'package:drift/drift.dart' show Value;
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/session/shop_controller.dart';
import '../../core/sync/sync_service.dart';
import '../../core/types/database_types.dart';
import '../../core/util/format.dart';

/// Répartition d'un règlement sur les factures impayées, les plus anciennes d'abord.
/// `unpaid` : documents triés du plus ancien au plus récent avec leur reste dû.
List<({String documentId, double amount})> allocatePayment(double amount, List<({String documentId, double remaining})> unpaid) {
  final allocations = <({String documentId, double amount})>[];
  var left = amount;
  for (final doc in unpaid) {
    if (left <= 0) break;
    final applied = left < doc.remaining ? left : doc.remaining;
    if (applied > 0) allocations.add((documentId: doc.documentId, amount: applied));
    left -= applied;
  }
  return allocations;
}

class CustomersController extends GetxController {
  CustomersController(this._client, this._db, this._shop, this._sync);

  final SupabaseClient _client;
  final AppDatabase _db;
  final ShopController _shop;
  final SyncService _sync;

  Stream<List<LocalCustomer>> watch() => _db.watchCustomers(_shop.shopId);

  bool get canWrite => _shop.can('clients.ecrire') && !_shop.readOnly;

  /// Création / modification (connexion requise) puis rafraîchissement du cache.
  Future<Map<String, dynamic>> save(Map<String, dynamic> values, {String? id}) async {
    final clean = {for (final e in values.entries) e.key: (e.value is String && (e.value as String).trim().isEmpty) ? null : e.value};
    if (!_sync.online.value) return _saveQueued(clean, id);
    final Map<String, dynamic> saved;
    try {
      if (id == null) {
        saved = await _client.from(Tables.clients).insert({...clean, 'boutique_id': _shop.shopId, 'cree_par': _shop.userId}).select().single();
      } else {
        saved = await _client.from(Tables.clients).update(clean).eq('id', id).select().single();
      }
    } catch (e) {
      // Réseau coupé en cours d'envoi : la cliente est enregistrée localement et envoyée à la reconnexion.
      if (isTransientError(e)) return _saveQueued(clean, id);
      rethrow;
    }
    await _sync.syncAll();
    return saved;
  }

  /// Hors ligne : écriture dans le cache local puis outbox (RPC idempotente par identifiant de cliente).
  Future<Map<String, dynamic>> _saveQueued(Map<String, dynamic> values, String? id) async {
    final customerId = id ?? const Uuid().v4();
    await _db.into(_db.localCustomers).insertOnConflictUpdate(LocalCustomersCompanion(
      id: Value(customerId),
      boutiqueId: Value(_shop.shopId),
      nomAr: Value(values['nom_ar'] as String?),
      nomFr: Value(values['nom_fr'] as String?),
      telephone: Value(values['telephone'] as String?),
      whatsapp: Value(values['whatsapp'] as String?),
      ville: Value(values['ville'] as String?),
      plafondCredit: Value(values['plafond_credit'] == null ? null : asDouble(values['plafond_credit'])),
    ));
    await _sync.enqueue(OutboxKind.customer, const Uuid().v4(), {...values, 'id': customerId, 'boutique_id': _shop.shopId});
    return {...values, 'id': customerId};
  }

  /// Factures non soldées d'une cliente (serveur), de la plus ancienne à la plus récente.
  Future<List<Map<String, dynamic>>> unpaidInvoices(String customerId) => _client
      .from(Tables.documentsVente)
      .select('id,numero,date_emission,total,paye,reste')
      .eq('client_id', customerId)
      .inFilter('type', ['facture', 'ticket'])
      .neq('statut', 'annulee')
      .gt('reste', 0)
      .order('date_emission');

  Future<List<Map<String, dynamic>>> purchaseHistory(String customerId) => _client
      .from(Tables.documentsVente)
      .select('id,numero,date_emission,total,paye,reste,statut,type')
      .eq('client_id', customerId)
      .inFilter('type', ['facture', 'ticket'])
      .order('date_emission', ascending: false)
      .limit(50);

  /// Encaisse un règlement global : réparti sur les factures impayées, un paiement idempotent (outbox) par facture.
  Future<double> settle(String customerId, String paymentModeId, double amount) async {
    final unpaid = await unpaidInvoices(customerId);
    final allocations = allocatePayment(amount, [for (final d in unpaid) (documentId: d['id'] as String, remaining: asDouble(d['reste']))]);
    var total = 0.0;
    for (final a in allocations) {
      final id = const Uuid().v4();
      await _sync.enqueue(OutboxKind.payment, id, {'id': id, 'document_id': a.documentId, 'mode_paiement_id': paymentModeId, 'montant': a.amount});
      total += a.amount;
    }
    return total;
  }
}
