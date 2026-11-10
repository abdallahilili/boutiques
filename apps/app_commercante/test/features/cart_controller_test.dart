import 'dart:convert';

import 'package:app_commercante/core/db/app_database.dart';
import 'package:app_commercante/core/session/shop_controller.dart';
import 'package:app_commercante/core/sync/sync_service.dart';
import 'package:app_commercante/features/pos/cart_controller.dart';
import 'package:app_commercante/features/pos/data/sales_service.dart';
import 'package:app_commercante/features/pos/domain/cart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeConnectivity implements Connectivity {
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => const Stream.empty();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];
}

LocalVariant variant(String id, {double price = 1000, double stock = 10}) => LocalVariant(
      id: id, boutiqueId: 'b1', produitId: 'p', libelleAr: 'حقيبة', libelleFr: 'Sac $id', prixVente: price, stockMinimum: 0, enStock: stock, reserve: 0,
    );

void main() {
  late AppDatabase db;
  late ShopController shop;
  late CartController controller;
  final now = DateTime(2026, 6, 1, 10);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final client = SupabaseClient('http://localhost:54321', 'cle-publique-de-test');
    shop = ShopController(client, db);
    final sync = SyncService(client, db, shop, connectivity: _FakeConnectivity());
    controller = CartController(db, shop, SalesService(db, shop, sync), clock: () => now);
    for (final id in ['a', 'b']) {
      await db.into(db.localVariants).insert(LocalVariantsCompanion.insert(
        id: id, boutiqueId: 'b1', produitId: 'p', libelleAr: 'حقيبة', libelleFr: 'Sac $id', prixVente: 1000, enStock: const Value(10),
      ));
    }
  });
  tearDown(() => db.close());

  test('le prix et la remise exigent les permissions pos.modifier_prix / pos.remise (vendeuse sans droits)', () {
    shop.permissions.assignAll({'pos.vendre'});
    controller.addVariant(variant('a'));
    final line = controller.cart.lines.single;
    controller.setPrice(line, 10);
    controller.setLineDiscount(line, 500, DiscountMode.amount);
    controller.setGlobalDiscount(50, DiscountMode.percent);
    expect(line.unitPrice, 1000);
    expect(line.discount, 0);
    expect(controller.cart.globalDiscount, 0);
  });

  test('avec les permissions : prix modifié, remise de ligne en pourcentage et remise globale', () {
    shop.permissions.assignAll({'pos.vendre', 'pos.modifier_prix', 'pos.remise'});
    controller.addVariant(variant('a'));
    final line = controller.cart.lines.single;
    controller.setPrice(line, 900);
    controller.setLineDiscount(line, 10, DiscountMode.percent);
    controller.setGlobalDiscount(100, DiscountMode.amount);
    expect(line.unitPrice, 900);
    expect(line.discount, 90);
    expect(controller.cart.total, 710);
  });

  test('la quantité à zéro retire la ligne ; le compteur de version notifie l\'interface', () {
    controller.addVariant(variant('a'));
    final before = controller.version.value;
    controller.setQuantity(controller.cart.lines.single, 0);
    expect(controller.cart.isEmpty, isTrue);
    expect(controller.version.value, greaterThan(before));
  });

  test('vente suspendue puis reprise : lignes, prix, remise et cliente conservés', () async {
    shop.permissions.assignAll({'pos.vendre', 'pos.modifier_prix', 'pos.remise'});
    shop.active.value = null;
    controller.addVariant(variant('a'));
    controller.addVariant(variant('b', price: 500));
    controller.setPrice(controller.cart.lines.first, 950);
    controller.setCustomer('c1', 'Fatima');
    controller.setGlobalDiscount(10, DiscountMode.percent);
    controller.setNote('à emballer');

    final saved = SuspendedSalesCompanion.insert(id: 's1', boutiqueId: 'b1', label: const Value('Fatima'), cartJson: jsonEncode(controller.cart.toJson()), createdAt: now);
    await db.saveSuspended(saved);
    controller.clear();
    expect(controller.cart.isEmpty, isTrue);

    final sale = (await db.watchSuspended('b1').first).single;
    await controller.resume(sale);

    expect(controller.cart.lines.map((l) => (l.variant.id, l.unitPrice)).toList(), [('a', 950.0), ('b', 500.0)]);
    expect(controller.cart.customerName, 'Fatima');
    expect(controller.cart.globalDiscountValue, 10);
    expect(controller.cart.globalDiscountMode, DiscountMode.percent);
    expect(controller.cart.note, 'à emballer');
    expect(await db.watchSuspended('b1').first, isEmpty);
  });
}
