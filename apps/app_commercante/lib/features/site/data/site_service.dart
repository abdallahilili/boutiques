import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/types/database_types.dart';
import '../../../core/util/image_format.dart';
import '../domain/site_models.dart';

/// Gestion de la boutique en ligne : paramètres, apparence (brouillon puis publication), bannières, sections,
/// pages, zones de livraison, catalogue. Toutes les écritures passent par la RLS (permission « site.gerer »).
class SiteService {
  SiteService(this._client, this._shopId);

  final SupabaseClient _client;
  final String _shopId;

  // ---------------------------------------------------------------- Paramètres

  Future<Map<String, dynamic>> settings() => _client.from(Tables.parametresSite).select().eq('boutique_id', _shopId).single();

  Future<void> updateSettings(Map<String, dynamic> values) async {
    await _client.from(Tables.parametresSite).update(values).eq('boutique_id', _shopId);
  }

  Future<Map<String, dynamic>?> domain() => _client.from(Tables.domainesBoutique).select().eq('boutique_id', _shopId).eq('principal', true).maybeSingle();

  Future<void> setCustomDomain(String? domain) async {
    await _client.from(Tables.domainesBoutique).update({'domaine_personnalise': domain}).eq('boutique_id', _shopId).eq('principal', true);
  }

  /// Vérifie le DNS du domaine personnalisé et le rattache à l'hébergeur (Edge Function `domain-verify`).
  Future<Map<String, dynamic>> verifyDomain() async {
    final response = await _client.functions.invoke('domain-verify', body: {'boutique_id': _shopId});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> updateShop(Map<String, dynamic> values) async {
    await _client.from(Tables.boutiques).update(values).eq('id', _shopId);
  }

  // ---------------------------------------------------------------- Apparence

  Future<List<Map<String, dynamic>>> themes() => _client.from(Tables.themesSite).select('id,code,nom_ar,nom_fr,plan_minimum').eq('actif', true).order('plan_minimum').order('code');

  Future<void> saveDraft(ThemeDraft draft) => updateSettings({'config_brouillon': draft.toDraftJson()});

  /// Publie le brouillon : thème et configuration passent en production, le brouillon est vidé.
  Future<void> publishDraft(ThemeDraft draft) => updateSettings({'theme_id': draft.themeId, 'config_theme': draft.toConfig(), 'config_brouillon': null});

  /// Envoie une image dans `shop-assets/{boutique}/{dossier}/…` et retourne son chemin.
  Future<String> uploadAsset(Uint8List bytes, String folder) async {
    final format = sniffImageFormat(bytes);
    final path = '$_shopId/$folder/${DateTime.now().millisecondsSinceEpoch}.${format.extension}';
    await _client.storage.from('shop-assets').uploadBinary(path, bytes, fileOptions: FileOptions(contentType: format.mime));
    return path;
  }

  Future<void> removeAsset(String? path) async {
    if (path == null || path.startsWith('http')) return;
    try {
      await _client.storage.from('shop-assets').remove([path]);
    } catch (_) {
      // Fichier orphelin sans conséquence.
    }
  }

  // ---------------------------------------------------------------- Listes ordonnées génériques

  Future<List<Map<String, dynamic>>> rows(String table, {String order = 'ordre'}) => _client.from(table).select().eq('boutique_id', _shopId).order(order).order('cree_le');

  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> values) => _client.from(table).insert({...values, 'boutique_id': _shopId}).select().single();

  Future<void> update(String table, String id, Map<String, dynamic> values) async {
    await _client.from(table).update(values).eq('id', id).eq('boutique_id', _shopId);
  }

  Future<void> delete(String table, String id) async {
    await _client.from(table).delete().eq('id', id).eq('boutique_id', _shopId);
  }

  /// Écrit les nouvelles positions (seules les lignes déplacées sont modifiées).
  Future<void> saveOrder(String table, List<({String id, int order})> updates, {String column = 'ordre'}) async {
    for (final u in updates) {
      await _client.from(table).update({column: u.order}).eq('id', u.id).eq('boutique_id', _shopId);
    }
  }

  // ---------------------------------------------------------------- Catalogue en ligne

  Future<List<Map<String, dynamic>>> products() =>
      _client.from(Tables.produits).select('id,nom_ar,nom_fr,visible_en_ligne,epingle,ordre_epinglage,statut').eq('boutique_id', _shopId).isFilter('supprime_le', null).order('nom_fr');

  Future<void> setProductOnline(String id, {bool? visible, bool? pinned, int? pinOrder}) async {
    final values = <String, dynamic>{'visible_en_ligne': ?visible, 'epingle': ?pinned};
    if (pinned == false) {
      values['ordre_epinglage'] = null;
    } else if (pinned == true && pinOrder != null) {
      values['ordre_epinglage'] = pinOrder;
    }
    if (values.isEmpty) return;
    await _client.from(Tables.produits).update(values).eq('id', id).eq('boutique_id', _shopId);
  }
}
