import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:get/get.dart' hide Value;

import '../../../core/db/app_database.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/sync/sync_service.dart';

/// Résumé d'un produit pour la liste (cache local : consultable hors ligne).
class ProductSummary {
  const ProductSummary({
    required this.product,
    required this.variantCount,
    required this.minPrice,
    required this.maxPrice,
    required this.totalStock,
    required this.lowStock,
  });

  final LocalProduct product;
  final int variantCount;
  final double minPrice;
  final double maxPrice;
  final double totalStock;
  final bool lowStock;
}

class ProductsController extends GetxController {
  ProductsController(this._db, this._shop, this._sync);

  final AppDatabase _db;
  final ShopController _shop;
  final SyncService _sync;

  final items = <ProductSummary>[].obs;
  final query = ''.obs;
  final categoryId = RxnString();
  final lowStockOnly = false.obs;
  final categories = <LocalCategory>[].obs;

  @override
  void onInit() {
    super.onInit();
    ever(_sync.lastSync, (_) => reload());
    debounce(query, (_) => reload(), time: const Duration(milliseconds: 250));
    ever(categoryId, (_) => reload());
    ever(lowStockOnly, (_) => reload());
    reload();
  }

  Future<void> reload() async {
    if (_shop.active.value == null) return;
    final shopId = _shop.shopId;
    categories.assignAll(await (_db.select(_db.localCategories)..where((c) => c.boutiqueId.equals(shopId) & c.actif)).get());

    final products = await (_db.select(_db.localProducts)..where((p) => p.boutiqueId.equals(shopId))).get();
    final variants = await (_db.select(_db.localVariants)..where((v) => v.boutiqueId.equals(shopId))).get();
    final byProduct = <String, List<LocalVariant>>{};
    for (final v in variants) {
      byProduct.putIfAbsent(v.produitId, () => []).add(v);
    }

    final text = query.value.trim().toLowerCase();
    final summaries = <ProductSummary>[];
    for (final p in products) {
      if (categoryId.value != null && p.categorieId != categoryId.value) continue;
      final vs = byProduct[p.id] ?? const <LocalVariant>[];
      if (text.isNotEmpty) {
        final haystack = '${p.nomAr ?? ''} ${p.nomFr ?? ''} ${vs.map((v) => '${v.sku ?? ''} ${v.codeBarres ?? ''}').join(' ')}'.toLowerCase();
        if (!haystack.contains(text)) continue;
      }
      final low = vs.any((v) => v.enStock <= 0 || (v.stockMinimum > 0 && v.enStock <= v.stockMinimum));
      if (lowStockOnly.value && !low) continue;
      final prices = vs.map((v) => v.prixVente).toList()..sort();
      summaries.add(ProductSummary(
        product: p,
        variantCount: vs.length,
        minPrice: prices.isEmpty ? 0 : prices.first,
        maxPrice: prices.isEmpty ? 0 : prices.last,
        totalStock: vs.fold(0.0, (sum, v) => sum + v.enStock),
        lowStock: low,
      ));
    }
    summaries.sort((a, b) => (a.product.nomFr ?? a.product.nomAr ?? '').compareTo(b.product.nomFr ?? b.product.nomAr ?? ''));
    items.assignAll(summaries);
  }
}
