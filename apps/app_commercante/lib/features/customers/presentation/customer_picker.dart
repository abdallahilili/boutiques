import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../../core/db/app_database.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../customers_controller.dart';

/// Sélection d'une cliente (recherche locale) ou création rapide (connexion requise).
Future<LocalCustomer?> pickCustomer(BuildContext context) => showModalBottomSheet<LocalCustomer>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CustomerPickerSheet(),
    );

class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet();

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _controller = Get.find<CustomersController>();
  final _shop = Get.find<ShopController>();
  String _query = '';

  Future<void> _create() async {
    final saved = await showCustomerForm(context);
    if (saved == null || !mounted) return;
    final local = await (Get.find<AppDatabase>().select(Get.find<AppDatabase>().localCustomers)..where((c) => c.id.equals(saved['id'] as String))).getSingleOrNull();
    if (local != null && mounted) Navigator.pop(context, local);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(autofocus: true, onChanged: (v) => setState(() => _query = v.toLowerCase()), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.searchCustomers, suffixIcon: _controller.canWrite ? IconButton(icon: const Icon(Icons.person_add_alt_1), tooltip: l10n.newCustomer, onPressed: _create) : null)),
        ),
        Expanded(
          child: StreamBuilder<List<LocalCustomer>>(
            stream: _controller.watch(),
            builder: (context, snapshot) {
              final items = (snapshot.data ?? const <LocalCustomer>[]).where((c) => _query.isEmpty || '${c.nomAr} ${c.nomFr} ${c.telephone}'.toLowerCase().contains(_query)).toList();
              if (items.isEmpty) return EmptyState(message: l10n.noCustomers, icon: Icons.people_outline);
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final c = items[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(localName(c.nomAr, c.nomFr, arabic: arabic)),
                    subtitle: Text(c.telephone ?? ''),
                    trailing: c.solde > 0 ? Text(formatMoney(c.solde, currency: _shop.currency, decimals: _shop.decimals), style: TextStyle(color: Theme.of(context).colorScheme.error)) : null,
                    onTap: () => Navigator.pop(context, c),
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

/// Formulaire cliente (création rapide ou modification) ; retourne la ligne enregistrée.
Future<Map<String, dynamic>?> showCustomerForm(BuildContext context, {LocalCustomer? customer}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CustomerForm(customer: customer),
  );
}

class _CustomerForm extends StatefulWidget {
  const _CustomerForm({this.customer});

  final LocalCustomer? customer;

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  final _key = GlobalKey<FormState>();
  late final _ar = TextEditingController(text: widget.customer?.nomAr ?? '');
  late final _fr = TextEditingController(text: widget.customer?.nomFr ?? '');
  late final _phone = TextEditingController(text: widget.customer?.telephone ?? '');
  late final _whatsapp = TextEditingController(text: widget.customer?.whatsapp ?? '');
  late final _city = TextEditingController(text: widget.customer?.ville ?? '');
  late final _limit = TextEditingController(text: widget.customer?.plafondCredit == null ? '' : formatQuantity(widget.customer!.plafondCredit!));
  bool _saving = false;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!(_key.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final saved = await Get.find<CustomersController>().save({
        'nom_ar': _ar.text,
        'nom_fr': _fr.text,
        'telephone': _phone.text,
        'whatsapp': _whatsapp.text,
        'ville': _city.text,
        'plafond_credit': _limit.text.trim().isEmpty ? null : parseAmount(_limit.text),
      }, id: widget.customer?.id);
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      showMessage(friendlyError(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.customer == null ? l10n.newCustomer : l10n.editCustomer, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            BilingualNameFields(arabic: _ar, french: _fr),
            const SizedBox(height: 12),
            TextFormField(controller: _phone, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l10n.phone)),
            const SizedBox(height: 12),
            TextFormField(controller: _whatsapp, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l10n.whatsapp)),
            const SizedBox(height: 12),
            TextFormField(controller: _city, decoration: InputDecoration(labelText: l10n.city)),
            const SizedBox(height: 12),
            NumberField(controller: _limit, label: l10n.creditLimit, required: false, min: 0),
            const SizedBox(height: 16),
            FilledButton(onPressed: _saving ? null : _submit, child: Text(l10n.save)),
          ]),
        ),
      ),
    );
  }
}
