import 'dart:convert';

import 'package:app_commercante/features/documents/data/invoice_pdf.dart';
import 'package:app_commercante/features/documents/domain/invoice_data.dart';
import 'package:flutter_test/flutter_test.dart';

InvoiceData sample({String? number = 'FAC-2026-0001'}) => InvoiceData(
      type: 'facture',
      number: number,
      date: DateTime(2026, 6, 1, 14, 30),
      shopNameAr: 'متجر الأنوار',
      shopNameFr: 'Boutique Anwar',
      shopAddress: 'Tevragh Zeina',
      shopPhone: '22236000001',
      currency: 'MRU',
      customerName: 'فاطمة',
      lines: const [
        InvoiceLine(labelAr: 'ملحفة - أحمر', labelFr: 'Melhafa - Rouge', quantity: 2, unitPrice: 1500, discount: 100, total: 2900),
      ],
      payments: const [InvoicePayment(nameAr: 'نقداً', nameFr: 'Espèces', amount: 2000)],
      subtotal: 2900,
      discount: 0,
      total: 2900,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le PDF est généré à la demande en arabe et en français (police arabe embarquée)', () async {
    final theme = await loadPdfTheme();
    for (final arabic in [true, false]) {
      final bytes = await buildInvoicePdf(sample(), arabic: arabic, theme: theme);
      expect(bytes.length, greaterThan(1000));
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    }
  });

  test('un document sans numéro (vente hors ligne sans plage) se génère aussi', () async {
    final bytes = await buildInvoicePdf(sample(number: null), arabic: true, theme: await loadPdfTheme());
    expect(bytes, isNotEmpty);
  });

  test('totaux : payé et reste dû calculés depuis les paiements', () {
    final data = sample();
    expect(data.paid, 2000);
    expect(data.remaining, 900);
  });

  test('résumé WhatsApp : numéro, total et reste dû dans la langue demandée', () {
    final fr = sample().summaryText(arabic: false);
    expect(fr, contains('FAC-2026-0001'));
    expect(fr, contains('2,900 MRU'));
    expect(fr, contains('Reste dû : 900 MRU'));
    expect(sample().summaryText(arabic: true), contains('المتبقي'));
  });

  test('document serveur : en-tête figé, lignes et paiements', () {
    final data = InvoiceData.fromServer(
      document: {
        'type': 'facture', 'numero': 'FAC-2026-0002', 'date_emission': '2026-06-01T12:00:00Z', 'sous_total': 1000, 'remise': 0, 'total': 1000, 'notes': null,
        'entete': {'nom_fr': 'Boutique', 'nom_ar': 'متجر', 'devise': 'MRU', 'adresse': 'Rue 1', 'ville': 'Nouakchott', 'client': {'nom_ar': 'فاطمة', 'telephone': '22236000009'}},
      },
      lines: [{'libelle_ar': 'حقيبة', 'libelle_fr': 'Sac', 'quantite': 1, 'prix_unitaire': 1000, 'remise': 0, 'total': 1000}],
      payments: [{'mode_paiement_id': 'm1', 'montant': 1000}],
      modeNamesAr: {'m1': 'نقداً'},
      modeNamesFr: {'m1': 'Espèces'},
    );
    expect(data.shopAddress, 'Rue 1, Nouakchott');
    expect(data.customerPhone, '22236000009');
    expect(data.paid, 1000);
    expect(data.remaining, 0);
  });
}
