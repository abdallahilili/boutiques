import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/util/format.dart';
import '../domain/invoice_data.dart';

class _Labels {
  const _Labels(this.title, this.number, this.date, this.customer, this.item, this.qty, this.price, this.discount, this.total, this.subtotal, this.paid, this.remaining, this.payments);

  final String title, number, date, customer, item, qty, price, discount, total, subtotal, paid, remaining, payments;

  static const ar = _Labels('فاتورة', 'رقم', 'التاريخ', 'الزبونة', 'المنتج', 'الكمية', 'السعر', 'تخفيض', 'المجموع', 'المجموع الفرعي', 'المدفوع', 'المتبقي', 'الدفعات');
  static const fr = _Labels('Facture', 'N°', 'Date', 'Cliente', 'Article', 'Qté', 'Prix', 'Remise', 'Total', 'Sous-total', 'Payé', 'Reste dû', 'Paiements');
}

/// Charge la police arabe (Amiri) embarquée dans l'app ; indispensable pour afficher l'arabe dans le PDF.
Future<pw.ThemeData> loadPdfTheme() async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
  return pw.ThemeData.withFont(base: regular, bold: bold);
}

/// Génère le PDF d'un document à la demande (impression A4, partage WhatsApp/e-mail). Jamais stocké.
Future<Uint8List> buildInvoicePdf(InvoiceData d, {required bool arabic, required pw.ThemeData theme, PdfPageFormat format = PdfPageFormat.a4}) async {
  final l = arabic ? _Labels.ar : _Labels.fr;
  final direction = arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  String money(double v) => formatMoney(v, currency: d.currency, decimals: d.decimals);
  String name(String? ar, String? fr) => localName(ar, fr, arabic: arabic);

  final doc = pw.Document(title: '${l.title} ${d.number ?? ''}', theme: theme);
  pw.Widget cell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.start}) =>
      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4), child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)));

  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      textDirection: direction,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Text(name(d.shopNameAr, d.shopNameFr), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        if (d.shopAddress != null) pw.Text(d.shopAddress!),
        if (d.shopPhone != null) pw.Text(d.shopPhone!, textDirection: pw.TextDirection.ltr),
        pw.SizedBox(height: 18),
        pw.Text('${l.title} ${d.number == null ? '' : '${l.number} ${d.number}'}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text('${l.date} : ${formatDateFor(d.date, arabic)}'),
        if (d.customerName != null) pw.Text('${l.customer} : ${d.customerName}${d.customerPhone == null ? '' : ' · ${d.customerPhone}'}'),
        pw.SizedBox(height: 14),
        pw.Table(
          border: pw.TableBorder(horizontalInside: const pw.BorderSide(color: PdfColors.grey400), bottom: const pw.BorderSide(color: PdfColors.grey600)),
          columnWidths: {0: const pw.FlexColumnWidth(4), 1: const pw.FlexColumnWidth(1.2), 2: const pw.FlexColumnWidth(2), 3: const pw.FlexColumnWidth(2)},
          children: [
            pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [cell(l.item, bold: true), cell(l.qty, bold: true), cell(l.price, bold: true), cell(l.total, bold: true)]),
            for (final line in d.lines)
              pw.TableRow(children: [
                cell(name(line.labelAr, line.labelFr) + (line.discount > 0 ? '  (-${money(line.discount)})' : '')),
                cell(formatQuantity(line.quantity)),
                cell(money(line.unitPrice)),
                cell(money(line.total)),
              ]),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 220,
            child: pw.Column(children: [
              _row(l.subtotal, money(d.subtotal)),
              if (d.discount > 0) _row(l.discount, '- ${money(d.discount)}'),
              pw.Divider(),
              _row(l.total, money(d.total), bold: true),
              _row(l.paid, money(d.paid)),
              if (d.remaining > 0) _row(l.remaining, money(d.remaining), bold: true),
            ]),
          ),
        ),
        if (d.payments.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(l.payments, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          for (final p in d.payments) pw.Text('${name(p.nameAr, p.nameFr)} : ${money(p.amount)}'),
        ],
        if (d.notes != null && d.notes!.trim().isNotEmpty) ...[pw.SizedBox(height: 10), pw.Text(d.notes!)],
        pw.SizedBox(height: 24),
        if ((arabic ? d.footerAr : d.footerFr) != null) pw.Center(child: pw.Text((arabic ? d.footerAr : d.footerFr)!)),
      ],
    ),
  );
  return doc.save();
}

pw.Widget _row(String label, String value, {bool bold = false}) {
  final style = pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
  return pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(label, style: style), pw.Text(value, style: style)]));
}

String formatDateFor(DateTime date, bool arabic) {
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
