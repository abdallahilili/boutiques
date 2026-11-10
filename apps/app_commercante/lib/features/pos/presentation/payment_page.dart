import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../../core/db/app_database.dart';
import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../cart_controller.dart';
import '../cash_session_controller.dart';
import '../domain/cart.dart';

/// Paiement : un ou plusieurs modes, paiement partiel (reste en dette cliente), rendu de monnaie.
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _cart = Get.find<CartController>();
  final _shop = Get.find<ShopController>();
  final _db = Get.find<AppDatabase>();
  final _session = Get.find<CashSessionController>();
  final _amount = TextEditingController();
  String? _modeId;
  double _change = 0;

  @override
  void initState() {
    super.initState();
    _amount.text = formatQuantity(_cart.cart.remaining);
  }

  void _add(LocalPaymentMode mode) {
    final received = parseAmount(_amount.text) ?? 0;
    if (received <= 0 || _cart.cart.remaining <= 0) return;
    final change = _cart.addPayment(PaymentEntry(modeId: mode.id, modeType: mode.type, nameAr: mode.nomAr, nameFr: mode.nomFr, amount: received), tendered: received);
    setState(() => _change = change);
    _amount.text = formatQuantity(_cart.cart.remaining);
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final cart = _cart.cart;
    if (cart.hasDebt && cart.customerId == null) {
      showMessage(l10n.customerRequiredForDebt, error: true);
      return;
    }
    try {
      final receipt = await _cart.checkout(sessionId: _session.sessionId.value, change: _change);
      if (receipt != null) Get.offNamedUntil(Routes.receipt, (route) => route.settings.name == Routes.home, arguments: receipt);
    } catch (e) {
      showMessage(friendlyError(l10n, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String money(double v) => formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pay)),
      body: Obx(() {
        _cart.version.value;
        final cart = _cart.cart;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text(l10n.total, style: Theme.of(context).textTheme.labelLarge),
              Text(money(cart.total), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.paidSoFar), Text(money(cart.paid))]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.remainingDue, style: const TextStyle(fontWeight: FontWeight.bold)), Text(money(cart.remaining), style: TextStyle(fontWeight: FontWeight.bold, color: cart.remaining > 0 ? Theme.of(context).colorScheme.error : Colors.green))]),
              if (_change > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Chip(avatar: const Icon(Icons.currency_exchange, size: 18), label: Text('${l10n.changeDue}: ${money(_change)}'), backgroundColor: Colors.amber.shade100)),
            ]),
          ),
          if (cart.remaining > 0) ...[
            StreamBuilder<List<LocalPaymentMode>>(
              stream: _db.watchPaymentModes(_shop.shopId),
              builder: (context, snapshot) {
                final modes = (snapshot.data ?? const <LocalPaymentMode>[]).where((m) => m.type != 'credit').toList();
                _modeId ??= modes.where((m) => m.parDefaut).firstOrNull?.id ?? modes.firstOrNull?.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    Wrap(spacing: 8, runSpacing: 4, children: [for (final m in modes) ChoiceChip(label: Text(localName(m.nomAr, m.nomFr, arabic: arabic)), selected: _modeId == m.id, onSelected: (_) => setState(() => _modeId = m.id))]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.receivedAmount, suffixText: _shop.currency))),
                      const SizedBox(width: 8),
                      FilledButton.tonal(style: FilledButton.styleFrom(minimumSize: const Size(96, 56)), onPressed: _modeId == null ? null : () => _add(modes.firstWhere((m) => m.id == _modeId)), child: Text(l10n.addPayment)),
                    ]),
                  ]),
                );
              },
            ),
          ],
          Expanded(
            child: ListView(children: [
              for (final p in cart.payments) ListTile(leading: const Icon(Icons.payments_outlined), title: Text(localName(p.nameAr, p.nameFr, arabic: arabic)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(money(p.amount)), IconButton(icon: const Icon(Icons.close), onPressed: () { _cart.removePayment(p); _amount.text = formatQuantity(cart.remaining); })])),
              if (cart.hasDebt) Padding(padding: const EdgeInsets.all(16), child: Card(color: Theme.of(context).colorScheme.tertiaryContainer, child: Padding(padding: const EdgeInsets.all(12), child: Text('${l10n.creditSale}: ${money(cart.remaining)}${cart.customerName == null ? '\n${l10n.customerRequiredForDebt}' : ' · ${cart.customerName}'}')))),
            ]),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(width: double.infinity, child: FilledButton(onPressed: _cart.saving.value || cart.total <= 0 && cart.lines.isEmpty ? null : _confirm, child: Text(l10n.confirmSale))),
            ),
          ),
        ]);
      }),
    );
  }
}
