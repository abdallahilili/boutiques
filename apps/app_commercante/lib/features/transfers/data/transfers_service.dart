import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/types/database_types.dart';
import '../domain/transfer_models.dart';

/// Transferts de stock entre deux boutiques (connexion requise : l'opération touche deux boutiques).
class TransfersService {
  TransfersService(this._client);

  final SupabaseClient _client;

  Future<List<TransferSummary>> list(String shopId) async {
    final rows = await _client.rpc(Rpc.listeTransferts, params: {'p_boutique': shopId}) as List;
    return [for (final r in rows) TransferSummary.fromJson(Map<String, dynamic>.from(r as Map))];
  }

  Future<Map<String, dynamic>> detail(String shopId, String id) async => Map<String, dynamic>.from(await _client.rpc(Rpc.detailTransfert, params: {'p_boutique': shopId, 'p_id': id}) as Map);

  Future<Map<String, dynamic>> send(Map<String, dynamic> payload) async => Map<String, dynamic>.from(await _client.rpc(Rpc.envoyerTransfert, params: {'p_donnees': payload}) as Map);

  Future<Map<String, dynamic>> respond(Map<String, dynamic> payload) async => Map<String, dynamic>.from(await _client.rpc(Rpc.repondreTransfert, params: {'p_donnees': payload}) as Map);

  Future<Map<String, dynamic>> cancel(String id) async => Map<String, dynamic>.from(await _client.rpc(Rpc.annulerTransfert, params: {'p_id': id}) as Map);
}
