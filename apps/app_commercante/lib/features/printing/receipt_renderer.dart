import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;

import '../../core/util/format.dart';
import '../documents/data/invoice_pdf.dart' show documentTitle, formatDateFor;
import '../documents/domain/invoice_data.dart';
import 'escpos_raster.dart';

bool _fontsLoaded = false;

/// Charge la police Amiri (arabe + latin) pour le dessin du reçu ; deux familles : normal et gras.
Future<void> ensureReceiptFonts() async {
  if (_fontsLoaded) return;
  final regular = FontLoader('AmiriReceipt')..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
  final bold = FontLoader('AmiriReceiptBold')..addFont(rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
  await Future.wait([regular.load(), bold.load()]);
  _fontsLoaded = true;
}

class _Placed {
  const _Placed(this.painter, this.dx, this.dy);

  final TextPainter painter;
  final double dx;
  final double dy;
}

/// Dessine le reçu d'un document en bitmap de [widthPx] points (RGBA, fond blanc). Le texte suit le sens de la
/// langue choisie : étiquette à droite et montant à gauche en arabe.
Future<({Uint8List rgba, int width, int height})> renderReceipt(InvoiceData d, {required bool arabic, int widthPx = 384, Uint8List? logo}) async {
  await ensureReceiptFonts();
  final width = widthPx.toDouble();
  final direction = arabic ? TextDirection.rtl : TextDirection.ltr;
  final placed = <_Placed>[];
  var y = 8.0;

  TextStyle style({bool bold = false, double size = 22}) => TextStyle(fontFamily: bold ? 'AmiriReceiptBold' : 'AmiriReceipt', fontSize: size, color: const Color(0xFF000000), height: 1.25);

  TextPainter paint(String text, TextStyle s, {required TextAlign align, required double maxWidth, TextDirection? dir}) =>
      TextPainter(text: TextSpan(text: text, style: s), textAlign: align, textDirection: dir ?? direction)..layout(minWidth: align == TextAlign.center ? maxWidth : 0, maxWidth: maxWidth);

  void centered(String text, {bool bold = false, double size = 22}) {
    final p = paint(text, style(bold: bold, size: size), align: TextAlign.center, maxWidth: width);
    placed.add(_Placed(p, 0, y));
    y += p.height + 2;
  }

  /// Ligne « étiquette … montant » : l'étiquette peut passer à la ligne, le montant reste sur la première.
  void pair(String label, String value, {bool bold = false}) {
    final s = style(bold: bold);
    final amount = paint(value, s, align: TextAlign.end, maxWidth: width * 0.42, dir: TextDirection.ltr);
    final text = paint(label, s, align: TextAlign.start, maxWidth: width - amount.width - 12);
    placed.add(_Placed(text, arabic ? width - text.width : 0, y));
    placed.add(_Placed(amount, arabic ? 0 : width - amount.width, y));
    y += (text.height > amount.height ? text.height : amount.height) + 2;
  }

  void rule() {
    final p = paint('-' * 48, style(size: 16), align: TextAlign.center, maxWidth: width, dir: TextDirection.ltr);
    placed.add(_Placed(p, 0, y));
    y += p.height;
  }

  ui.Image? logoImage;
  if (logo != null) {
    try {
      final codec = await ui.instantiateImageCodec(logo, targetWidth: (width * 0.45).round());
      logoImage = (await codec.getNextFrame()).image;
    } catch (_) {
      logoImage = null; // Un logo illisible n'empêche jamais l'impression.
    }
  }
  final logoTop = y;
  if (logoImage != null) y += logoImage.height + 6;

  String money(double v) => formatMoney(v, currency: d.currency, decimals: d.decimals);
  String name(String? ar, String? fr) => localName(ar, fr, arabic: arabic);
  final title = documentTitle(d.type, arabic: arabic);
  final showPayments = d.type == 'facture' || d.type == 'ticket';

  centered(name(d.shopNameAr, d.shopNameFr), bold: true, size: 28);
  if (d.shopAddress != null) centered(d.shopAddress!, size: 18);
  if (d.shopPhone != null) centered(d.shopPhone!, size: 18);
  rule();
  centered('$title ${d.number ?? ''}', bold: true, size: 24);
  centered(formatDateFor(d.date, arabic), size: 18);
  if (d.customerName != null) centered(d.customerName!, size: 18);
  rule();
  for (final l in d.lines) {
    pair('${formatQuantity(l.quantity)} × ${name(l.labelAr, l.labelFr)}', money(l.total));
    if (l.discount > 0) pair('   -${money(l.discount)}', '');
  }
  rule();
  if (d.discount > 0) pair(arabic ? 'تخفيض' : 'Remise', '- ${money(d.discount)}');
  pair(arabic ? 'المجموع' : 'Total', money(d.total), bold: true);
  if (showPayments) {
    for (final p in d.payments) {
      pair(name(p.nameAr, p.nameFr), money(p.amount));
    }
    if (d.remaining > 0) pair(arabic ? 'المتبقي' : 'Reste dû', money(d.remaining), bold: true);
  }
  final footer = arabic ? d.footerAr : d.footerFr;
  if (footer != null && footer.trim().isNotEmpty) {
    rule();
    centered(footer, size: 18);
  }
  y += 8;

  final height = y.ceil();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, width, height.toDouble()));
  canvas.drawRect(ui.Rect.fromLTWH(0, 0, width, height.toDouble()), ui.Paint()..color = const Color(0xFFFFFFFF));
  if (logoImage != null) canvas.drawImage(logoImage, ui.Offset((width - logoImage.width) / 2, logoTop + 4), ui.Paint());
  for (final p in placed) {
    p.painter.paint(canvas, ui.Offset(p.dx, p.dy));
  }
  final image = await recorder.endRecording().toImage(widthPx, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return (rgba: data!.buffer.asUint8List(), width: widthPx, height: height);
}

/// Octets ESC/POS prêts à envoyer à l'imprimante pour imprimer le document.
Future<Uint8List> buildReceiptEscPos(InvoiceData d, {required bool arabic, int paperMm = 58, Uint8List? logo}) async {
  final widthPx = dotsForPaper(paperMm);
  final image = await renderReceipt(d, arabic: arabic, widthPx: widthPx, logo: logo);
  return escPosRasterJob(rgbaToMonochrome(image.rgba, image.width, image.height), image.width, image.height);
}
