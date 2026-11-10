import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LocalCategories,
    LocalColors,
    LocalModels,
    LocalSizes,
    LocalPaymentModes,
    LocalReasons,
    LocalCustomers,
    LocalProducts,
    LocalVariants,
    OutboxItems,
    SuspendedSales,
    NumberRanges,
    MetaEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Base de production (SQLite sur l'appareil).
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'boutiques'));

  @override
  int get schemaVersion => 1;

  // ---------------------------------------------------------------- Métadonnées

  Future<String?> meta(String key) async =>
      (await (select(metaEntries)..where((m) => m.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setMeta(String key, String value) =>
      into(metaEntries).insertOnConflictUpdate(MetaEntriesCompanion.insert(key: key, value: value));

  // -------------------------------------------------------------- Cache lecture

  /// Purge le cache de lecture à la déconnexion (aucune donnée ne passe d'un compte à l'autre).
  /// L'outbox, les ventes suspendues et les plages de numéros sont conservés : rien n'est perdu.
  Future<void> clearCache() => transaction(() async {
        await delete(localCategories).go();
        await delete(localColors).go();
        await delete(localModels).go();
        await delete(localSizes).go();
        await delete(localPaymentModes).go();
        await delete(localReasons).go();
        await delete(localCustomers).go();
        await delete(localProducts).go();
        await delete(localVariants).go();
      });

  /// Remplace le cache d'une boutique en une transaction (le serveur fait foi).
  Future<void> replaceCatalog(
    String boutiqueId, {
    required List<LocalCategoriesCompanion> categories,
    required List<LocalColorsCompanion> colors,
    required List<LocalModelsCompanion> models,
    required List<LocalSizesCompanion> sizes,
    required List<LocalPaymentModesCompanion> paymentModes,
    List<LocalReasonsCompanion> reasons = const [],
    required List<LocalCustomersCompanion> customers,
    required List<LocalProductsCompanion> products,
    required List<LocalVariantsCompanion> variants,
  }) {
    return transaction(() async {
      Future<void> swap<T extends Table, D>(TableInfo<T, D> table, GeneratedColumn<String> col, List<Insertable<D>> rows) async {
        await (delete(table)..where((_) => col.equals(boutiqueId))).go();
        await batch((b) => b.insertAll(table, rows));
      }

      await swap(localCategories, localCategories.boutiqueId, categories);
      await swap(localColors, localColors.boutiqueId, colors);
      await swap(localModels, localModels.boutiqueId, models);
      await swap(localSizes, localSizes.boutiqueId, sizes);
      await swap(localPaymentModes, localPaymentModes.boutiqueId, paymentModes);
      await swap(localReasons, localReasons.boutiqueId, reasons);
      await swap(localCustomers, localCustomers.boutiqueId, customers);
      await swap(localProducts, localProducts.boutiqueId, products);
      await swap(localVariants, localVariants.boutiqueId, variants);
    });
  }

  Stream<List<LocalCategory>> watchCategories(String boutiqueId) =>
      (select(localCategories)..where((c) => c.boutiqueId.equals(boutiqueId) & c.actif)..orderBy([(c) => OrderingTerm.asc(c.ordre)])).watch();

  Stream<List<LocalPaymentMode>> watchPaymentModes(String boutiqueId) =>
      (select(localPaymentModes)..where((m) => m.boutiqueId.equals(boutiqueId) & m.actif)..orderBy([(m) => OrderingTerm.asc(m.ordre)])).watch();

  Stream<List<LocalReason>> watchReasons(String boutiqueId) =>
      (select(localReasons)..where((r) => r.boutiqueId.equals(boutiqueId) & r.actif)).watch();

  Stream<List<LocalCustomer>> watchCustomers(String boutiqueId) =>
      (select(localCustomers)..where((c) => c.boutiqueId.equals(boutiqueId))..orderBy([(c) => OrderingTerm.asc(c.nomFr), (c) => OrderingTerm.asc(c.nomAr)])).watch();

  Stream<List<LocalVariant>> watchVariants(String boutiqueId, {String? query, String? categoryId, bool lowStockOnly = false}) {
    final q = select(localVariants)..where((v) => v.boutiqueId.equals(boutiqueId));
    if (categoryId != null) q.where((v) => v.categorieId.equals(categoryId));
    if (lowStockOnly) q.where((v) => v.enStock.isSmallerOrEqual(v.stockMinimum) | v.enStock.isSmallerOrEqualValue(0));
    final text = query?.trim();
    if (text != null && text.isNotEmpty) {
      final like = '%$text%';
      q.where((v) => v.libelleAr.like(like) | v.libelleFr.like(like) | v.sku.like(like) | v.codeBarres.like(like));
    }
    q.orderBy([(v) => OrderingTerm.asc(v.libelleFr)]);
    return q.watch();
  }

  Future<LocalVariant?> variantByBarcode(String boutiqueId, String code) =>
      (select(localVariants)..where((v) => v.boutiqueId.equals(boutiqueId) & (v.codeBarres.equals(code) | v.sku.equals(code)))).getSingleOrNull();

  Future<List<LocalVariant>> variantsOfProduct(String productId) =>
      (select(localVariants)..where((v) => v.produitId.equals(productId))).get();

  /// Décrémente le stock affiché après une vente enregistrée hors ligne (le serveur recalcule à la synchronisation).
  Future<void> adjustLocalStock(String variantId, double delta) async {
    await customUpdate(
      'UPDATE local_variants SET en_stock = en_stock + ? WHERE id = ?',
      variables: [Variable<double>(delta), Variable<String>(variantId)],
      updates: {localVariants},
    );
  }

  // --------------------------------------------------------------------- Outbox

  Future<void> enqueue(OutboxItemsCompanion item) => into(outboxItems).insert(item, mode: InsertMode.insertOrIgnore);

  /// Éléments à envoyer, dans l'ordre de création (une session ouverte doit précéder ses ventes).
  Future<List<OutboxItem>> pendingItems(String boutiqueId) =>
      (select(outboxItems)..where((o) => o.boutiqueId.equals(boutiqueId) & o.status.equals('pending'))..orderBy([(o) => OrderingTerm.asc(o.createdAt)])).get();

  Stream<int> watchPendingCount(String boutiqueId) =>
      (select(outboxItems)..where((o) => o.boutiqueId.equals(boutiqueId) & o.status.isIn(['pending', 'failed']))).watch().map((l) => l.length);

  Stream<List<OutboxItem>> watchFailedItems(String boutiqueId) =>
      (select(outboxItems)..where((o) => o.boutiqueId.equals(boutiqueId) & o.status.equals('failed'))).watch();

  Future<void> removeOutbox(String id) => (delete(outboxItems)..where((o) => o.id.equals(id))).go();

  Future<void> markFailed(String id, String error) => (update(outboxItems)..where((o) => o.id.equals(id))).write(
        OutboxItemsCompanion(status: const Value('failed'), lastError: Value(error)),
      );

  Future<void> markAttempt(String id, String? error) async {
    await customUpdate(
      'UPDATE outbox_items SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      variables: [Variable<String>(error), Variable<String>(id)],
      updates: {outboxItems},
    );
  }

  Future<void> retryFailed(String id) =>
      (update(outboxItems)..where((o) => o.id.equals(id))).write(const OutboxItemsCompanion(status: Value('pending'), lastError: Value(null)));

  // ------------------------------------------------------------ Ventes suspendues

  Stream<List<SuspendedSale>> watchSuspended(String boutiqueId) =>
      (select(suspendedSales)..where((s) => s.boutiqueId.equals(boutiqueId))..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).watch();

  Future<void> saveSuspended(SuspendedSalesCompanion sale) => into(suspendedSales).insertOnConflictUpdate(sale);

  Future<void> deleteSuspended(String id) => (delete(suspendedSales)..where((s) => s.id.equals(id))).go();

  // ------------------------------------------------------------ Plages de numéros

  Future<void> saveRange(NumberRangesCompanion range) => into(numberRanges).insertOnConflictUpdate(range);

  /// Numéros encore disponibles dans les plages réservées pour ce type et cette année.
  Future<int> remainingNumbers(String boutiqueId, String type, int year) async {
    final ranges = await (select(numberRanges)..where((r) => r.boutiqueId.equals(boutiqueId) & r.type.equals(type) & r.year.equals(year))).get();
    return ranges.fold<int>(0, (sum, r) => sum + (r.end - r.next + 1).clamp(0, 1 << 30));
  }

  /// Prend le prochain numéro d'une plage réservée (`FAC-2026-0014`), ou null si la réserve est épuisée.
  Future<String?> takeNextNumber(String boutiqueId, String type, int year) {
    return transaction(() async {
      final ranges = await (select(numberRanges)
            ..where((r) => r.boutiqueId.equals(boutiqueId) & r.type.equals(type) & r.year.equals(year) & r.next.isSmallerOrEqual(r.end))
            ..orderBy([(r) => OrderingTerm.asc(r.start)])
            ..limit(1))
          .get();
      if (ranges.isEmpty) return null;
      final range = ranges.single;
      await (update(numberRanges)..where((r) => r.boutiqueId.equals(boutiqueId) & r.type.equals(type) & r.year.equals(year) & r.start.equals(range.start)))
          .write(NumberRangesCompanion(next: Value(range.next + 1)));
      return formatDocumentNumber(range.prefix, year, range.next);
    });
  }
}

/// Format serveur : `PREFIXE-AAAA-NNNN` (au moins 4 chiffres).
String formatDocumentNumber(String prefix, int year, int number) => '$prefix-$year-${number.toString().padLeft(4, '0')}';
