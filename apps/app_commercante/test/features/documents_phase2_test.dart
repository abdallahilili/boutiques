import 'dart:convert';

import 'package:app_commercante/features/documents/data/invoice_pdf.dart';
import 'package:app_commercante/features/documents/domain/document_payloads.dart';
import 'package:app_commercante/features/documents/domain/invoice_data.dart';
import 'package:flutter_test/flutter_test.dart';

DraftLine line(String id, double price, {double qty = 1, double discount = 0}) => DraftLine(variantId: id, labelAr: 'منتج', labelFr: 'Produit', unitPrice: price, quantity: qty, discount: discount);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DraftDocument', () {
    test('totaux : sous-total, remise et total jamais négatif', () {
      final doc = DraftDocument(type: 'devis', discount: 200)
        ..lines.addAll([line('a', 1000, qty: 2), line('b', 500, discount: 100)]);
      expect(doc.subtotal, 2400);
      expect(doc.total, 2200);
      expect(doc.isValid, isTrue);
    });

    test('une ligne identique est cumulée, un document vide est invalide', () {
      final doc = DraftDocument(type: 'bon_livraison');
      expect(doc.isValid, isFalse);
      doc.addOrIncrement(line('a', 1000));
      doc.addOrIncrement(line('a', 1000));
      expect(doc.lines, hasLength(1));
      expect(doc.lines.single.quantity, 2);
    });

    test('remise supérieure au sous-total : invalide', () {
      final doc = DraftDocument(type: 'devis', discount: 5000)..lines.add(line('a', 1000));
      expect(doc.isValid, isFalse);
    });

    test('charge utile du devis : identifiant, date de validité, envoi direct', () {
      final doc = DraftDocument(type: 'devis', customerId: 'c1', validUntil: DateTime(2026, 7, 5), discount: 100, notes: ' merci ')..lines.add(line('a', 1000, qty: 3));
      final payload = doc.toPayload(id: 'doc-1', shopId: 'shop-1', sent: true);
      expect(payload['id'], 'doc-1');
      expect(payload['boutique_id'], 'shop-1');
      expect(payload['client_id'], 'c1');
      expect(payload['date_validite'], '2026-07-05');
      expect(payload['statut'], 'envoye');
      expect(payload['remise'], 100);
      expect(payload['notes'], 'merci');
      expect(payload['lignes'], [
        {'variante_id': 'a', 'quantite': 3.0, 'prix_unitaire': 1000.0},
      ]);
    });

    test('charge utile du bon de livraison : ni date de validité ni statut', () {
      final doc = DraftDocument(type: 'bon_livraison', validUntil: DateTime(2026, 7, 5))..lines.add(line('a', 1000));
      final payload = doc.toPayload(id: 'bl-1', shopId: 'shop-1', sent: true);
      expect(payload.containsKey('date_validite'), isFalse);
      expect(payload.containsKey('statut'), isFalse);
      expect(payload.containsKey('client_id'), isFalse);
    });
  });

  group('CreditNotePlan', () {
    CreditableLine creditable(String id, double qty, double price, {double discount = 0, double credited = 0}) =>
        CreditableLine(id: id, labelAr: 'منتج', labelFr: 'Produit', quantity: qty, unitPrice: price, discount: discount, alreadyCredited: credited);

    test('avoir imputé sur le reste dû : rien à rembourser', () {
      final plan = CreditNotePlan(lines: [creditable('l1', 3, 1000)], quantities: {'l1': 1}, invoiceSubtotal: 3000, invoiceDiscount: 0, invoiceRemaining: 2000);
      expect(plan.total, 1000);
      expect(plan.applied, 1000);
      expect(plan.dueBack, 0);
    });

    test('facture soldée : tout le montant est à rembourser', () {
      final plan = CreditNotePlan(lines: [creditable('l1', 3, 1000)], quantities: {'l1': 2}, invoiceSubtotal: 3000, invoiceDiscount: 0, invoiceRemaining: 0);
      expect(plan.applied, 0);
      expect(plan.dueBack, 2000);
    });

    test('avoir supérieur au reste dû : imputation partielle puis remboursement', () {
      final plan = CreditNotePlan(lines: [creditable('l1', 3, 1000)], quantities: {'l1': 3}, invoiceSubtotal: 3000, invoiceDiscount: 0, invoiceRemaining: 500);
      expect(plan.applied, 500);
      expect(plan.dueBack, 2500);
    });

    test('remise globale et remise de ligne reprises au prorata, comme le serveur', () {
      // 2 lignes : 2 × 1000 (remise de ligne 200) et 1 × 500 ; remise globale 300 sur un sous-total de 2300.
      final lines = [creditable('l1', 2, 1000, discount: 200), creditable('l2', 1, 500)];
      final plan = CreditNotePlan(lines: lines, quantities: {'l1': 1}, invoiceSubtotal: 2300, invoiceDiscount: 300, invoiceRemaining: 0);
      expect(plan.subtotal, 900); // 1000 − 200/2
      expect(plan.discount, 117.39); // 900 × 300 / 2300
      expect(plan.total, 782.61);
    });

    test('quantité supérieure à celle encore avoirable ou aucune ligne : invalide', () {
      final line = creditable('l1', 3, 1000, credited: 2);
      expect(line.remaining, 1);
      expect(CreditNotePlan(lines: [line], quantities: {'l1': 2}, invoiceSubtotal: 3000, invoiceDiscount: 0, invoiceRemaining: 0).isValid, isFalse);
      expect(CreditNotePlan(lines: [line], quantities: {'l1': 1}, invoiceSubtotal: 3000, invoiceDiscount: 0, invoiceRemaining: 0).isValid, isTrue);
      expect(CreditNotePlan(lines: [line], quantities: const {}, invoiceSubtotal: 3000, invoiceDiscount: 0, invoiceRemaining: 0).isValid, isFalse);
    });

    test('charge utile : uniquement les lignes avoirées, remboursements et retour en stock', () {
      final plan = CreditNotePlan(lines: [creditable('l1', 3, 1000), creditable('l2', 1, 500)], quantities: {'l1': 1, 'l2': 0}, invoiceSubtotal: 3500, invoiceDiscount: 0, invoiceRemaining: 0);
      final payload = plan.toPayload(id: 'av-1', invoiceId: 'f-1', returnStock: true, reason: ' retour ', refunds: [
        {'mode_paiement_id': 'm1', 'montant': 1000},
      ]);
      expect(payload['facture_id'], 'f-1');
      expect(payload['retour_stock'], isTrue);
      expect(payload['motif'], 'retour');
      expect(payload['lignes'], [
        {'ligne_id': 'l1', 'quantite': 1.0},
      ]);
      expect(payload['remboursements'], hasLength(1));
      expect(payload.containsKey('session_caisse_id'), isFalse);
    });
  });

  group('availableActions', () {
    Set<DocumentAction> actions(String type, String status, {bool create = true, bool manage = true, bool converted = false}) => availableActions(type: type, status: status, canCreate: create, canManage: manage, alreadyConverted: converted);

    test('devis : envoi et décision en brouillon, conversion tant qu\'il n\'est pas converti', () {
      expect(actions('devis', 'brouillon'), containsAll([DocumentAction.send, DocumentAction.accept, DocumentAction.refuse, DocumentAction.convertToDelivery, DocumentAction.convertToInvoice]));
      expect(actions('devis', 'envoye'), isNot(contains(DocumentAction.send)));
      expect(actions('devis', 'accepte', converted: true), isEmpty);
      expect(actions('devis', 'expire'), isEmpty);
    });

    test('bon de livraison : validation puis livraison puis facturation', () {
      expect(actions('bon_livraison', 'brouillon'), contains(DocumentAction.validate));
      expect(actions('bon_livraison', 'brouillon'), isNot(contains(DocumentAction.convertToInvoice)));
      expect(actions('bon_livraison', 'valide'), containsAll([DocumentAction.deliver, DocumentAction.convertToInvoice]));
      expect(actions('bon_livraison', 'facture'), isEmpty);
    });

    test('facture : avoir sur une facture émise, annulation tant qu\'aucun paiement', () {
      expect(actions('facture', 'emise'), containsAll([DocumentAction.createCredit, DocumentAction.cancel]));
      expect(actions('facture', 'payee'), equals({DocumentAction.createCredit}));
      expect(actions('facture', 'annulee'), isEmpty);
      expect(actions('avoir', 'payee'), isEmpty);
    });

    test('la vendeuse (sans documents.gerer) ne convertit ni n\'annule', () {
      final vendeuse = actions('devis', 'brouillon', manage: false);
      expect(vendeuse, containsAll([DocumentAction.send, DocumentAction.accept]));
      expect(vendeuse, isNot(contains(DocumentAction.convertToInvoice)));
      expect(actions('facture', 'emise', manage: false), isEmpty);
    });
  });

  group('PDF par type', () {
    InvoiceData sample(String type) => InvoiceData(
          type: type,
          number: 'XXX-2026-0001',
          date: DateTime(2026, 6, 1, 14, 30),
          dueDate: DateTime(2026, 7, 1),
          shopNameAr: 'متجر الأنوار',
          shopNameFr: 'Boutique Anwar',
          currency: 'MRU',
          lines: const [InvoiceLine(labelAr: 'ملحفة', labelFr: 'Melhafa', quantity: 2, unitPrice: 1500, discount: 0, total: 3000)],
          payments: const [],
          subtotal: 3000,
          discount: 0,
          total: 3000,
        );

    test('devis, bon de livraison et avoir sont générés en arabe et en français', () async {
      final theme = await loadPdfTheme();
      for (final type in ['devis', 'bon_livraison', 'avoir', 'ticket', 'facture']) {
        for (final arabic in [true, false]) {
          final bytes = await buildInvoicePdf(sample(type), arabic: arabic, theme: theme);
          expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-', reason: '$type / ${arabic ? 'ar' : 'fr'}');
        }
      }
    });

    test('titres par type', () {
      expect(documentTitle('devis', arabic: false), 'Devis');
      expect(documentTitle('bon_livraison', arabic: false), 'Bon de livraison');
      expect(documentTitle('avoir', arabic: true), 'إشعار دائن');
      expect(sample('devis').summaryText(arabic: false), startsWith('Devis XXX-2026-0001'));
      expect(sample('devis').summaryText(arabic: false), isNot(contains('Reste dû')));
    });
  });
}
