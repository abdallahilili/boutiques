import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../../core/db/app_database.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/document_payloads.dart';

/// Modes de paiement utilisables pour encaisser ou rembourser (le crédit est exclu).
Future<List<LocalPaymentMode>> cashModes() async {
  final shop = Get.find<ShopController>();
  final modes = await Get.find<AppDatabase>().watchPaymentModes(shop.shopId).first;
  return modes.where((m) => m.type != 'credit' && m.actif).toList();
}

/// Résultat de la feuille « convertir en facture » : échéance et paiement immédiat facultatifs.
class ConvertInvoiceResult {
  const ConvertInvoiceResult({this.dueDate, this.payments = const []});

  final DateTime? dueDate;
  final List<Map<String, dynamic>> payments;
}

Future<ConvertInvoiceResult?> showConvertInvoiceSheet(BuildContext context, {required double total, required String currency, int? decimals}) =>
    showModalBottomSheet<ConvertInvoiceResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: _ConvertInvoiceSheet(total: total, currency: currency, decimals: decimals)),
    );

class _ConvertInvoiceSheet extends StatefulWidget {
  const _ConvertInvoiceSheet({required this.total, required this.currency, this.decimals});

  final double total;
  final String currency;
  final int? decimals;

  @override
  State<_ConvertInvoiceSheet> createState() => _ConvertInvoiceSheetState();
}

class _ConvertInvoiceSheetState extends State<_ConvertInvoiceSheet> {
  final _amount = TextEditingController(text: '0');
  List<LocalPaymentMode> _modes = const [];
  String? _modeId;
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    cashModes().then((m) {
      if (mounted) {
        setState(() {
          _modes = m;
          _modeId = m.where((x) => x.parDefaut).firstOrNull?.id ?? m.firstOrNull?.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l10n.convertToInvoice, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('${l10n.total}: ${formatMoney(widget.total, currency: widget.currency, decimals: widget.decimals)}'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _modeId,
          decoration: InputDecoration(labelText: l10n.paymentMode),
          items: [for (final m in _modes) DropdownMenuItem(value: m.id, child: Text(localName(m.nomAr, m.nomFr, arabic: arabic)))],
          onChanged: (v) => setState(() => _modeId = v),
        ),
        const SizedBox(height: 12),
        NumberField(controller: _amount, label: l10n.amountPaid, min: 0, required: false),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.event_outlined),
          label: Text(_due == null ? l10n.dueDate : formatDate(_due!, Localizations.localeOf(context))),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(context: context, initialDate: _due ?? now.add(const Duration(days: 30)), firstDate: now, lastDate: now.add(const Duration(days: 365 * 3)));
            if (picked != null) setState(() => _due = picked);
          },
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            final amount = parseAmount(_amount.text) ?? 0;
            Navigator.pop(context, ConvertInvoiceResult(dueDate: _due, payments: amount > 0 && _modeId != null ? [{'mode_paiement_id': _modeId, 'montant': amount}] : const []));
          },
          child: Text(l10n.confirm),
        ),
      ]),
    );
  }
}

/// Résultat de la feuille d'avoir : quantités, retour en stock, motif, remboursement.
class CreditNoteResult {
  const CreditNoteResult({required this.quantities, required this.returnStock, required this.reason, required this.refunds});

  final Map<String, double> quantities;
  final bool returnStock;
  final String? reason;
  final List<Map<String, dynamic>> refunds;
}

Future<CreditNoteResult?> showCreditNoteSheet(BuildContext context, {required List<CreditableLine> lines, required double invoiceSubtotal, required double invoiceDiscount, required double invoiceRemaining, required String currency, int? decimals}) =>
    showModalBottomSheet<CreditNoteResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CreditNoteSheet(lines: lines, invoiceSubtotal: invoiceSubtotal, invoiceDiscount: invoiceDiscount, invoiceRemaining: invoiceRemaining, currency: currency, decimals: decimals),
    );

class _CreditNoteSheet extends StatefulWidget {
  const _CreditNoteSheet({required this.lines, required this.invoiceSubtotal, required this.invoiceDiscount, required this.invoiceRemaining, required this.currency, this.decimals});

  final List<CreditableLine> lines;
  final double invoiceSubtotal;
  final double invoiceDiscount;
  final double invoiceRemaining;
  final String currency;
  final int? decimals;

  @override
  State<_CreditNoteSheet> createState() => _CreditNoteSheetState();
}

class _CreditNoteSheetState extends State<_CreditNoteSheet> {
  final Map<String, double> _quantities = {};
  final _reason = TextEditingController();
  final _refund = TextEditingController();
  bool _returnStock = true;
  List<LocalPaymentMode> _modes = const [];
  String? _modeId;

  CreditNotePlan get _plan => CreditNotePlan(lines: widget.lines, quantities: _quantities, invoiceSubtotal: widget.invoiceSubtotal, invoiceDiscount: widget.invoiceDiscount, invoiceRemaining: widget.invoiceRemaining);

  @override
  void initState() {
    super.initState();
    cashModes().then((m) {
      if (mounted) {
        setState(() {
          _modes = m;
          _modeId = m.where((x) => x.parDefaut).firstOrNull?.id ?? m.firstOrNull?.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _reason.dispose();
    _refund.dispose();
    super.dispose();
  }

  void _setQuantity(CreditableLine line, double value) {
    setState(() {
      _quantities[line.id] = value.clamp(0, line.remaining).toDouble();
      _refund.text = _plan.dueBack > 0 ? _plan.dueBack.toString() : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String money(double v) => formatMoney(v, currency: widget.currency, decimals: widget.decimals);
    final plan = _plan;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l10n.createCreditNote, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.creditNoteHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            for (final line in widget.lines)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(localName(line.labelAr, line.labelFr, arabic: arabic)),
                subtitle: Text('${formatQuantity(line.quantity)} × ${money(line.unitPrice)}${line.alreadyCredited > 0 ? ' · ${l10n.alreadyCredited(formatQuantity(line.alreadyCredited))}' : ''}'),
                trailing: line.remaining <= 0
                    ? null
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _setQuantity(line, (_quantities[line.id] ?? 0) - 1)),
                        SizedBox(width: 28, child: Text(formatQuantity(_quantities[line.id] ?? 0), textAlign: TextAlign.center)),
                        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _setQuantity(line, (_quantities[line.id] ?? 0) + 1)),
                      ]),
              ),
            const Divider(),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.creditNoteReturnStock), value: _returnStock, onChanged: (v) => setState(() => _returnStock = v)),
            TextField(controller: _reason, decoration: InputDecoration(labelText: l10n.note)),
            const SizedBox(height: 8),
            Text('${l10n.total}: ${money(plan.total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (plan.applied > 0) Text('${l10n.remainingDue}: -${money(plan.applied)}'),
            if (plan.dueBack > 0) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _modeId,
                decoration: InputDecoration(labelText: l10n.refundMode),
                items: [for (final m in _modes) DropdownMenuItem(value: m.id, child: Text(localName(m.nomAr, m.nomFr, arabic: arabic)))],
                onChanged: (v) => setState(() => _modeId = v),
              ),
              const SizedBox(height: 8),
              NumberField(controller: _refund, label: l10n.refundAmount, min: 0, required: false),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: !plan.isValid
                  ? null
                  : () {
                      final refund = parseAmount(_refund.text) ?? 0;
                      Navigator.pop(
                        context,
                        CreditNoteResult(
                          quantities: Map.of(_quantities),
                          returnStock: _returnStock,
                          reason: _reason.text,
                          refunds: refund > 0 && _modeId != null ? [{'mode_paiement_id': _modeId, 'montant': refund}] : const [],
                        ),
                      );
                    },
              child: Text(l10n.confirm),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Demande le motif d'annulation (obligatoire côté serveur) ; null si abandonné.
Future<String?> askCancelReason(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.cancelDocument),
      content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: l10n.cancelReason)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim().isEmpty ? null : controller.text.trim()), child: Text(l10n.confirm)),
      ],
    ),
  );
  controller.dispose();
  return result;
}
