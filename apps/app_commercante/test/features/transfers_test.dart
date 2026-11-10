import 'package:app_commercante/features/transfers/domain/transfer_models.dart';
import 'package:flutter_test/flutter_test.dart';

TransferDraftLine line(String id, {double qty = 1, double price = 300, double available = 10}) => TransferDraftLine(variantId: id, labelAr: 'منتج', labelFr: 'Produit', available: available, price: price, quantity: qty);

void main() {
  group('destinataire', () {
    test('un numéro de téléphone (avec espaces ou +) est reconnu', () {
      expect(recipientFromInput('+222 36 00 00 02'), {'telephone': '22236000002'});
      expect(recipientFromInput('36000002'), {'telephone': '36000002'});
    });

    test('un code boutique est mis en majuscules', () {
      expect(recipientFromInput(' ab12cd '), {'code_boutique': 'AB12CD'});
    });
  });

  group('TransferDraft', () {
    test('total, cumul des lignes identiques et validité', () {
      final draft = TransferDraft(recipient: 'AB12CD');
      expect(draft.isValid, isFalse);
      draft.addOrIncrement(line('a', qty: 2));
      draft.addOrIncrement(line('a', qty: 1));
      draft.addOrIncrement(line('b', price: 100));
      expect(draft.lines, hasLength(2));
      expect(draft.total, 3 * 300 + 100);
      expect(draft.isValid, isTrue);
    });

    test('destinataire trop courte : invalide', () {
      expect((TransferDraft(recipient: 'AB')..lines.add(line('a'))).isValid, isFalse);
    });

    test('charge utile : identifiant, boutique, destinataire, lignes et note', () {
      final draft = TransferDraft(recipient: 'ab12cd', note: ' urgent ')..lines.add(line('a', qty: 4, price: 300));
      expect(draft.toPayload(id: 't-1', shopId: 's-1'), {
        'id': 't-1',
        'boutique_id': 's-1',
        'destinataire': {'code_boutique': 'AB12CD'},
        'note': 'urgent',
        'lignes': [
          {'variante_id': 'a', 'quantite': 4.0, 'prix_unitaire': 300.0},
        ],
      });
    });
  });

  group('réponse de la destinataire', () {
    test('refus : aucune correspondance requise', () {
      expect(buildTransferResponse(transferId: 't-1', accept: false), {'transfert_id': 't-1', 'decision': 'refuser'});
    });

    test('acceptation : produit existant et création avec prix de vente', () {
      final payload = buildTransferResponse(transferId: 't-1', accept: true, mappings: [
        LineMapping(lineId: 'l1', create: false, variantId: 'v9', salePrice: 1100),
        LineMapping(lineId: 'l2', salePrice: 500),
      ]);
      expect(payload['decision'], 'accepter');
      expect(payload['correspondances'], [
        {'ligne_id': 'l1', 'variante_id': 'v9', 'prix_vente': 1100.0},
        {'ligne_id': 'l2', 'creer': true, 'prix_vente': 500.0},
      ]);
    });

    test('acceptation refusée côté application tant qu\'une ligne n\'est pas associée', () {
      expect(() => buildTransferResponse(transferId: 't-1', accept: true), throwsArgumentError);
      expect(() => buildTransferResponse(transferId: 't-1', accept: true, mappings: [LineMapping(lineId: 'l1', create: false)]), throwsArgumentError);
      expect(() => buildTransferResponse(transferId: 't-1', accept: true, mappings: [LineMapping(lineId: 'l1', salePrice: null)]), throwsArgumentError);
    });
  });

  test('résumé de transfert lu depuis la réponse serveur', () {
    final summary = TransferSummary.fromJson({
      'id': 't-1',
      'numero': 'TRF-2026-0001',
      'statut': 'en_attente',
      'total': '1200.00',
      'cree_le': '2026-06-01T10:00:00Z',
      'sens': 'recu',
      'autre_boutique': {'nom_ar': 'متجر', 'nom_fr': 'Boutique A'},
    });
    expect(summary.sent, isFalse);
    expect(summary.pending, isTrue);
    expect(summary.total, 1200);
    expect(summary.otherFr, 'Boutique A');
  });
}
