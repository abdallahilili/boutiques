import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/app_localizations.dart';
import '../db/app_database.dart';
import '../session/shop_controller.dart';
import '../util/format.dart';
import 'common.dart';

/// Lecture d'un code-barres / QR avec la caméra : retourne le texte lu.
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).scan), actions: [IconButton(onPressed: _controller.toggleTorch, icon: const Icon(Icons.flashlight_on_outlined))]),
        body: MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_done) return;
            final code = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
            if (code != null) {
              _done = true;
              Navigator.pop(context, code);
            }
          },
        ),
      );
}

Future<String?> scanBarcode(BuildContext context) => Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const BarcodeScannerPage()));

/// Sélecteur d'article : recherche par nom / SKU / code-barres ou scan caméra.
Future<LocalVariant?> pickVariant(BuildContext context) {
  return showModalBottomSheet<LocalVariant>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _VariantPickerSheet(),
  );
}

class _VariantPickerSheet extends StatefulWidget {
  const _VariantPickerSheet();

  @override
  State<_VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends State<_VariantPickerSheet> {
  final _db = Get.find<AppDatabase>();
  final _shop = Get.find<ShopController>();
  String _query = '';

  Future<void> _scan() async {
    final l10n = AppLocalizations.of(context);
    final code = await scanBarcode(context);
    if (code == null || !mounted) return;
    final variant = await _db.variantByBarcode(_shop.shopId, code);
    if (!mounted) return;
    if (variant == null) {
      showMessage(l10n.scanNotFound, error: true);
    } else {
      Navigator.pop(context, variant);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.stockSearch, suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scan)),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<LocalVariant>>(
            stream: _db.watchVariants(_shop.shopId, query: _query),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <LocalVariant>[];
              if (items.isEmpty) return const EmptyState();
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final v = items[i];
                  return ListTile(
                    leading: v.couleurHex == null ? null : CircleAvatar(radius: 12, backgroundColor: Color(0xFF000000 | int.parse(v.couleurHex!.substring(1), radix: 16))),
                    title: Text(arabic ? v.libelleAr : v.libelleFr),
                    subtitle: Text(formatMoney(v.prixVente, currency: _shop.currency, decimals: _shop.decimals)),
                    trailing: Text(formatQuantity(v.enStock)),
                    onTap: () => Navigator.pop(context, v),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
