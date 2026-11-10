import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../core/widgets/common.dart';
import '../../l10n/app_localizations.dart';
import 'thermal_printer_service.dart';

/// Message traduit d'un échec d'impression.
String printFailureMessage(AppLocalizations l10n, Object error) => switch (error is PrintException ? error.failure : null) {
      PrintFailure.unsupported => l10n.printerUnsupported,
      PrintFailure.noPrinter => l10n.printerNotSelected,
      PrintFailure.bluetoothOff => l10n.printerBluetoothOff,
      PrintFailure.permission => l10n.printerPermission,
      PrintFailure.connection => l10n.printerConnectionFailed,
      PrintFailure.write => l10n.printerWriteFailed,
      null => l10n.unknownError('$error'),
    };

/// Réglages de l'imprimante thermique : choix parmi les imprimantes appairées, largeur du papier, ticket d'essai.
class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final _printer = Get.find<ThermalPrinterService>();
  late Future<List<BluetoothInfo>> _future = _printer.pairedPrinters();

  Future<void> _test() async {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      await _printer.printTest(arabic: arabic);
      showMessage(l10n.printSent);
    } catch (e) {
      showMessage(printFailureMessage(l10n, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.printerSettings)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Obx(() => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.print_outlined),
              title: Text(_printer.printerName.value ?? l10n.printerNotSelected),
              trailing: _printer.hasPrinter ? IconButton(icon: const Icon(Icons.link_off), tooltip: l10n.printerForget, onPressed: _printer.forget) : null,
            )),
        const SizedBox(height: 8),
        Text(l10n.paperWidth, style: Theme.of(context).textTheme.titleSmall),
        Obx(() => SegmentedButton<int>(
              segments: const [ButtonSegment(value: 58, label: Text('58 mm')), ButtonSegment(value: 80, label: Text('80 mm'))],
              selected: {_printer.paperMm.value},
              onSelectionChanged: (s) => _printer.setPaper(s.first),
            )),
        const SizedBox(height: 12),
        Obx(() => FilledButton.icon(onPressed: _printer.printerName.value == null ? null : _test, icon: const Icon(Icons.receipt_long_outlined), label: Text(l10n.printTest))),
        const Divider(height: 32),
        Row(children: [Expanded(child: Text(l10n.printerPaired, style: Theme.of(context).textTheme.titleMedium)), IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _future = _printer.pairedPrinters()))]),
        Text(l10n.printerPairHint, style: Theme.of(context).textTheme.bodySmall),
        FutureBuilder<List<BluetoothInfo>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            if (snapshot.hasError) return ErrorView(message: printFailureMessage(l10n, snapshot.error!), onRetry: () => setState(() => _future = _printer.pairedPrinters()));
            final devices = snapshot.data!;
            if (devices.isEmpty) return EmptyState(message: l10n.printerNoneFound, icon: Icons.bluetooth_disabled);
            return Column(children: [
              for (final d in devices)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bluetooth),
                  title: Text(d.name),
                  subtitle: Text(d.macAdress, textDirection: TextDirection.ltr),
                  trailing: _printer.printerMac == d.macAdress ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () async {
                    await _printer.choose(d.macAdress, d.name);
                    if (mounted) setState(() {});
                  },
                ),
            ]);
          },
        ),
      ]),
    );
  }
}
