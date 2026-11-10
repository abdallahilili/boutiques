import 'dart:typed_data';

import 'package:app_commercante/features/documents/domain/invoice_data.dart';
import 'package:app_commercante/features/printing/escpos_raster.dart';
import 'package:app_commercante/features/printing/receipt_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

InvoiceData sample({String type = 'ticket'}) => InvoiceData(
      type: type,
      number: 'TIC-2026-0001',
      date: DateTime(2026, 6, 1, 14, 30),
      shopNameAr: 'متجر الأنوار',
      shopNameFr: 'Boutique Anwar',
      shopAddress: 'Tevragh Zeina',
      shopPhone: '22236000001',
      currency: 'MRU',
      customerName: 'فاطمة',
      lines: const [
        InvoiceLine(labelAr: 'ملحفة قطنية - أحمر', labelFr: 'Melhafa coton - Rouge', quantity: 2, unitPrice: 1500, discount: 100, total: 2900),
        InvoiceLine(labelAr: 'وشاح', labelFr: 'Foulard', quantity: 1, unitPrice: 400, discount: 0, total: 400),
      ],
      payments: const [InvoicePayment(nameAr: 'نقداً', nameFr: 'Espèces', amount: 3000)],
      subtotal: 3300,
      discount: 0,
      total: 3300,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('rgbaToMonochrome', () {
    Uint8List rgba(int width, int height, List<int> pixels) {
      final out = Uint8List(width * height * 4);
      for (var i = 0; i < pixels.length; i++) {
        out[i * 4] = out[i * 4 + 1] = out[i * 4 + 2] = pixels[i];
        out[i * 4 + 3] = 255;
      }
      return out;
    }

    test('noir = 1, blanc = 0, bit de poids fort à gauche', () {
      // 8 pixels : noir, blanc, noir, blanc, noir, noir, blanc, blanc → 1010 1100 = 0xAC
      final mono = rgbaToMonochrome(rgba(8, 1, [0, 255, 0, 255, 0, 0, 255, 255]), 8, 1);
      expect(mono, [0xAC]);
    });

    test('largeur non multiple de 8 : rembourrage à droite en blanc', () {
      final mono = rgbaToMonochrome(rgba(3, 1, [0, 0, 0]), 3, 1);
      expect(mono, [0xE0]);
    });

    test('pixel transparent = blanc ; seuil de luminance', () {
      final transparent = Uint8List.fromList([0, 0, 0, 0]);
      expect(rgbaToMonochrome(transparent, 1, 1), [0x00]);
      expect(rgbaToMonochrome(rgba(1, 1, [100]), 1, 1, threshold: 160), [0x80]);
      expect(rgbaToMonochrome(rgba(1, 1, [200]), 1, 1, threshold: 160), [0x00]);
    });

    test('image trop courte refusée', () {
      expect(() => rgbaToMonochrome(Uint8List(4), 2, 2), throwsArgumentError);
    });
  });

  group('escPosRasterJob', () {
    test('initialisation, un bloc raster, avance papier et coupe', () {
      final mono = Uint8List(2 * 3); // 16 points × 3 lignes
      final job = escPosRasterJob(mono, 16, 3, feedLines: 4);
      expect(job.sublist(0, 2), [0x1B, 0x40]);
      expect(job.sublist(2, 10), [0x1D, 0x76, 0x30, 0x00, 2, 0, 3, 0]);
      expect(job.sublist(job.length - 7), [0x1B, 0x64, 4, 0x1D, 0x56, 0x42, 0x00]);
      expect(job.length, 2 + 8 + 6 + 3 + 4);
    });

    test('image haute découpée en bandes (hauteur et nombre d\'octets cohérents)', () {
      const width = 384, height = 300;
      final stride = width ~/ 8;
      final job = escPosRasterJob(Uint8List(stride * height), width, height, bandHeight: 128, feedLines: 0, cut: false);
      // 3 bandes : 128 + 128 + 44 lignes, chacune précédée de 8 octets d'en-tête.
      expect(job.length, 2 + 3 * 8 + stride * height);
      expect(job[2 + 6], 128); // hauteur de la première bande
      expect(job[2 + 8 + stride * 128 + 6], 128);
      expect(job[2 + 16 + stride * 256 + 6], 44);
    });

    test('bitmap de mauvaise taille refusé ; largeur 576 : stride sur deux octets non requis', () {
      expect(() => escPosRasterJob(Uint8List(5), 16, 3), throwsArgumentError);
      final job = escPosRasterJob(Uint8List(72), 576, 1, feedLines: 0, cut: false);
      expect(job.sublist(2, 10), [0x1D, 0x76, 0x30, 0x00, 72, 0, 1, 0]);
    });

    test('largeur du papier en points', () {
      expect(dotsForPaper(58), 384);
      expect(dotsForPaper(80), 576);
      expect(dotsForPaper(0), 384);
    });
  });

  group('rendu du reçu', () {
    testWidgets('ticket arabe et français : bitmap de la bonne largeur contenant de l\'encre', (tester) async {
      await tester.runAsync(() async {
        for (final arabic in [true, false]) {
          final image = await renderReceipt(sample(), arabic: arabic, widthPx: 384);
          expect(image.width, 384);
          expect(image.height, greaterThan(200));
          expect(image.rgba.length, 384 * image.height * 4);
          final mono = rgbaToMonochrome(image.rgba, image.width, image.height);
          expect(mono.any((b) => b != 0), isTrue, reason: 'le reçu ne doit pas être blanc (${arabic ? 'ar' : 'fr'})');
        }
      });
    });

    testWidgets('travail ESC/POS complet : 58 mm et 80 mm, devis sans paiements', (tester) async {
      await tester.runAsync(() async {
        final narrow = await buildReceiptEscPos(sample(), arabic: true, paperMm: 58);
        final wide = await buildReceiptEscPos(sample(type: 'devis'), arabic: false, paperMm: 80);
        expect(narrow.sublist(0, 2), [0x1B, 0x40]);
        expect(narrow.sublist(2, 6), [0x1D, 0x76, 0x30, 0x00]);
        expect(narrow[6], 48); // 384 / 8
        expect(wide[6], 72); // 576 / 8
        expect(narrow.sublist(narrow.length - 4), [0x1D, 0x56, 0x42, 0x00]);
      });
    });
  });
}
