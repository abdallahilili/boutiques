import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/variant_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../documents/presentation/documents_pages.dart' show ensureOnline;
import '../data/transfers_service.dart';
import '../domain/transfer_models.dart';

String transferStatusLabel(AppLocalizations l10n, String status) => switch (status) {
      'en_attente' => l10n.transferPending,
      'accepte' => l10n.statusAccepted,
      'refuse' => l10n.statusRefused,
      'annule' => l10n.transferCancelled,
      _ => status,
    };

/// Transferts reçus et envoyés. L'émettrice sort le stock à l'envoi ; la destinataire accepte ou refuse.
class TransfersPage extends StatefulWidget {
  const TransfersPage({super.key});

  @override
  State<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends State<TransfersPage> {
  final _service = TransfersService(Get.find<SupabaseClient>());
  final _shop = Get.find<ShopController>();
  late Future<List<TransferSummary>> _future = _service.list(_shop.shopId);

  void _reload() => setState(() => _future = _service.list(_shop.shopId));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String money(num v) => formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.menuTransfers), bottom: TabBar(tabs: [Tab(text: l10n.transfersReceived), Tab(text: l10n.transfersSent)])),
        floatingActionButton: _shop.can('stock.ecrire') && !_shop.readOnly
            ? FloatingActionButton.extended(onPressed: () => Get.toNamed<void>(Routes.transferForm)?.then((_) => _reload()), icon: const Icon(Icons.swap_horiz), label: Text(l10n.newTransfer))
            : null,
        body: FutureBuilder<List<TransferSummary>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: _reload);
            final all = snapshot.data!;
            Widget tab(bool sent) {
              final items = all.where((t) => t.sent == sent).toList();
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: items.isEmpty
                    ? ListView(children: const [SizedBox(height: 120), EmptyState(icon: Icons.swap_horiz)])
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final t = items[i];
                          return ListTile(
                            leading: Icon(t.pending ? Icons.hourglass_bottom : t.status == 'accepte' ? Icons.check_circle_outline : Icons.cancel_outlined, color: t.pending ? Colors.orange : null),
                            title: Text('${t.number} · ${localName(t.otherAr, t.otherFr, arabic: arabic)}'),
                            subtitle: Text('${formatDate(t.createdAt, Localizations.localeOf(context), time: true)} · ${transferStatusLabel(l10n, t.status)}'),
                            trailing: Text(money(t.total), style: const TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () => Get.toNamed<void>(Routes.transferDetail, arguments: t.id)?.then((_) => _reload()),
                          );
                        },
                      ),
              );
            }

            return TabBarView(children: [tab(false), tab(true)]);
          },
        ),
      ),
    );
  }
}

/// Envoi d'un transfert : destinataire (code boutique ou téléphone), articles, prix de transfert.
class TransferFormPage extends StatefulWidget {
  const TransferFormPage({super.key});

  @override
  State<TransferFormPage> createState() => _TransferFormPageState();
}

class _TransferFormPageState extends State<TransferFormPage> {
  final _service = TransfersService(Get.find<SupabaseClient>());
  final _shop = Get.find<ShopController>();
  final _id = const Uuid().v4();
  final _recipient = TextEditingController();
  final _note = TextEditingController();
  final _draft = TransferDraft();
  bool _busy = false;

  @override
  void dispose() {
    _recipient.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _addLine() async {
    final variant = await pickVariant(context);
    if (variant == null) return;
    setState(() => _draft.addOrIncrement(TransferDraftLine(variantId: variant.id, labelAr: variant.libelleAr, labelFr: variant.libelleFr, available: variant.enStock, price: variant.prixVente)));
  }

  Future<void> _editLine(TransferDraftLine line) async {
    final l10n = AppLocalizations.of(context);
    final quantity = TextEditingController(text: formatQuantity(line.quantity));
    final price = TextEditingController(text: formatQuantity(line.price));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localName(line.labelAr, line.labelFr, arabic: Localizations.localeOf(context).languageCode == 'ar')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          NumberField(controller: quantity, label: '${l10n.quantityLabel} (max ${formatQuantity(line.available)})', min: 0.001),
          const SizedBox(height: 8),
          NumberField(controller: price, label: l10n.transferPrice, min: 0),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save))],
      ),
    );
    if (ok == true) {
      setState(() {
        line.quantity = parseAmount(quantity.text) ?? line.quantity;
        line.price = parseAmount(price.text) ?? line.price;
      });
    }
    quantity.dispose();
    price.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    _draft
      ..recipient = _recipient.text
      ..note = _note.text;
    if (!_draft.isValid) {
      showMessage(l10n.transferInvalid, error: true);
      return;
    }
    if (!ensureOnline(l10n)) return;
    final overdraw = _draft.lines.any((l) => l.quantity > l.available);
    if (overdraw && !await confirmDialog(context, title: l10n.transferExceedsStock)) return;
    setState(() => _busy = true);
    try {
      await _service.send(_draft.toPayload(id: _id, shopId: _shop.shopId));
      Get.find<SyncService>().syncAll();
      showMessage(l10n.transferSent);
      Get.back<void>();
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newTransfer)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(l10n.transferHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        TextField(controller: _recipient, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l10n.recipientHint, prefixIcon: const Icon(Icons.store_outlined))),
        const Divider(height: 32),
        for (final line in _draft.lines)
          Dismissible(
            key: ValueKey(line.variantId),
            background: Container(color: Colors.red.shade100),
            onDismissed: (_) => setState(() => _draft.lines.remove(line)),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(localName(line.labelAr, line.labelFr, arabic: arabic)),
              subtitle: Text('${formatQuantity(line.quantity)} × ${money(line.price)}'),
              trailing: Text(money(line.total), style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => _editLine(line),
            ),
          ),
        OutlinedButton.icon(onPressed: _addLine, icon: const Icon(Icons.add), label: Text(l10n.addLine)),
        const SizedBox(height: 12),
        TextField(controller: _note, maxLines: 2, decoration: InputDecoration(labelText: l10n.note)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.total, style: Theme.of(context).textTheme.titleMedium), Text(money(_draft.total), style: Theme.of(context).textTheme.titleLarge)]),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: _busy ? null : _send, icon: const Icon(Icons.send), label: Text(l10n.sendTransfer)),
      ]),
    );
  }
}

/// Détail d'un transfert : la destinataire associe chaque article à un produit puis accepte ou refuse.
class TransferDetailPage extends StatefulWidget {
  const TransferDetailPage({super.key});

  @override
  State<TransferDetailPage> createState() => _TransferDetailPageState();
}

class _TransferDetailPageState extends State<TransferDetailPage> {
  final String _id = Get.arguments as String;
  final _service = TransfersService(Get.find<SupabaseClient>());
  final _shop = Get.find<ShopController>();
  final Map<String, LineMapping> _mappings = {};
  final Map<String, String> _mappedLabels = {};
  late Future<Map<String, dynamic>> _future = _service.detail(_shop.shopId, _id);
  bool _busy = false;

  void _reload() => setState(() => _future = _service.detail(_shop.shopId, _id));

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    if (!ensureOnline(l10n)) return;
    setState(() => _busy = true);
    try {
      await action();
      Get.find<SyncService>().syncAll();
      showMessage(l10n.transferAnswered);
    } catch (e) {
      if (mounted) showMessage(friendlyError(l10n, e), error: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _reload();
      }
    }
  }

  Future<void> _mapExisting(LineMapping mapping) async {
    final variant = await pickVariant(context);
    if (variant == null || !mounted) return;
    setState(() {
      mapping
        ..create = false
        ..variantId = variant.id
        ..salePrice ??= variant.prixVente;
      _mappedLabels[mapping.lineId] = localName(variant.libelleAr, variant.libelleFr, arabic: Localizations.localeOf(context).languageCode == 'ar');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String money(num v) => formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuTransfers)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: _reload);
          final detail = snapshot.data!;
          final summary = TransferSummary.fromJson(detail);
          final lines = (detail['lignes'] as List).cast<Map<String, dynamic>>();
          final canAnswer = !summary.sent && summary.pending && _shop.can('stock.ecrire') && !_shop.readOnly;
          final canCancel = summary.sent && summary.pending && _shop.can('stock.ecrire') && !_shop.readOnly;
          for (final line in lines) {
            _mappings.putIfAbsent(line['id'] as String, () => LineMapping(lineId: line['id'] as String, salePrice: asDouble(line['prix_unitaire'])));
          }
          final complete = lines.every((l) => _mappings[l['id']]!.isComplete);
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(child: Text(summary.number, style: Theme.of(context).textTheme.headlineSmall, textDirection: TextDirection.ltr)),
              Chip(label: Text(transferStatusLabel(l10n, summary.status))),
            ]),
            Text('${summary.sent ? l10n.transferTo : l10n.transferFrom}: ${localName(summary.otherAr, summary.otherFr, arabic: arabic)}'),
            Text(formatDate(summary.createdAt, Localizations.localeOf(context), time: true)),
            if (detail['note'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(detail['note'] as String)),
            const SizedBox(height: 12),
            for (final line in lines)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('${formatQuantity(asDouble(line['quantite']))} × ${localName(line['libelle_ar'] as String?, line['libelle_fr'] as String?, arabic: arabic)}')),
                      Text(money(asDouble(line['total']))),
                    ]),
                    if (canAnswer) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        ChoiceChip(label: Text(l10n.createProduct), selected: _mappings[line['id']]!.create, onSelected: (_) => setState(() => _mappings[line['id']]!.create = true)),
                        ChoiceChip(label: Text(_mappings[line['id']]!.create ? l10n.mapToProduct : (_mappedLabels[line['id']] ?? l10n.mapToProduct)), selected: !_mappings[line['id']]!.create, onSelected: (_) => _mapExisting(_mappings[line['id']]!)),
                      ]),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          initialValue: formatQuantity(_mappings[line['id']]!.salePrice ?? 0),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: l10n.salePriceLabel, isDense: true),
                          onChanged: (v) => setState(() => _mappings[line['id']]!.salePrice = parseAmount(v)),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.bold)), Text(money(summary.total), style: const TextStyle(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            if (canAnswer)
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: _busy ? null : () async {
                  if (await confirmDialog(context, title: l10n.refuseTransfer)) {
                    await _run(() async => _service.respond(buildTransferResponse(transferId: _id, accept: false)));
                  }
                }, child: Text(l10n.refuseTransfer))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: _busy || !complete ? null : () => _run(() async => _service.respond(buildTransferResponse(transferId: _id, accept: true, mappings: [for (final l in lines) _mappings[l['id']]!]))), child: Text(l10n.acceptTransfer))),
              ]),
            if (canCancel) OutlinedButton(onPressed: _busy ? null : () async {
              if (await confirmDialog(context, title: l10n.cancelTransfer)) await _run(() async => _service.cancel(_id));
            }, child: Text(l10n.cancelTransfer)),
          ]);
        },
      ),
    );
  }
}
