import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../../core/session/shop_controller.dart';
import '../../../core/util/format.dart';
import '../../../l10n/app_localizations.dart';
import '../cash_session_controller.dart';

/// Ouverture (fond de caisse) ou clôture (montant compté, rapport Z) de la session de caisse.
Future<void> showCashSessionSheet(BuildContext context) {
  final session = Get.find<CashSessionController>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CashSessionSheet(open: session.sessionId.value != null),
  );
}

class _CashSessionSheet extends StatefulWidget {
  const _CashSessionSheet({required this.open});

  final bool open;

  @override
  State<_CashSessionSheet> createState() => _CashSessionSheetState();
}

class _CashSessionSheetState extends State<_CashSessionSheet> {
  final _amount = TextEditingController();
  final _session = Get.find<CashSessionController>();
  final _shop = Get.find<ShopController>();
  Map<String, dynamic>? _report;
  bool _closed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String money(Object? v) => formatMoney(asDouble(v), currency: _shop.currency, decimals: _shop.decimals);

    if (_closed) {
      final r = _report;
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.zReport, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (r == null) Text(l10n.queuedOffline) else ...[
            _line(l10n.cashFloat, money(r['fond_initial'])),
            _line(l10n.cashExpected, money(r['attendu'])),
            _line(l10n.cashCounted, money(r['compte'])),
            _line(l10n.cashDifference, money(r['ecart']), bold: true),
            const Divider(),
            _line(l10n.salesCount, '${r['nb_documents']}'),
            _line(l10n.revenue, money(r['total_ventes'])),
            for (final m in (r['par_mode'] as List).cast<Map<String, dynamic>>()) _line(localName(m['nom_ar'] as String?, m['nom_fr'] as String?, arabic: Localizations.localeOf(context).languageCode == 'ar'), money(m['montant'])),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
        ]),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.open ? l10n.closeCash : l10n.openCash, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: widget.open ? l10n.cashCounted : l10n.cashFloat, suffixText: _shop.currency),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            final value = parseAmount(_amount.text) ?? 0;
            if (widget.open) {
              final report = await _session.close(value);
              setState(() {
                _report = report;
                _closed = true;
              });
            } else {
              await _session.open(value);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: Text(l10n.confirm),
        ),
      ]),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : null))]),
      );
}
