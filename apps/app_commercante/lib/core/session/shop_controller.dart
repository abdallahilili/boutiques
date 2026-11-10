import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../types/database_types.dart';

/// Boutique active, permissions de l'utilisatrice et état d'abonnement (lecture seule si suspendue).
class ShopController extends GetxController {
  ShopController(this._client, this._db);

  final SupabaseClient _client;
  final AppDatabase _db;

  final shops = <BoutiquesRow>[].obs;
  final active = Rxn<BoutiquesRow>();
  final permissions = <String>{}.obs;
  final loaded = false.obs;
  String deviceId = '';

  String get shopId => active.value!.id;
  String get currency => active.value?.devise ?? 'MRU';
  String get userId => _client.auth.currentUser!.id;

  /// Décimales d'affichage : réglage de la boutique, sinon 0 pour MRU et 2 pour les autres devises.
  int get decimals {
    final settings = active.value?.parametres;
    final value = settings is Map ? settings['decimales'] : null;
    return value is int ? value : (currency == 'MRU' ? 0 : 2);
  }

  bool can(String permission) => permissions.contains(permission);

  /// Suspendue ou fermée : consultation seulement.
  bool get readOnly => switch (active.value?.statut) {
        StatutBoutique.suspendu || StatutBoutique.ferme => true,
        _ => false,
      };

  bool get inGrace => active.value?.statut == StatutBoutique.grace;

  bool get onboardingDone {
    final settings = active.value?.parametres;
    return settings is Map && settings['onboarding_termine'] == true;
  }

  bool get negativeStockAllowed {
    final settings = active.value?.parametres;
    return settings is Map && settings['stock_negatif_autorise'] == true;
  }

  Future<void> load() async {
    deviceId = await _db.meta('device_id') ?? const Uuid().v4();
    await _db.setMeta('device_id', deviceId);

    final rows = await _client.from(Tables.boutiques).select().order('cree_le');
    shops.value = rows.map<BoutiquesRow>(BoutiquesRow.depuisJson).toList();
    final savedId = await _db.meta('boutique_active');
    final chosen = shops.firstWhereOrNull((s) => s.id == savedId) ?? shops.firstOrNull;
    if (chosen != null) await select(chosen.id);
    loaded.value = true;
  }

  Future<void> select(String id) async {
    active.value = shops.firstWhere((s) => s.id == id);
    await _db.setMeta('boutique_active', id);
    await refreshPermissions();
  }

  Future<void> refreshPermissions() async {
    final result = await _client.rpc(Rpc.mesPermissions, params: {'p_boutique': shopId});
    permissions.assignAll((result as List).cast<String>());
  }

  /// Recharge la boutique active (statut d'abonnement, paramètres) depuis le serveur.
  Future<void> refreshActive() async {
    final row = await _client.from(Tables.boutiques).select().eq('id', shopId).single();
    final fresh = BoutiquesRow.depuisJson(row);
    shops[shops.indexWhere((s) => s.id == fresh.id)] = fresh;
    active.value = fresh;
  }

  /// Fournisseurs de la boutique (liste vide hors ligne : le fournisseur reste facultatif).
  Future<List<Map<String, dynamic>>> loadSuppliers() async {
    try {
      return await _client.from(Tables.fournisseurs).select().eq('boutique_id', shopId).isFilter('supprime_le', null).order('nom_fr');
    } catch (_) {
      return const [];
    }
  }

  /// Enregistre cet appareil (identité pour les plages de numéros hors ligne et le jeton FCM futur).
  Future<void> registerDevice(String platform) async {
    await _client.from(Tables.appareils).upsert({
      'id': deviceId,
      'utilisateur_id': userId,
      'boutique_id': shopId,
      'plateforme': platform,
      'derniere_activite': DateTime.now().toUtc().toIso8601String(),
    });
  }

  void reset() {
    shops.clear();
    active.value = null;
    permissions.clear();
    loaded.value = false;
  }
}
