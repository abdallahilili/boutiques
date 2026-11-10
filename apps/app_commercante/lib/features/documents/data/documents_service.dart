import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/types/database_types.dart';
import '../../../core/util/format.dart';
import '../domain/document_payloads.dart';

/// Document enregistré avec ses lignes, ses paiements et ses liens (devis → BL → facture → avoir).
class DocumentBundle {
  const DocumentBundle({required this.document, required this.lines, required this.payments, required this.derived, required this.sources});

  final Map<String, dynamic> document;
  final List<Map<String, dynamic>> lines;
  final List<Map<String, dynamic>> payments;

  /// Documents créés à partir de celui-ci (numéro, type, statut).
  final List<Map<String, dynamic>> derived;

  /// Documents dont celui-ci est issu.
  final List<Map<String, dynamic>> sources;

  String get id => document['id'] as String;
  String get type => document['type'] as String;
  String get status => document['statut'] as String;

  /// Vrai si un document non annulé a déjà été créé depuis celui-ci (conversion unique).
  bool get hasActiveDerived => derived.any((d) => d['statut'] != 'annulee' && (d['type'] == 'bon_livraison' || d['type'] == 'facture'));
}

/// Accès serveur aux devis, bons de livraison, factures et avoirs. Les opérations sont des fonctions SQL
/// transactionnelles et idempotentes (l'identifiant UUID est généré par l'appelant).
class DocumentsService {
  DocumentsService(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> list(DocumentFamily family, {bool unpaidOnly = false, int limit = 100}) {
    var query = _client.from(Tables.documentsVente).select('id,numero,type,statut,date_emission,date_echeance,total,reste,client_id,entete').inFilter('type', family.types);
    if (unpaidOnly) query = query.gt('reste', 0).neq('statut', 'annulee');
    return query.order('date_emission', ascending: false).limit(limit);
  }

  Future<DocumentBundle> load(String id) async {
    final document = await _client.from(Tables.documentsVente).select().eq('id', id).single();
    final lines = await _client.from(Tables.lignesDocumentVenteVue).select().eq('document_id', id).order('ordre');
    final payments = await _client.from(Tables.paiements).select().eq('document_id', id).order('paye_le');
    final links = await _client.from(Tables.documentsLiens).select('document_id,source_id').or('document_id.eq.$id,source_id.eq.$id');
    final derivedIds = [for (final l in links) if (l['source_id'] == id) l['document_id'] as String];
    final sourceIds = [for (final l in links) if (l['document_id'] == id) l['source_id'] as String];
    Future<List<Map<String, dynamic>>> summaries(List<String> ids) =>
        ids.isEmpty ? Future.value(const []) : _client.from(Tables.documentsVente).select('id,numero,type,statut').inFilter('id', ids);
    return DocumentBundle(document: document, lines: lines, payments: payments, derived: await summaries(derivedIds), sources: await summaries(sourceIds));
  }

  Future<Map<String, dynamic>> _rpc(String name, Map<String, dynamic> params) async => Map<String, dynamic>.from(await _client.rpc(name, params: params) as Map);

  Future<Map<String, dynamic>> createQuote(Map<String, dynamic> payload) => _rpc(Rpc.creerDevis, {'p_donnees': payload});

  Future<Map<String, dynamic>> createDeliveryNote(Map<String, dynamic> payload) => _rpc(Rpc.creerBonLivraison, {'p_donnees': payload});

  Future<Map<String, dynamic>> setQuoteStatus(String id, String status) => _rpc(Rpc.changerStatutDevis, {'p_id': id, 'p_statut': status});

  Future<Map<String, dynamic>> setDeliveryStatus(String id, String status) => _rpc(Rpc.changerStatutBonLivraison, {'p_id': id, 'p_statut': status});

  /// Convertit un devis (en BL ou en facture) ou regroupe un ou plusieurs BL en une facture.
  Future<Map<String, dynamic>> convert({required String newId, required List<String> sourceIds, required String target, DateTime? dueDate, String? sessionId, List<Map<String, dynamic>> payments = const []}) =>
      _rpc(Rpc.convertirDocument, {
        'p_donnees': {
          'id': newId,
          'type_cible': target,
          'source_ids': sourceIds,
          if (dueDate != null) 'date_echeance': '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
          'session_caisse_id': ?sessionId,
          if (payments.isNotEmpty) 'paiements': payments,
        },
      });

  Future<Map<String, dynamic>> createCreditNote(Map<String, dynamic> payload) => _rpc(Rpc.creerAvoir, {'p_donnees': payload});

  Future<Map<String, dynamic>> cancel(String id, String reason) => _rpc(Rpc.annulerDocument, {'p_id': id, 'p_motif': reason});

  /// Lignes d'une facture avec la quantité déjà avoirée (avoirs non annulés liés à la facture).
  Future<List<CreditableLine>> creditableLines(String invoiceId) async {
    final lines = await _client.from(Tables.lignesDocumentVenteVue).select().eq('document_id', invoiceId).order('ordre');
    final credits = await _client.from(Tables.documentsVente).select('id').eq('document_source_id', invoiceId).eq('type', 'avoir').neq('statut', 'annulee');
    final credited = <String, double>{};
    if (credits.isNotEmpty) {
      final creditLines = await _client.from(Tables.lignesDocumentVenteVue).select('ligne_source_id,quantite').inFilter('document_id', [for (final c in credits) c['id'] as String]);
      for (final l in creditLines) {
        final source = l['ligne_source_id'] as String?;
        if (source != null) credited[source] = (credited[source] ?? 0) + asDouble(l['quantite']);
      }
    }
    return [
      for (final l in lines)
        CreditableLine(
          id: l['id'] as String,
          labelAr: (l['libelle_ar'] ?? l['libelle_fr'] ?? '') as String,
          labelFr: (l['libelle_fr'] ?? l['libelle_ar'] ?? '') as String,
          quantity: asDouble(l['quantite']),
          unitPrice: asDouble(l['prix_unitaire']),
          discount: asDouble(l['remise']),
          alreadyCredited: credited[l['id']] ?? 0,
        ),
    ];
  }
}
