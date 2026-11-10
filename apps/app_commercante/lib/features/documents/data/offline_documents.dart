import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/document_payloads.dart';
import 'documents_service.dart';

/// Consultation hors ligne des 30 derniers documents (cache rempli par la synchronisation).
class OfflineDocuments {
  OfflineDocuments(this._db);

  final AppDatabase _db;

  Future<List<Map<String, dynamic>>> _bundles(String shopId) async {
    final raw = await _db.meta(SyncService.recentDocumentsKey(shopId));
    if (raw == null) return const [];
    return [for (final b in jsonDecode(raw) as List) Map<String, dynamic>.from(b as Map)];
  }

  Future<List<Map<String, dynamic>>> list(String shopId, DocumentFamily family, {bool unpaidOnly = false}) async {
    final documents = [
      for (final b in await _bundles(shopId)) Map<String, dynamic>.from(b['document'] as Map),
    ].where((d) => family.types.contains(d['type'])).where((d) => !unpaidOnly || ((d['reste'] as num?) ?? 0) > 0 && d['statut'] != 'annulee').toList();
    return documents;
  }

  Future<DocumentBundle?> bundle(String shopId, String id) async {
    for (final b in await _bundles(shopId)) {
      final document = Map<String, dynamic>.from(b['document'] as Map);
      if (document['id'] != id) continue;
      List<Map<String, dynamic>> rows(String key) => [for (final r in b[key] as List) Map<String, dynamic>.from(r as Map)];
      return DocumentBundle(document: document, lines: rows('lines'), payments: rows('payments'), derived: const [], sources: const []);
    }
    return null;
  }
}
