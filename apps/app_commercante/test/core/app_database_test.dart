import 'package:app_commercante/core/db/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

LocalVariantsCompanion variant(String id, {String boutique = 'b1', String? barcode, double stock = 0, double min = 0}) =>
    LocalVariantsCompanion.insert(
      id: id,
      boutiqueId: boutique,
      produitId: 'p-$id',
      libelleAr: 'حقيبة $id',
      libelleFr: 'Sac $id',
      prixVente: 1000,
      codeBarres: Value(barcode),
      enStock: Value(stock),
      stockMinimum: Value(min),
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seed({List<LocalVariantsCompanion> variants = const []}) => db.replaceCatalog(
        'b1',
        categories: [],
        colors: [],
        models: [],
        sizes: [],
        paymentModes: [],
        customers: [],
        products: [],
        variants: variants,
      );

  group('cache catalogue', () {
    test('replaceCatalog remplace uniquement les données de la boutique', () async {
      await seed(variants: [variant('a'), variant('b')]);
      await db.into(db.localVariants).insert(variant('autre', boutique: 'b2'));
      await seed(variants: [variant('c')]);
      final all = await db.select(db.localVariants).get();
      expect(all.map((v) => v.id).toSet(), {'c', 'autre'});
    });

    test('recherche par libellé, SKU ou code-barres et scan exact', () async {
      await seed(variants: [variant('a', barcode: '2900000000011'), variant('b')]);
      expect((await db.watchVariants('b1', query: 'Sac b').first).map((v) => v.id), ['b']);
      expect((await db.watchVariants('b1', query: '29000000000').first).map((v) => v.id), ['a']);
      expect((await db.variantByBarcode('b1', '2900000000011'))?.id, 'a');
      expect(await db.variantByBarcode('b1', 'inconnu'), isNull);
    });

    test('filtre stock bas : rupture ou sous le seuil', () async {
      await seed(variants: [variant('ok', stock: 10, min: 2), variant('bas', stock: 2, min: 2), variant('rupture', stock: 0)]);
      final ids = (await db.watchVariants('b1', lowStockOnly: true).first).map((v) => v.id).toSet();
      expect(ids, {'bas', 'rupture'});
    });

    test('le stock local est décrémenté après une vente hors ligne', () async {
      await seed(variants: [variant('a', stock: 5)]);
      await db.adjustLocalStock('a', -2);
      expect((await db.select(db.localVariants).getSingle()).enStock, 3);
    });
  });

  group('outbox', () {
    OutboxItemsCompanion item(String id, DateTime at, {String boutique = 'b1'}) =>
        OutboxItemsCompanion.insert(id: id, boutiqueId: boutique, kind: 'vente', payload: '{}', createdAt: at);

    test('envoi dans l\'ordre de création, par boutique', () async {
      final t = DateTime(2026, 1, 1);
      await db.enqueue(item('2', t.add(const Duration(minutes: 2))));
      await db.enqueue(item('1', t));
      await db.enqueue(item('x', t, boutique: 'b2'));
      expect((await db.pendingItems('b1')).map((i) => i.id), ['1', '2']);
    });

    test('un UUID rejoué n\'est enregistré qu\'une fois (idempotence locale)', () async {
      final t = DateTime(2026, 1, 1);
      await db.enqueue(item('1', t));
      await db.enqueue(item('1', t));
      expect((await db.pendingItems('b1')).length, 1);
    });

    test('échec métier : sorti de la file d\'envoi, comptabilisé, relançable', () async {
      final t = DateTime(2026, 1, 1);
      await db.enqueue(item('1', t));
      await db.markFailed('1', 'stock_insuffisant');
      expect(await db.pendingItems('b1'), isEmpty);
      expect(await db.watchPendingCount('b1').first, 1);
      await db.retryFailed('1');
      expect((await db.pendingItems('b1')).single.lastError, isNull);
    });

    test('succès : l\'élément est retiré', () async {
      await db.enqueue(item('1', DateTime(2026)));
      await db.removeOutbox('1');
      expect(await db.watchPendingCount('b1').first, 0);
    });
  });

  group('plages de numéros', () {
    test('consomme les numéros dans l\'ordre, puis null quand la réserve est épuisée', () async {
      await db.saveRange(NumberRangesCompanion.insert(boutiqueId: 'b1', type: 'facture', year: 2026, prefix: 'FAC', start: 5, end: 6, next: 5));
      expect(await db.remainingNumbers('b1', 'facture', 2026), 2);
      expect(await db.takeNextNumber('b1', 'facture', 2026), 'FAC-2026-0005');
      expect(await db.takeNextNumber('b1', 'facture', 2026), 'FAC-2026-0006');
      expect(await db.takeNextNumber('b1', 'facture', 2026), isNull);
      expect(await db.remainingNumbers('b1', 'facture', 2026), 0);
    });

    test('plages multiples : la plus ancienne d\'abord, par type et année', () async {
      await db.saveRange(NumberRangesCompanion.insert(boutiqueId: 'b1', type: 'facture', year: 2026, prefix: 'FAC', start: 30, end: 30, next: 30));
      await db.saveRange(NumberRangesCompanion.insert(boutiqueId: 'b1', type: 'facture', year: 2026, prefix: 'FAC', start: 10, end: 10, next: 10));
      await db.saveRange(NumberRangesCompanion.insert(boutiqueId: 'b1', type: 'ticket', year: 2026, prefix: 'TIC', start: 1, end: 1, next: 1));
      expect(await db.takeNextNumber('b1', 'facture', 2026), 'FAC-2026-0010');
      expect(await db.takeNextNumber('b1', 'facture', 2026), 'FAC-2026-0030');
      expect(await db.takeNextNumber('b1', 'ticket', 2025), isNull);
    });
  });

  test('métadonnées : lecture et mise à jour', () async {
    expect(await db.meta('k'), isNull);
    await db.setMeta('k', 'v1');
    await db.setMeta('k', 'v2');
    expect(await db.meta('k'), 'v2');
  });

  test('ventes suspendues : enregistrement et suppression', () async {
    await db.saveSuspended(SuspendedSalesCompanion.insert(id: 's1', boutiqueId: 'b1', cartJson: '{}', createdAt: DateTime(2026)));
    expect((await db.watchSuspended('b1').first).length, 1);
    await db.deleteSuspended('s1');
    expect(await db.watchSuspended('b1').first, isEmpty);
  });
}
