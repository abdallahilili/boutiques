import 'package:app_commercante/core/db/app_database.dart';
import 'package:app_commercante/features/pos/domain/cart.dart';
import 'package:app_commercante/features/pos/domain/sale_payload.dart';
import 'package:flutter_test/flutter_test.dart';

LocalVariant variant(String id, {double price = 1000, double? promo, DateTime? promoStart, DateTime? promoEnd, double stock = 10}) => LocalVariant(
      id: id, boutiqueId: 'b1', produitId: 'p', libelleAr: 'حقيبة', libelleFr: 'Sac $id', prixVente: price, prixPromo: promo,
      promoDebut: promoStart, promoFin: promoEnd, stockMinimum: 0, enStock: stock, reserve: 0,
    );

PaymentEntry cash(double amount) => PaymentEntry(modeId: 'cash', modeType: 'especes', nameAr: 'نقداً', nameFr: 'Espèces', amount: amount);
PaymentEntry mobile(double amount) => PaymentEntry(modeId: 'bankily', modeType: 'mobile_money', nameAr: null, nameFr: 'Bankily', amount: amount);

void main() {
  final now = DateTime(2026, 6, 1);

  group('prix effectif', () {
    test('promotion active', () => expect(effectivePrice(variant('a', promo: 800), now), 800));
    test('promotion pas encore commencée ou terminée', () {
      expect(effectivePrice(variant('a', promo: 800, promoStart: DateTime(2026, 7)), now), 1000);
      expect(effectivePrice(variant('a', promo: 800, promoEnd: DateTime(2026, 5)), now), 1000);
    });
    test('sans promotion', () => expect(effectivePrice(variant('a'), now), 1000));
  });

  group('panier', () {
    test('ajouter deux fois la même variante incrémente la quantité', () {
      final cart = Cart()..addVariant(variant('a'), now)..addVariant(variant('a'), now);
      expect(cart.lines.length, 1);
      expect(cart.lines.single.quantity, 2);
      expect(cart.total, 2000);
    });

    test('remise de ligne puis remise globale en pourcentage', () {
      final cart = Cart()..addVariant(variant('a'), now)..addVariant(variant('b', price: 500), now);
      cart.lines.first.discount = 100;
      cart.globalDiscountMode = DiscountMode.percent;
      cart.globalDiscountValue = 10;
      expect(cart.subtotal, 1400);
      expect(cart.globalDiscount, 140);
      expect(cart.total, 1260);
      expect(cart.hasDiscount, isTrue);
    });

    test('la remise globale ne peut dépasser le sous-total', () {
      final cart = Cart()..addVariant(variant('a'), now);
      cart.globalDiscountValue = 5000;
      expect(cart.globalDiscount, 1000);
      expect(cart.total, 0);
    });

    test('une remise de ligne ne rend jamais le total négatif', () {
      final cart = Cart()..addVariant(variant('a'), now);
      cart.lines.single.discount = 5000;
      expect(cart.lines.single.net, 0);
    });

    test('prix modifié détecté ; dépassement de stock signalé', () {
      final cart = Cart()..addVariant(variant('a', stock: 1), now);
      cart.lines.single.unitPrice = 900;
      expect(cart.lines.single.priceModified, isTrue);
      cart.lines.single.quantity = 2;
      expect(cart.lines.single.exceedsStock, isTrue);
    });
  });

  group('paiements', () {
    test('deux modes de paiement soldent la vente', () {
      final cart = Cart()..addVariant(variant('a', price: 12000), now);
      cart.addPayment(cash(6000));
      cart.addPayment(mobile(6000));
      expect(cart.paid, 12000);
      expect(cart.remaining, 0);
      expect(cart.hasDebt, isFalse);
    });

    test('espèces remises au-dessus du reste : monnaie rendue, paiement plafonné', () {
      final cart = Cart()..addVariant(variant('a', price: 1500), now);
      final change = cart.addPayment(cash(2000), tendered: 2000);
      expect(change, 500);
      expect(cart.payments.single.amount, 1500);
      expect(cart.remaining, 0);
    });

    test('paiement mobile au-dessus du reste : pas de monnaie', () {
      final cart = Cart()..addVariant(variant('a', price: 1000), now);
      expect(cart.addPayment(mobile(3000)), 0);
      expect(cart.paid, 1000);
    });

    test('paiement partiel : reste dû = dette cliente', () {
      final cart = Cart()..addVariant(variant('a', price: 2000), now);
      cart.addPayment(cash(500));
      expect(cart.remaining, 1500);
      expect(cart.hasDebt, isTrue);
    });

    test('un paiement « crédit » ne compte pas comme encaissé', () {
      final cart = Cart()..addVariant(variant('a', price: 2000), now);
      cart.payments.add(PaymentEntry(modeId: 'credit', modeType: 'credit', nameAr: null, nameFr: 'Crédit', amount: 2000));
      expect(cart.paid, 0);
      expect(cart.remaining, 2000);
    });

    test('même mode ajouté deux fois : cumulé', () {
      final cart = Cart()..addVariant(variant('a', price: 3000), now);
      cart.addPayment(cash(1000));
      cart.addPayment(cash(500));
      expect(cart.payments.length, 1);
      expect(cart.payments.single.amount, 1500);
    });
  });

  group('charge utile de la vente', () {
    test('UUID d\'appareil, numéro de plage, remises et paiements sans crédit', () {
      var n = 0;
      String id() => 'id-${n++}';
      final cart = Cart()..addVariant(variant('a', price: 2000), now);
      cart.lines.single.discount = 100;
      cart.customerId = 'client-1';
      cart.addPayment(cash(1000));
      cart.payments.add(PaymentEntry(modeId: 'credit', modeType: 'credit', nameAr: null, nameFr: 'Crédit', amount: 900));

      final payload = buildSalePayload(cart: cart, saleId: 'sale-1', shopId: 'b1', newId: id, number: 'FAC-2026-0007', deviceId: 'dev-1', sessionId: 's1');

      expect(payload['id'], 'sale-1');
      expect(payload['numero'], 'FAC-2026-0007');
      expect(payload['appareil_id'], 'dev-1');
      expect(payload['client_id'], 'client-1');
      expect(payload['session_caisse_id'], 's1');
      final lines = payload['lignes'] as List;
      expect(lines.single, {'id': 'id-0', 'variante_id': 'a', 'quantite': 1.0, 'prix_unitaire': 2000.0, 'remise': 100.0});
      expect(payload['paiements'], [{'id': 'id-1', 'mode_paiement_id': 'cash', 'montant': 1000.0}]);
    });

    test('sans numéro de plage : le serveur attribue le numéro (aucun appareil envoyé)', () {
      final cart = Cart()..addVariant(variant('a'), now);
      final payload = buildSalePayload(cart: cart, saleId: 's', shopId: 'b1', newId: () => 'x', deviceId: 'dev-1');
      expect(payload.containsKey('numero'), isFalse);
      expect(payload.containsKey('appareil_id'), isFalse);
    });
  });
}
