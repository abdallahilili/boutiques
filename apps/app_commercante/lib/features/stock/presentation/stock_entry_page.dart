import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../../core/session/shop_controller.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/variant_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../stock_controllers.dart';

class StockEntryPage extends StatefulWidget {
  const StockEntryPage({super.key});

  @override
  State<StockEntryPage> createState() => _StockEntryPageState();
}

class _StockEntryPageState extends State<StockEntryPage> {
  late final StockEntryController _c = Get.put(StockEntryController(Get.find(), Get.find(), Get.find()));
  final _shop = Get.find<ShopController>();

  @override
  void dispose() {
    Get.delete<StockEntryController>();
    super.dispose();
  }

  Future<void> _add() async {
    final variant = await pickVariant(context);
    if (variant != null) _c.addVariant(variant);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    try {
      await _c.submit();
      showMessage(l10n.queuedOffline);
      Get.back<void>();
    } catch (e) {
      showMessage(friendlyError(l10n, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.stockEntryTitle), actions: [IconButton(icon: const Icon(Icons.add), tooltip: l10n.addLine, onPressed: _add)]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            _SupplierDropdown(controller: _c),
            const SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: l10n.reference), onChanged: (v) => _c.reference.value = v),
          ]),
        ),
        Expanded(
          child: Obx(() {
            if (_c.lines.isEmpty) return EmptyState(message: l10n.noLines, icon: Icons.qr_code_scanner);
            return ListView.builder(
              itemCount: _c.lines.length,
              itemBuilder: (_, i) {
                final line = _c.lines[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      Row(children: [
                        Expanded(child: Text(arabic ? line.variant.libelleAr : line.variant.libelleFr, style: const TextStyle(fontWeight: FontWeight.w600))),
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _c.removeAt(i)),
                      ]),
                      Row(children: [
                        Expanded(child: TextFormField(initialValue: formatQuantity(line.quantity), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.quantity, isDense: true), onChanged: (v) { line.quantity = parseAmount(v) ?? 0; _c.lines.refresh(); })),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(initialValue: line.unitCost == 0 ? '' : formatQuantity(line.unitCost), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.unitCost, isDense: true), onChanged: (v) { line.unitCost = parseAmount(v) ?? 0; _c.lines.refresh(); })),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: TextFormField(initialValue: line.salePrice == null ? '' : formatQuantity(line.salePrice!), keyboardType: const TextInputType.numberWithOptions(decimal: true), enabled: _shop.can('produits.ecrire'), decoration: InputDecoration(labelText: l10n.newSalePrice, isDense: true), onChanged: (v) => line.salePrice = v.trim().isEmpty ? null : parseAmount(v))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event_outlined, size: 18),
                            label: Text(line.expiry == null ? l10n.expiryDate : formatDate(line.expiry!, Localizations.localeOf(context))),
                            onPressed: () async {
                              final picked = await showDatePicker(context: context, initialDate: line.expiry ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 10)));
                              if (picked != null) {
                                line.expiry = picked;
                                _c.lines.refresh();
                              }
                            },
                          ),
                        ),
                      ]),
                    ]),
                  ),
                );
              },
            );
          }),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Obx(() => Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.total), Text(formatMoney(_c.total, currency: _shop.currency, decimals: _shop.decimals), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
                  const SizedBox(height: 8),
                  TextField(keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.amountPaid, isDense: true), onChanged: (v) => _c.amountPaid.value = parseAmount(v) ?? 0),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _c.isValid && !_c.saving.value ? _submit : null, child: Text(l10n.save)),
                ])),
          ),
        ),
      ]),
    );
  }
}

class _SupplierDropdown extends StatelessWidget {
  const _SupplierDropdown({required this.controller});

  final StockEntryController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final shop = Get.find<ShopController>();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: shop.loadSuppliers(),
      builder: (context, snapshot) {
        final suppliers = snapshot.data ?? const <Map<String, dynamic>>[];
        return Obx(() => DropdownButtonFormField<String?>(
              initialValue: controller.supplierId.value,
              decoration: InputDecoration(labelText: '${l10n.supplier} (${l10n.optional})'),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(l10n.none)),
                for (final s in suppliers) DropdownMenuItem<String?>(value: s['id'] as String, child: Text(localName(s['nom_ar'] as String?, s['nom_fr'] as String?, arabic: arabic))),
              ],
              onChanged: (v) => controller.supplierId.value = v,
            ));
      },
    );
  }
}
