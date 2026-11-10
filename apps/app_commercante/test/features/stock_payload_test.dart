import 'package:app_commercante/core/db/app_database.dart';
import 'package:app_commercante/features/stock/stock_controllers.dart';
import 'package:flutter_test/flutter_test.dart';

LocalVariant variant(String id, {double stock = 5}) => LocalVariant(
      id: id, boutiqueId: 'b1', produitId: 'p', libelleAr: 'حقيبة', libelleFr: 'Sac', prixVente: 1000, stockMinimum: 0, enStock: stock, reserve: 0,
    );

void main() {
  var n = 0;
  String id() => 'id-${n++}';
  setUp(() => n = 0);

  test('réception : UUID d\'appareil, coût, expiration et prix de vente propre', () {
    final lines = [StockLine(variant('v1'), quantity: 10, unitCost: 100, expiry: DateTime(2027, 3, 9), salePrice: 1500)];
    final payload = buildReceptionPayload(id: 'r1', shopId: 'b1', lines: lines, supplierId: 'f1', reference: ' BON-1 ', amountPaid: 500, newId: id);
    expect(payload['id'], 'r1');
    expect(payload['fournisseur_id'], 'f1');
    expect(payload['reference'], 'BON-1');
    expect(payload['montant_paye'], 500);
    expect((payload['lignes'] as List).single, {'id': 'id-0', 'variante_id': 'v1', 'quantite': 10.0, 'cout_unitaire': 100.0, 'date_expiration': '2027-03-09', 'prix_vente': 1500.0});
  });

  test('réception sans fournisseur ni paiement : champs omis', () {
    final payload = buildReceptionPayload(id: 'r1', shopId: 'b1', lines: [StockLine(variant('v1'), quantity: 1, unitCost: 10)], newId: id);
    expect(payload.containsKey('fournisseur_id'), isFalse);
    expect(payload.containsKey('montant_paye'), isFalse);
    expect(((payload['lignes'] as List).single as Map).containsKey('date_expiration'), isFalse);
  });

  test('sortie manuelle : quantité à retirer et motif', () {
    final payload = buildAdjustmentPayload(id: 'a1', shopId: 'b1', type: 'sortie_manuelle', reasonId: 'casse', lines: [StockLine(variant('v1'), quantity: 2)], newId: id);
    expect(payload['type'], 'sortie_manuelle');
    expect(payload['motif_id'], 'casse');
    expect((payload['lignes'] as List).single, {'id': 'id-0', 'variante_id': 'v1', 'quantite': 2.0});
  });

  test('inventaire : quantité comptée, sans motif (résolu côté serveur)', () {
    final payload = buildAdjustmentPayload(id: 'a1', shopId: 'b1', type: 'inventaire', lines: [StockLine(variant('v1'), quantity: 8)], newId: id);
    expect(payload.containsKey('motif_id'), isFalse);
    expect((payload['lignes'] as List).single, {'id': 'id-0', 'variante_id': 'v1', 'quantite_comptee': 8.0});
  });
}
