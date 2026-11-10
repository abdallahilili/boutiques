import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:printing/printing.dart';

import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/widgets/common.dart';
import '../../../core/util/contact.dart';
import '../../../core/util/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../documents/data/invoice_pdf.dart';
import '../../printing/printer_page.dart' show printFailureMessage;
import '../../printing/thermal_printer_service.dart';
import '../../documents/domain/invoice_data.dart';
import '../data/sales_service.dart';

/// Actions sur un document : le PDF est généré à la demande (partage WhatsApp / e-mail, impression A4).
class InvoiceActions extends StatelessWidget {
  const InvoiceActions({super.key, required this.invoice, this.customerPhone});

  final InvoiceData invoice;
  final String? customerPhone;

  Future<void> _share(BuildContext context) async {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final bytes = await buildInvoicePdf(invoice, arabic: arabic, theme: await loadPdfTheme(), logo: await Get.find<ShopController>().loadLogoBytes());
    await Printing.sharePdf(bytes: bytes, filename: '${invoice.number ?? 'facture'}.pdf');
  }

  Future<void> _print(BuildContext context) async {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = await loadPdfTheme();
    final logo = await Get.find<ShopController>().loadLogoBytes();
    await Printing.layoutPdf(onLayout: (format) => buildInvoicePdf(invoice, arabic: arabic, theme: theme, format: format, logo: logo), name: invoice.number ?? 'facture');
  }

  /// Impression thermique Bluetooth : sans imprimante choisie, ouvre les réglages de l'imprimante.
  Future<void> _thermal(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final printer = Get.find<ThermalPrinterService>();
    if (!printer.hasPrinter) {
      Get.toNamed<void>(Routes.printer);
      return;
    }
    try {
      await printer.printInvoice(invoice, arabic: arabic, logo: await Get.find<ShopController>().loadLogoBytes());
      showMessage(l10n.printSent);
    } catch (e) {
      showMessage(printFailureMessage(l10n, e), error: true);
    }
  }

  Future<void> _whatsapp(BuildContext context) async {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    await openWhatsapp(customerPhone, invoice.summaryText(arabic: arabic));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
      FilledButton.icon(onPressed: () => _share(context), icon: const Icon(Icons.share), label: Text(l10n.sharePdf)),
      OutlinedButton.icon(onPressed: () => _whatsapp(context), icon: const Icon(Icons.chat), label: Text(l10n.whatsappMessage)),
      OutlinedButton.icon(onPressed: () => _print(context), icon: const Icon(Icons.print_outlined), label: Text(l10n.printInvoice)),
      if (Get.find<ThermalPrinterService>().supported) OutlinedButton.icon(onPressed: () => _thermal(context), icon: const Icon(Icons.bluetooth), label: Text(l10n.printThermal)),
    ]);
  }
}

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final receipt = Get.arguments as SaleReceipt;
    final invoice = receipt.invoice;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String money(double v) => formatMoney(v, currency: invoice.currency, decimals: invoice.decimals);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptTitle), automaticallyImplyLeading: false),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 72),
        const SizedBox(height: 8),
        Center(child: Text(receipt.number ?? l10n.numberPending, style: Theme.of(context).textTheme.headlineSmall, textDirection: TextDirection.ltr)),
        Center(child: Text(l10n.saleQueued, style: Theme.of(context).textTheme.bodySmall)),
        if (receipt.change > 0) Padding(padding: const EdgeInsets.only(top: 12), child: Center(child: Chip(label: Text('${l10n.changeDue}: ${money(receipt.change)}'), backgroundColor: Colors.amber.shade100))),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              for (final line in invoice.lines)
                Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text('${formatQuantity(line.quantity)} × ${localName(line.labelAr, line.labelFr, arabic: arabic)}')), Text(money(line.total))])),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.bold)), Text(money(invoice.total), style: const TextStyle(fontWeight: FontWeight.bold))]),
              if (invoice.remaining > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.remainingDue), Text(money(invoice.remaining), style: TextStyle(color: Theme.of(context).colorScheme.error))]),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        InvoiceActions(invoice: invoice),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => Get.offAllNamed(Routes.home), child: Text(l10n.newSaleAction)),
      ]),
    );
  }
}
