import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import '../session/shop_controller.dart';
import '../types/database_types.dart';
import '../util/format.dart';

/// Types d'opérations de l'outbox → fonction SQL idempotente correspondante.
abstract final class OutboxKind {
  static const sale = 'vente';
  static const stockReceipt = 'reception';
  static const stockAdjustment = 'ajustement';
  static const payment = 'paiement';
  static const sessionOpen = 'session_ouvrir';
  static const sessionClose = 'session_fermer';
  static const expense = 'depense';
  static const customer = 'client';

  static String rpc(String kind) => switch (kind) {
        sale => Rpc.enregistrerVente,
        stockReceipt => Rpc.recevoirStock,
        stockAdjustment => Rpc.ajusterStock,
        payment => Rpc.enregistrerPaiement,
        sessionOpen => Rpc.ouvrirSessionCaisse,
        sessionClose => Rpc.fermerSessionCaisse,
        expense => Rpc.enregistrerDepense,
        customer => Rpc.enregistrerClient,
        _ => throw ArgumentError('Type d\'opération inconnu : $kind'),
      };

  /// Les RPC de session prennent des paramètres nommés ; les autres reçoivent `{ p_donnees: … }`.
  static Map<String, dynamic> params(String kind, Map<String, dynamic> payload) =>
      (kind == sessionOpen || kind == sessionClose) ? payload : {'p_donnees': payload};
}

/// Erreur réseau ou serveur transitoire (à rejouer plus tard) ; sinon erreur métier définitive
/// (stock insuffisant, droit refusé…) à corriger par la commerçante.
bool isTransientError(Object error) {
  if (error is SocketException || error is TimeoutException || error is AuthException || error is FunctionException) return true;
  if (error is PostgrestException) {
    final code = error.code ?? '';
    return code.startsWith('PGRST3') || code == '57014' || (int.tryParse(code) ?? 0) >= 500;
  }
  // Les erreurs du client HTTP (ClientException) n'ont pas de type commun exporté.
  return error.runtimeType.toString().contains('ClientException');
}

/// Synchronisation : envoi de l'outbox (idempotent) puis rafraîchissement du cache de lecture.
class SyncService extends GetxService {
  SyncService(this._client, this._db, this._shop, {Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final SupabaseClient _client;
  final AppDatabase _db;
  final ShopController _shop;
  final Connectivity _connectivity;

  final syncing = false.obs;
  final online = true.obs;
  final lastSync = Rxn<DateTime>();
  final lastError = RxnString();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      final recovered = isOnline && !online.value;
      online.value = isOnline;
      if (recovered) syncAll();
    });
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => syncAll());
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.onClose();
  }

  Future<void> syncAll() async {
    if (syncing.value || _shop.active.value == null) return;
    syncing.value = true;
    lastError.value = null;
    try {
      await pushOutbox();
      await pullCatalog();
      await pullRecentDocuments();
      await ensureNumberRange(OutboxKindDocument.invoice);
      lastSync.value = DateTime.now();
      online.value = true;
    } catch (e) {
      if (isTransientError(e)) {
        online.value = false;
      } else {
        lastError.value = '$e';
      }
    } finally {
      syncing.value = false;
    }
  }

  // ------------------------------------------------------------------- Envoi

  /// Envoie les opérations en attente, dans l'ordre. Réseau coupé : on s'arrête (reprise plus tard) ;
  /// erreur métier (ex. stock insuffisant) : l'élément est marqué « en échec » pour décision de la commerçante.
  Future<void> pushOutbox() async {
    final items = await _db.pendingItems(_shop.shopId);
    for (final item in items) {
      try {
        await _client.rpc(OutboxKind.rpc(item.kind), params: OutboxKind.params(item.kind, jsonDecode(item.payload) as Map<String, dynamic>));
        await _db.removeOutbox(item.id);
      } on PostgrestException catch (e) {
        if (isTransientError(e)) {
          await _db.markAttempt(item.id, e.message);
          rethrow;
        }
        await _db.markFailed(item.id, e.message);
      } catch (e) {
        if (isTransientError(e)) await _db.markAttempt(item.id, '$e');
        rethrow;
      }
    }
  }

  /// Ajoute une opération à l'outbox puis tente un envoi immédiat (sans bloquer l'écran).
  Future<void> enqueue(String kind, String id, Map<String, dynamic> payload) async {
    await _db.enqueue(OutboxItemsCompanion.insert(
      id: id,
      boutiqueId: _shop.shopId,
      kind: kind,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
    ));
    unawaited(syncAll());
  }

  // ------------------------------------------------------------------- Plages

  /// Garde une réserve de numéros pour les ventes hors ligne (aucun doublon, aucun trou côté serveur).
  Future<void> ensureNumberRange(String type) async {
    final year = DateTime.now().year;
    if (await _db.remainingNumbers(_shop.shopId, type, year) >= 5) return;
    try {
      final result = await _client.rpc(Rpc.reserverPlageNumeros, params: {
        'p_boutique_id': _shop.shopId,
        'p_type': type,
        'p_appareil_id': _shop.deviceId,
        'p_taille': 20,
      }) as Map<String, dynamic>;
      await _db.saveRange(NumberRangesCompanion.insert(
        boutiqueId: _shop.shopId,
        type: type,
        year: result['annee'] as int,
        prefix: result['prefixe'] as String,
        start: result['debut'] as int,
        end: result['fin'] as int,
        next: result['debut'] as int,
      ));
    } on PostgrestException catch (e) {
      // Réserve déjà importante côté serveur : la numérotation en ligne prend le relais.
      if (!(e.message.startsWith('plage_non_epuisee') || e.message.startsWith('appareil_invalide'))) rethrow;
    }
  }

  // ------------------------------------------------------------------- Lecture

  /// Dernières ventes (30 documents avec lignes et paiements), gardées pour la consultation et la réimpression
  /// hors ligne. Stockage clé/valeur : aucun schéma local supplémentaire.
  Future<void> pullRecentDocuments() async {
    final shopId = _shop.shopId;
    final documents = await _client
        .from(Tables.documentsVente)
        .select()
        .inFilter('type', ['facture', 'ticket', 'avoir', 'devis', 'bon_livraison'])
        .eq('boutique_id', shopId)
        .order('date_emission', ascending: false)
        .limit(30);
    if (documents.isEmpty) {
      await _db.setMeta(recentDocumentsKey(shopId), '[]');
      return;
    }
    final ids = [for (final d in documents) d['id'] as String];
    final lines = await _client.from(Tables.lignesDocumentVenteVue).select().inFilter('document_id', ids).order('ordre');
    final payments = await _client.from(Tables.paiements).select().inFilter('document_id', ids);
    final bundles = [
      for (final d in documents)
        {
          'document': d,
          'lines': [for (final l in lines) if (l['document_id'] == d['id']) l],
          'payments': [for (final p in payments) if (p['document_id'] == d['id']) p],
        },
    ];
    await _db.setMeta(recentDocumentsKey(shopId), jsonEncode(bundles));
  }

  /// Clé du cache des documents récents d'une boutique.
  static String recentDocumentsKey(String shopId) => 'recent_documents:$shopId';

  Future<List<Map<String, dynamic>>> _fetchAll(PostgrestTransformBuilder<PostgrestList> Function(int from, int to) page) async {
    const size = 1000;
    final rows = <Map<String, dynamic>>[];
    for (var from = 0;; from += size) {
      final chunk = await page(from, from + size - 1);
      rows.addAll(chunk);
      if (chunk.length < size) return rows;
    }
  }

  /// Recharge le cache local (référentiels, produits, variantes avec stock, clientes).
  Future<void> pullCatalog() async {
    final boutiqueId = _shop.shopId;
    PostgrestFilterBuilder<PostgrestList> table(String name) => _client.from(name).select();

    final categories = await _fetchAll((a, b) => table(Tables.categories).eq('boutique_id', boutiqueId).order('ordre').range(a, b));
    final colors = await _fetchAll((a, b) => table(Tables.couleurs).eq('boutique_id', boutiqueId).order('ordre').range(a, b));
    final models = await _fetchAll((a, b) => table(Tables.modeles).eq('boutique_id', boutiqueId).order('id').range(a, b));
    final sizes = await _fetchAll((a, b) => table(Tables.tailles).eq('boutique_id', boutiqueId).order('ordre').range(a, b));
    final reasons = await _fetchAll((a, b) => table(Tables.motifsMouvement).eq('boutique_id', boutiqueId).order('id').range(a, b));
    final modes = await _fetchAll((a, b) => table(Tables.modesPaiement).eq('boutique_id', boutiqueId).order('ordre').range(a, b));
    final customers = await _fetchAll((a, b) => table(Tables.clients).eq('boutique_id', boutiqueId).isFilter('supprime_le', null).order('id').range(a, b));
    final products = await _fetchAll((a, b) => table(Tables.produits).eq('boutique_id', boutiqueId).isFilter('supprime_le', null).order('id').range(a, b));
    final variants = await _fetchAll((a, b) => table(Tables.variantesProduit).eq('boutique_id', boutiqueId).isFilter('supprime_le', null).eq('actif', true).order('id').range(a, b));
    final images = await _fetchAll((a, b) => _client.from(Tables.imagesProduit).select('produit_id,url,principale,ordre').eq('boutique_id', boutiqueId).order('principale', ascending: false).order('ordre').range(a, b));
    final stock = await _fetchAll((a, b) => _client.from(Tables.stockVariante).select('variante_id,en_stock,reserve').eq('boutique_id', boutiqueId).range(a, b));

    final productById = {for (final p in products) p['id'] as String: p};
    final colorById = {for (final c in colors) c['id'] as String: c};
    final modelById = {for (final m in models) m['id'] as String: m};
    final sizeById = {for (final s in sizes) s['id'] as String: s};
    final stockById = {for (final s in stock) s['variante_id'] as String: s};
    final imageByProduct = <String, String>{};
    for (final i in images) {
      imageByProduct.putIfAbsent(i['produit_id'] as String, () => i['url'] as String);
    }

    String label(Map<String, dynamic> variant, bool arabic) {
      Map<String, dynamic>? product = productById[variant['produit_id']];
      String? pick(Map<String, dynamic>? m) => m == null ? null : (arabic ? (m['nom_ar'] ?? m['nom_fr']) : (m['nom_fr'] ?? m['nom_ar'])) as String?;
      return [
        pick(product),
        pick(modelById[variant['modele_id']]),
        pick(colorById[variant['couleur_id']]),
        pick(sizeById[variant['taille_id']]),
      ].whereType<String>().where((s) => s.isNotEmpty).join(' - ');
    }

    DateTime? date(Object? v) => v == null ? null : DateTime.parse('$v');

    await _db.replaceCatalog(
      boutiqueId,
      categories: [
        for (final c in categories)
          LocalCategoriesCompanion.insert(
            id: c['id'], boutiqueId: boutiqueId, parentId: Value(c['parent_id']), nomAr: Value(c['nom_ar']), nomFr: Value(c['nom_fr']),
            imageUrl: Value(c['image_url']), ordre: Value(c['ordre'] as int), visibleEnLigne: Value(c['visible_en_ligne'] as bool), actif: Value(c['actif'] as bool),
          ),
      ],
      colors: [
        for (final c in colors)
          LocalColorsCompanion.insert(id: c['id'], boutiqueId: boutiqueId, codeHex: c['code_hex'], nomAr: Value(c['nom_ar']), nomFr: Value(c['nom_fr']), ordre: Value(c['ordre'] as int), actif: Value(c['actif'] as bool)),
      ],
      models: [
        for (final m in models)
          LocalModelsCompanion.insert(id: m['id'], boutiqueId: boutiqueId, categorieId: Value(m['categorie_id']), nomAr: Value(m['nom_ar']), nomFr: Value(m['nom_fr']), actif: Value(m['actif'] as bool)),
      ],
      sizes: [
        for (final s in sizes)
          LocalSizesCompanion.insert(id: s['id'], boutiqueId: boutiqueId, nomAr: Value(s['nom_ar']), nomFr: Value(s['nom_fr']), type: Value(s['type']), ordre: Value(s['ordre'] as int), actif: Value(s['actif'] as bool)),
      ],
      paymentModes: [
        for (final m in modes)
          LocalPaymentModesCompanion.insert(
            id: m['id'], boutiqueId: boutiqueId, type: m['type'], nomAr: Value(m['nom_ar']), nomFr: Value(m['nom_fr']),
            parDefaut: Value(m['par_defaut'] as bool), actif: Value(m['actif'] as bool), ordre: Value(m['ordre'] as int),
          ),
      ],
      reasons: [
        for (final r in reasons)
          LocalReasonsCompanion.insert(id: r['id'], boutiqueId: boutiqueId, code: Value(r['code']), nomAr: Value(r['nom_ar']), nomFr: Value(r['nom_fr']), actif: Value(r['actif'] as bool)),
      ],
      customers: [
        for (final c in customers)
          LocalCustomersCompanion.insert(
            id: c['id'], boutiqueId: boutiqueId, nomAr: Value(c['nom_ar']), nomFr: Value(c['nom_fr']), telephone: Value(c['telephone']), whatsapp: Value(c['whatsapp']),
            ville: Value(c['ville']), plafondCredit: Value(c['plafond_credit'] == null ? null : asDouble(c['plafond_credit'])), solde: Value(asDouble(c['solde'])),
          ),
      ],
      products: [
        for (final p in products)
          LocalProductsCompanion.insert(
            id: p['id'], boutiqueId: boutiqueId, categorieId: Value(p['categorie_id']), nomAr: Value(p['nom_ar']), nomFr: Value(p['nom_fr']),
            statut: Value(p['statut']), visibleEnLigne: Value(p['visible_en_ligne'] as bool), imageUrl: Value(imageByProduct[p['id']]),
          ),
      ],
      variants: [
        for (final v in variants)
          if (productById[v['produit_id']]?['statut'] == 'actif')
            LocalVariantsCompanion.insert(
              id: v['id'], boutiqueId: boutiqueId, produitId: v['produit_id'], categorieId: Value(productById[v['produit_id']]?['categorie_id']),
              libelleAr: label(v, true), libelleFr: label(v, false), modeleId: Value(v['modele_id']), couleurId: Value(v['couleur_id']),
              couleurHex: Value(colorById[v['couleur_id']]?['code_hex']), tailleId: Value(v['taille_id']), sku: Value(v['sku']), codeBarres: Value(v['code_barres']),
              prixVente: asDouble(v['prix_vente']), prixPromo: Value(v['prix_promo'] == null ? null : asDouble(v['prix_promo'])),
              promoDebut: Value(date(v['promo_debut'])), promoFin: Value(date(v['promo_fin'])), stockMinimum: Value(asDouble(v['stock_minimum'])),
              imageUrl: Value(v['image_url'] ?? imageByProduct[v['produit_id']]),
              enStock: Value(asDouble(stockById[v['id']]?['en_stock'])), reserve: Value(asDouble(stockById[v['id']]?['reserve'])),
            ),
      ],
    );
    if (kDebugMode) debugPrint('Cache synchronisé : ${variants.length} variante(s)');
  }
}

/// Types de documents numérotés réservables hors ligne.
abstract final class OutboxKindDocument {
  static const invoice = 'facture';
  static const ticket = 'ticket';
}
