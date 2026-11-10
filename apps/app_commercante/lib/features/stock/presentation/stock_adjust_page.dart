import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../../core/db/app_database.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/variant_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../stock_controllers.dart';

/// Sortie manuelle (motif obligatoire) ou inventaire (quantités comptées → écarts → ajustements).
class StockAdjustPage extends StatefulWidget {
  const StockAdjustPage({super.key, required this.inventory});

  final bool inventory;

  @override
  State<StockAdjustPage> createState() => _StockAdjustPageState();
}

class _StockAdjustPageState extends State<StockAdjustPage> {
  late final StockAdjustController _c = Get.put(StockAdjustController(Get.find(), Get.find(), Get.find(), inventory: widget.inventory), tag: widget.inventory ? 'inventory' : 'out');
  final _db = Get.find<AppDatabase>();
  final _shop = Get.find<ShopController>();

  @override
  void dispose() {
    Get.delete<StockAdjustController>(tag: widget.inventory ? 'inventory' : 'out');
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
      appBar: AppBar(title: Text(widget.inventory ? l10n.inventoryTitle : l10n.stockOutTitle), actions: [IconButton(icon: const Icon(Icons.add), tooltip: l10n.addLine, onPressed: _add)]),
      body: Column(children: [
        if (!widget.inventory)
          Padding(
            padding: const EdgeInsets.all(12),
            child: StreamBuilder<List<LocalReason>>(
              stream: _db.watchReasons(_shop.shopId),
              builder: (context, snapshot) {
                final reasons = (snapshot.data ?? const <LocalReason>[]).where((r) => r.code != 'inventaire').toList();
                return Obx(() => DropdownButtonFormField<String?>(
                      initialValue: _c.reasonId.value,
                      decoration: InputDecoration(labelText: l10n.reason),
                      items: [for (final r in reasons) DropdownMenuItem<String?>(value: r.id, child: Text(localName(r.nomAr, r.nomFr, arabic: arabic)))],
                      onChanged: (v) => _c.reasonId.value = v,
                    ));
              },
            ),
          ),
        Expanded(
          child: Obx(() {
            if (_c.lines.isEmpty) return EmptyState(message: l10n.noLines, icon: Icons.qr_code_scanner);
            return ListView.builder(
              itemCount: _c.lines.length,
              itemBuilder: (_, i) {
                final line = _c.lines[i];
                final diff = line.quantity - line.variant.enStock;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(arabic ? line.variant.libelleAr : line.variant.libelleFr),
                    subtitle: widget.inventory ? Text('${l10n.systemQty(formatQuantity(line.variant.enStock))} · ${l10n.difference(formatQuantity(diff))}') : Text(l10n.systemQty(formatQuantity(line.variant.enStock))),
                    trailing: SizedBox(
                      width: 96,
                      child: TextFormField(
                        initialValue: formatQuantity(line.quantity),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(labelText: widget.inventory ? l10n.counted : l10n.stockOutQty, isDense: true),
                        onChanged: (v) {
                          line.quantity = parseAmount(v) ?? 0;
                          _c.lines.refresh();
                        },
                      ),
                    ),
                    onLongPress: () => _c.lines.removeAt(i),
                  ),
                );
              },
            );
          }),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Obx(() => FilledButton(onPressed: _c.isValid && !_c.saving.value ? _submit : null, child: Text(widget.inventory ? l10n.applyInventory : l10n.confirm))),
          ),
        ),
      ]),
    );
  }
}
