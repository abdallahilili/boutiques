import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/types/database_types.dart';
import '../domain/report_models.dart';

/// Rapports calculés côté serveur (connexion requise) : les montants sont nets d'avoirs, les marges
/// n'existent que pour les rôles autorisés à voir les coûts.
class ReportsService {
  ReportsService(this._client);

  final SupabaseClient _client;

  Future<ReportSummary> summary(String shopId, ReportPeriod period) async =>
      ReportSummary.fromJson(Map<String, dynamic>.from(await _client.rpc(Rpc.rapportSynthese, params: period.params(shopId)) as Map));

  List<ReportRow> _rows(Object? data) => [for (final r in data as List) ReportRow.fromJson(Map<String, dynamic>.from(r as Map))];

  Future<List<ReportRow>> sales(String shopId, ReportPeriod period, SalesAxis axis) async =>
      _rows(await _client.rpc(Rpc.rapportVentes, params: {...period.params(shopId), 'p_axe': axis.value}));

  Future<List<ReportRow>> products(String shopId, ReportPeriod period, {required bool dormant}) async =>
      _rows(await _client.rpc(Rpc.rapportProduits, params: {...period.params(shopId), 'p_type': dormant ? 'dormants' : 'meilleurs', 'p_limite': 50}));

  Future<({double? total, List<ReportRow> rows})> stock(String shopId) async {
    final data = Map<String, dynamic>.from(await _client.rpc(Rpc.rapportStock, params: {'p_boutique': shopId}) as Map);
    return (total: data['valeur_totale'] == null ? null : (data['valeur_totale'] as num).toDouble(), rows: _rows(data['lignes']));
  }

  Future<Map<String, dynamic>> unpaid(String shopId) async => Map<String, dynamic>.from(await _client.rpc(Rpc.rapportImpayes, params: {'p_boutique': shopId}) as Map);

  /// Écarts de stock (stock négatif après synchronisation) en attente de validation.
  Future<List<Map<String, dynamic>>> stockDiscrepancies(String shopId) async =>
      [for (final r in await _client.rpc(Rpc.ecartsStock, params: {'p_boutique': shopId}) as List) Map<String, dynamic>.from(r as Map)];

  Future<void> validateDiscrepancy(String shopId, String variantId) async => _client.rpc(Rpc.validerEcartStock, params: {'p_boutique': shopId, 'p_variante': variantId});
}
