import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../../customers/presentation/customer_picker.dart';
import '../cart_controller.dart';
import '../domain/cart.dart';

/// Panier : quantités, prix modifiable (si autorisé), remises par ligne et globale, cliente, note.
class CartPage extends StatelessWidget {
  CartPage({super.key});

  final _cart = Get.find<CartController>();
  final _shop = Get.find<ShopController>();

  Future<double?> _askNumber(BuildContext context, String title, double initial, {String? suffix}) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: initial == 0 ? '' : formatQuantity(initial));
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(suffixText: suffix)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, parseAmount(controller.text) ?? 0), child: Text(l10n.confirm))],
      ),
    );
  }

  Future<void> _discount(BuildContext context, {CartLine? line}) async {
    final l10n = AppLocalizations.of(context);
    var mode = DiscountMode.amount;
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(line == null ? l10n.applyDiscount : l10n.lineDiscount),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            SegmentedButton<DiscountMode>(
              segments: [ButtonSegment(value: DiscountMode.amount, label: Text(l10n.discountAmount)), ButtonSegment(value: DiscountMode.percent, label: Text(l10n.discountPercent))],
              selected: {mode},
              onSelectionChanged: (s) => setState(() => mode = s.first),
            ),
            const SizedBox(height: 12),
            TextField(controller: controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(suffixText: mode == DiscountMode.percent ? '%' : _shop.currency)),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.confirm))],
        ),
      ),
    );
    if (ok != true) return;
    final value = parseAmount(controller.text) ?? 0;
    line == null ? _cart.setGlobalDiscount(value, mode) : _cart.setLineDiscount(line, value, mode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String money(double v) => formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cartTitle),
        actions: [
          IconButton(icon: const Icon(Icons.pause_circle_outline), tooltip: l10n.suspendSale, onPressed: () async { await _cart.suspend(); Get.back<void>(); }),
          IconButton(icon: const Icon(Icons.delete_sweep_outlined), onPressed: () { _cart.clear(); Get.back<void>(); }),
        ],
      ),
      body: Obx(() {
        _cart.version.value;
        final cart = _cart.cart;
        if (cart.isEmpty) return EmptyState(message: l10n.cartEmpty, icon: Icons.shopping_cart_outlined);
        return Column(children: [
          Expanded(
            child: ListView(children: [
              for (final line in cart.lines)
                Dismissible(
                  key: ValueKey(line.variant.id),
                  background: Container(color: Colors.red, alignment: AlignmentDirectional.centerStart, padding: const EdgeInsets.all(16), child: const Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (_) => _cart.setQuantity(line, 0),
                  child: ListTile(
                    title: Text(arabic ? line.variant.libelleAr : line.variant.libelleFr),
                    subtitle: Wrap(spacing: 8, children: [
                      InkWell(onTap: _cart.canModifyPrice ? () async { final v = await _askNumber(context, l10n.editPrice, line.unitPrice, suffix: _shop.currency); if (v != null) _cart.setPrice(line, v); } : null, child: Text(money(line.unitPrice), style: TextStyle(color: line.priceModified ? Theme.of(context).colorScheme.tertiary : null, fontWeight: line.priceModified ? FontWeight.bold : null))),
                      if (line.discount > 0) Text('-${money(line.discount)}', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      if (line.exceedsStock) Text(l10n.stockInsufficient, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                    ]),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _cart.setQuantity(line, line.quantity - 1)),
                      Text(formatQuantity(line.quantity), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _cart.setQuantity(line, line.quantity + 1)),
                      SizedBox(width: 78, child: Text(money(line.net), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ]),
                    onLongPress: _cart.canDiscount ? () => _discount(context, line: line) : null,
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(cart.customerName ?? l10n.walkInCustomer),
                trailing: cart.customerId == null ? const Icon(Icons.chevron_right) : IconButton(icon: const Icon(Icons.close), onPressed: () => _cart.setCustomer(null, null)),
                onTap: () async {
                  final picked = await pickCustomer(context);
                  if (picked != null) _cart.setCustomer(picked.id, localName(picked.nomAr, picked.nomFr, arabic: arabic));
                },
              ),
              if (_cart.canDiscount) ListTile(leading: const Icon(Icons.percent), title: Text(l10n.applyDiscount), trailing: cart.globalDiscount > 0 ? Text('-${money(cart.globalDiscount)}') : null, onTap: () => _discount(context)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(decoration: InputDecoration(labelText: l10n.note, isDense: true), onChanged: _cart.setNote)),
            ]),
          ),
          Material(
            elevation: 8,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.subtotal), Text(money(cart.subtotal))]),
                  if (cart.globalDiscount > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.discount), Text('-${money(cart.globalDiscount)}')]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.total, style: Theme.of(context).textTheme.titleMedium), Text(money(cart.total), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _shop.readOnly ? null : () => Get.toNamed(Routes.payment), child: Text(l10n.pay)),
                ]),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}
