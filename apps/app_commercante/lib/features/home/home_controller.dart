import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/shop_controller.dart';
import '../../core/types/database_types.dart';
import '../../core/util/format.dart';

/// Indicateurs de l'accueil. Les montants sont nuls pour les rôles sans « rapports.financiers ».
class DashboardStats {
  const DashboardStats({
    this.revenueToday,
    this.revenueWeek,
    this.revenueMonth,
    this.unpaid,
    required this.salesToday,
    required this.outOfStock,
    required this.lowStock,
    required this.ordersToProcess,
  });

  final double? revenueToday;
  final double? revenueWeek;
  final double? revenueMonth;
  final double? unpaid;
  final int salesToday;
  final int outOfStock;
  final int lowStock;
  final int ordersToProcess;

  bool get hasFinancials => revenueToday != null;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    double? money(String key) => json[key] == null ? null : asDouble(json[key]);
    int count(String key) => asDouble(json[key]).toInt();
    return DashboardStats(
      revenueToday: money('ca_jour'),
      revenueWeek: money('ca_semaine'),
      revenueMonth: money('ca_mois'),
      unpaid: money('impayes'),
      salesToday: count('nb_ventes_jour'),
      outOfStock: count('ruptures'),
      lowStock: count('sous_seuil'),
      ordersToProcess: count('commandes_a_traiter'),
    );
  }
}

class HomeController extends GetxController {
  HomeController(this._client, this._shop);

  final SupabaseClient _client;
  final ShopController _shop;

  final stats = Rxn<DashboardStats>();
  final loading = false.obs;
  final error = Rxn<Object>();

  Future<void> load() async {
    if (loading.value || _shop.active.value == null) return;
    loading.value = true;
    error.value = null;
    try {
      final json = await _client.rpc(Rpc.tableauDeBord, params: {'p_boutique_id': _shop.shopId}) as Map<String, dynamic>;
      stats.value = DashboardStats.fromJson(json);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }
}
