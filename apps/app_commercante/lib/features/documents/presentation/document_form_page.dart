import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/variant_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../customers/presentation/customer_picker.dart';
import '../data/documents_service.dart';
import '../domain/document_payloads.dart';

/// Création d'un devis ou d'un bon de livraison (connexion requise). L'identifiant est généré une seule fois :
/// un nouvel envoi après une coupure réseau ne crée jamais de doublon.
class DocumentFormPage extends StatefulWidget {
  const DocumentFormPage({super.key});

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _shop = Get.find<ShopController>();
  final _service = DocumentsService(Get.find<SupabaseClient>());
  final _id = const Uuid().v4();
  final _notes = TextEditingController();
  final _discount = TextEditingController();
  late final DraftDocument _draft = DraftDocument(type: Get.arguments as String, validUntil: DateTime.now().add(const Duration(days: 30)));
  String? _customerName;
  bool _busy = false;

  bool get _isQuote => _draft.type == 'devis';

  @override
  void dispose() {
    _notes.dispose();
    _discount.dispose();
    super.dispose();
  }

  Future<void> _addLine() async {
    final variant = await pickVariant(context);
    if (variant == null) return;
    setState(() => _draft.addOrIncrement(DraftLine(variantId: variant.id, labelAr: variant.libelleAr, labelFr: variant.libelleFr, unitPrice: variant.prixVente)));
  }

  Future<void> _pickCustomer() async {
    final customer = await pickCustomer(context);
    if (customer == null || !mounted) return;
    setState(() {
      _draft.customerId = customer.id;
      _customerName = localName(customer.nomAr, customer.nomFr, arabic: Localizations.localeOf(context).languageCode == 'ar');
    });
  }

  Future<void> _editLine(DraftLine line) async {
    final l10n = AppLocalizations.of(context);
    final quantity = TextEditingController(text: formatQuantity(line.quantity));
    final price = TextEditingController(text: formatQuantity(line.unitPrice));
    final discount = TextEditingController(text: line.discount > 0 ? formatQuantity(line.discount) : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localName(line.labelAr, line.labelFr, arabic: Localizations.localeOf(context).languageCode == 'ar')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          NumberField(controller: quantity, label: l10n.quantityLabel, min: 0.001),
          const SizedBox(height: 8),
          NumberField(controller: price, label: l10n.unitPriceLabel, min: 0),
          const SizedBox(height: 8),
          NumberField(controller: discount, label: l10n.discountAmount, required: false, min: 0),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        line.quantity = parseAmount(quantity.text) ?? line.quantity;
        line.unitPrice = parseAmount(price.text) ?? line.unitPrice;
        line.discount = parseAmount(discount.text) ?? 0;
      });
    }
    quantity.dispose();
    price.dispose();
    discount.dispose();
  }

  Future<void> _save({bool sent = false}) async {
    final l10n = AppLocalizations.of(context);
    _draft
      ..notes = _notes.text
      ..discount = parseAmount(_discount.text) ?? 0;
    if (!_draft.isValid) {
      showMessage(l10n.linesRequired, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final payload = _draft.toPayload(id: _id, shopId: _shop.shopId, sent: sent);
      final result = _isQuote ? await _service.createQuote(payload) : await _service.createDeliveryNote(payload);
      showMessage(l10n.documentCreated);
      Get.back<void>();
      Get.toNamed(Routes.documentDetail, arguments: result['id']);
    } catch (e) {
      if (mounted) showMessage(friendlyError(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String money(double v) => formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);
    final discount = parseAmount(_discount.text) ?? 0;
    final total = (_draft.subtotal - discount).clamp(0, double.infinity).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(_isQuote ? l10n.newQuote : l10n.newDeliveryNote)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline),
          title: Text(_customerName ?? l10n.chooseCustomer),
          trailing: _draft.customerId == null ? const Icon(Icons.chevron_right) : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _draft.customerId = null; _customerName = null; })),
          onTap: _pickCustomer,
        ),
        if (_isQuote)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text('${l10n.validUntil}: ${formatDate(_draft.validUntil!, Localizations.localeOf(context))}'),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(context: context, initialDate: _draft.validUntil!, firstDate: now, lastDate: now.add(const Duration(days: 365)));
              if (picked != null) setState(() => _draft.validUntil = picked);
            },
          ),
        const Divider(),
        for (final line in _draft.lines)
          Dismissible(
            key: ValueKey(line.variantId),
            background: Container(color: Colors.red.shade100),
            onDismissed: (_) => setState(() => _draft.lines.remove(line)),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(localName(line.labelAr, line.labelFr, arabic: arabic)),
              subtitle: Text('${formatQuantity(line.quantity)} × ${money(line.unitPrice)}${line.discount > 0 ? ' (-${money(line.discount)})' : ''}'),
              trailing: Text(money(line.net), style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => _editLine(line),
            ),
          ),
        OutlinedButton.icon(onPressed: _addLine, icon: const Icon(Icons.add), label: Text(l10n.addLine)),
        const SizedBox(height: 12),
        TextField(controller: _discount, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l10n.discountAmount)),
        const SizedBox(height: 12),
        TextField(controller: _notes, maxLines: 2, decoration: InputDecoration(labelText: l10n.note)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.total, style: Theme.of(context).textTheme.titleMedium), Text(money(total), style: Theme.of(context).textTheme.titleLarge)]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: _busy ? null : _save, child: Text(l10n.statusDraft))),
          if (_isQuote) ...[const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: _busy ? null : () => _save(sent: true), child: Text(l10n.actionSend)))],
        ]),
      ]),
    );
  }
}
