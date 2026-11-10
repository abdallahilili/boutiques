import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../../core/db/app_database.dart';
import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/util/contact.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../customers_controller.dart';
import 'customer_picker.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _controller = Get.find<CustomersController>();
  final _shop = Get.find<ShopController>();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuCustomers)),
      floatingActionButton: _controller.canWrite ? FloatingActionButton(onPressed: () => showCustomerForm(context), child: const Icon(Icons.person_add_alt_1)) : null,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: (v) => setState(() => _query = v.toLowerCase()), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.searchCustomers, isDense: true))),
        Expanded(
          child: StreamBuilder<List<LocalCustomer>>(
            stream: _controller.watch(),
            builder: (context, snapshot) {
              final items = (snapshot.data ?? const <LocalCustomer>[]).where((c) => _query.isEmpty || '${c.nomAr} ${c.nomFr} ${c.telephone}'.toLowerCase().contains(_query)).toList();
              if (items.isEmpty) return EmptyState(message: l10n.noCustomers, icon: Icons.people_outline);
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = items[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(localName(c.nomAr, c.nomFr, arabic: arabic)),
                    subtitle: Text(c.telephone ?? ''),
                    trailing: c.solde > 0 ? Chip(label: Text(formatMoney(c.solde, currency: _shop.currency, decimals: _shop.decimals)), backgroundColor: Theme.of(context).colorScheme.errorContainer) : null,
                    onTap: () => Get.toNamed(Routes.customerDetail, arguments: c),
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

/// Compte cliente : solde dû, historique d'achats, règlement (global, réparti sur les plus anciennes factures), relance WhatsApp.
class CustomerDetailPage extends StatefulWidget {
  const CustomerDetailPage({super.key});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final LocalCustomer _customer = Get.arguments as LocalCustomer;
  final _controller = Get.find<CustomersController>();
  final _shop = Get.find<ShopController>();
  late Future<List<Map<String, dynamic>>> _history = _controller.purchaseHistory(_customer.id);

  Future<void> _settle() async {
    final l10n = AppLocalizations.of(context);
    final amount = TextEditingController(text: formatQuantity(_customer.solde));
    final modes = await Get.find<AppDatabase>().watchPaymentModes(_shop.shopId).first;
    final usable = modes.where((m) => m.type != 'credit').toList();
    if (!mounted || usable.isEmpty) return;
    String modeId = (usable.where((m) => m.parDefaut).firstOrNull ?? usable.first).id;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.settleDebt),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.amount, suffixText: _shop.currency)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [for (final m in usable) ChoiceChip(label: Text(localName(m.nomAr, m.nomFr, arabic: arabic)), selected: modeId == m.id, onSelected: (_) => setState(() => modeId = m.id))]),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.confirm))],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final applied = await _controller.settle(_customer.id, modeId, parseAmount(amount.text) ?? 0);
      showMessage('${l10n.saved}: ${formatMoney(applied, currency: _shop.currency, decimals: _shop.decimals)}');
      setState(() => _history = _controller.purchaseHistory(_customer.id));
    } catch (e) {
      showMessage(friendlyError(l10n, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String money(num v) => formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);
    final name = localName(_customer.nomAr, _customer.nomFr, arabic: arabic);

    return Scaffold(
      appBar: AppBar(title: Text(name), actions: [if (_controller.canWrite) IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => showCustomerForm(context, customer: _customer))]),
      body: ListView(children: [
        ListTile(title: Text(l10n.balanceDue), trailing: Text(money(_customer.solde), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _customer.solde > 0 ? Theme.of(context).colorScheme.error : null, fontWeight: FontWeight.bold))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, children: [
            if (_customer.solde > 0 && !_shop.readOnly) FilledButton.icon(onPressed: _settle, icon: const Icon(Icons.payments_outlined), label: Text(l10n.settleDebt)),
            if (_customer.telephone != null) OutlinedButton.icon(onPressed: () => callPhone(_customer.telephone!), icon: const Icon(Icons.call), label: Text(l10n.callCustomer)),
            if (_customer.solde > 0) OutlinedButton.icon(onPressed: () => openWhatsapp(_customer.whatsapp ?? _customer.telephone, l10n.reminderMessage(name, money(_customer.solde))), icon: const Icon(Icons.chat), label: Text(l10n.whatsappReminder)),
          ]),
        ),
        const Divider(height: 32),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.purchaseHistory, style: Theme.of(context).textTheme.titleMedium)),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _history,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            if (snapshot.hasError) return ErrorView(message: l10n.networkError);
            final docs = snapshot.data!;
            if (docs.isEmpty) return EmptyState(message: l10n.noPurchases);
            return Column(children: [
              for (final d in docs)
                ListTile(
                  title: Text(d['numero'] as String, textDirection: TextDirection.ltr),
                  subtitle: Text(formatDate(DateTime.parse(d['date_emission'] as String), Localizations.localeOf(context))),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(money(asDouble(d['total']))), if (asDouble(d['reste']) > 0) Text('${l10n.remainingDue}: ${money(asDouble(d['reste']))}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.error))]),
                  onTap: () => Get.toNamed(Routes.documentDetail, arguments: d['id']),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}
