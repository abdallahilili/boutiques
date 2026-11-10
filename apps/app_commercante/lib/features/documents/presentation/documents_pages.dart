import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../../pos/presentation/receipt_page.dart' show InvoiceActions;
import '../data/documents_service.dart';
import '../data/invoice_pdf.dart' show documentTitle;
import '../domain/document_payloads.dart';
import '../domain/invoice_data.dart';
import 'document_sheets.dart';

/// Libellé traduit du statut d'un document de vente.
String documentStatusLabel(AppLocalizations l10n, String status) => switch (status) {
      'brouillon' => l10n.statusDraft,
      'envoye' => l10n.statusSent,
      'accepte' => l10n.statusAccepted,
      'refuse' => l10n.statusRefused,
      'expire' => l10n.statusExpired,
      'valide' => l10n.statusValidated,
      'livre' => l10n.statusDelivered,
      'facture' => l10n.statusInvoiced,
      'emise' => l10n.statusIssued,
      'partiellement_payee' => l10n.statusPartiallyPaid,
      'payee' => l10n.statusPaid,
      'annulee' => l10n.statusCancelled,
      _ => status,
    };

/// Contrôle de connexion avant une opération serveur (les documents ne sont pas créés hors ligne).
bool ensureOnline(AppLocalizations l10n) {
  if (Get.find<SyncService>().online.value) return true;
  showMessage(l10n.onlineOnly, error: true);
  return false;
}

/// Liste des documents de vente par famille : factures/tickets, devis, bons de livraison, avoirs.
class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final _service = DocumentsService(Get.find<SupabaseClient>());
  final _shop = Get.find<ShopController>();
  DocumentFamily _family = DocumentFamily.invoices;
  bool _unpaidOnly = false;
  final Set<String> _selected = {};
  late Future<List<Map<String, dynamic>>> _future = _load();

  Future<List<Map<String, dynamic>>> _load() => _service.list(_family, unpaidOnly: _unpaidOnly && _family == DocumentFamily.invoices);

  void _reload() => setState(() {
        _selected.clear();
        _future = _load();
      });

  Future<void> _invoiceSelection() async {
    final l10n = AppLocalizations.of(context);
    if (!ensureOnline(l10n)) return;
    final result = await showConvertInvoiceSheet(context, total: 0, currency: _shop.currency, decimals: _shop.decimals);
    if (result == null) return;
    try {
      final created = await _service.convert(newId: const Uuid().v4(), sourceIds: _selected.toList(), target: 'facture', dueDate: result.dueDate, payments: result.payments);
      showMessage(l10n.documentCreated);
      _reload();
      Get.toNamed(Routes.documentDetail, arguments: created['id']);
    } catch (e) {
      if (mounted) showMessage(friendlyError(l10n, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String money(num v) => formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);
    final labels = {
      DocumentFamily.invoices: l10n.docTypeInvoice,
      DocumentFamily.quotes: l10n.docTypeQuote,
      DocumentFamily.deliveries: l10n.docTypeDelivery,
      DocumentFamily.credits: l10n.docTypeCredit,
    };
    final canCreate = _shop.can('documents.creer') && !_shop.readOnly;
    final createType = switch (_family) {
      DocumentFamily.quotes => 'devis',
      DocumentFamily.deliveries => 'bon_livraison',
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuDocuments)),
      floatingActionButton: canCreate && createType != null
          ? FloatingActionButton.extended(
              onPressed: () => Get.toNamed<void>(Routes.documentForm, arguments: createType)?.then((_) => _reload()),
              icon: const Icon(Icons.add),
              label: Text(createType == 'devis' ? l10n.newQuote : l10n.newDeliveryNote),
            )
          : null,
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: FilledButton.icon(onPressed: _invoiceSelection, icon: const Icon(Icons.receipt_long), label: Text('${l10n.invoiceSelected} (${_selected.length})')))),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            for (final f in DocumentFamily.values)
              Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(labels[f]!), selected: _family == f, onSelected: (_) => setState(() { _family = f; _future = _load(); _selected.clear(); }))),
            if (_family == DocumentFamily.invoices) FilterChip(label: Text(l10n.unpaidOnly), selected: _unpaidOnly, onSelected: (v) => setState(() { _unpaidOnly = v; _future = _load(); })),
          ]),
        ),
        if (_family == DocumentFamily.deliveries && _shop.can('documents.gerer')) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.selectDeliveryNotes, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _reload(),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: _reload);
                final docs = snapshot.data!;
                if (docs.isEmpty) return ListView(children: const [SizedBox(height: 120), EmptyState(icon: Icons.receipt_long_outlined)]);
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final id = d['id'] as String;
                    final remaining = asDouble(d['reste']);
                    final status = d['statut'] as String;
                    final selectable = _family == DocumentFamily.deliveries && _shop.can('documents.gerer') && (status == 'valide' || status == 'livre');
                    final due = _family == DocumentFamily.invoices && remaining > 0 && status != 'annulee';
                    return ListTile(
                      selected: _selected.contains(id),
                      leading: Icon(status == 'annulee' ? Icons.cancel_outlined : due ? Icons.pending_outlined : Icons.check_circle_outline, color: due ? Colors.orange : null),
                      title: Text(d['numero'] as String, textDirection: TextDirection.ltr),
                      subtitle: Text('${formatDate(DateTime.parse(d['date_emission'] as String), Localizations.localeOf(context), time: true)} · ${documentStatusLabel(l10n, status)}'),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(money(asDouble(d['total'])), style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (due) Text('${l10n.remainingDue}: ${money(remaining)}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.error)),
                      ]),
                      onLongPress: selectable ? () => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id)) : null,
                      onTap: _selected.isNotEmpty && selectable
                          ? () => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id))
                          : () => Get.toNamed<void>(Routes.documentDetail, arguments: id)?.then((_) => _reload()),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

/// Document reconstitué depuis la base (en-tête figé + lignes + paiements + liens) ; PDF généré à la demande.
class DocumentDetailPage extends StatefulWidget {
  const DocumentDetailPage({super.key});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  final String _id = Get.arguments as String;
  final _service = DocumentsService(Get.find<SupabaseClient>());
  final _shop = Get.find<ShopController>();
  late Future<(DocumentBundle, InvoiceData)> _future = _load();
  bool _busy = false;

  Future<(DocumentBundle, InvoiceData)> _load() async {
    final bundle = await _service.load(_id);
    final modes = await Get.find<AppDatabase>().watchPaymentModes(_shop.shopId).first;
    final data = InvoiceData.fromServer(
      document: bundle.document,
      lines: bundle.lines,
      payments: bundle.payments,
      modeNamesAr: {for (final m in modes) m.id: m.nomAr},
      modeNamesFr: {for (final m in modes) m.id: m.nomFr},
    );
    return (bundle, data);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    if (!ensureOnline(l10n)) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showMessage(friendlyError(l10n, e), error: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _reload();
      }
    }
  }

  Future<void> _convert(DocumentBundle bundle, InvoiceData data, String target) async {
    final l10n = AppLocalizations.of(context);
    ConvertInvoiceResult? options;
    if (target == 'facture') {
      options = await showConvertInvoiceSheet(context, total: data.total, currency: data.currency, decimals: data.decimals);
      if (options == null) return;
    } else if (!await confirmDialog(context, title: l10n.convertToDelivery)) {
      return;
    }
    await _run(() async {
      final created = await _service.convert(newId: const Uuid().v4(), sourceIds: [bundle.id], target: target, dueDate: options?.dueDate, payments: options?.payments ?? const []);
      showMessage(l10n.documentCreated);
      Get.toNamed<void>(Routes.documentDetail, arguments: created['id']);
    });
  }

  Future<void> _credit(DocumentBundle bundle, InvoiceData data) async {
    final l10n = AppLocalizations.of(context);
    if (!ensureOnline(l10n)) return;
    final lines = await _service.creditableLines(bundle.id);
    if (!mounted) return;
    final result = await showCreditNoteSheet(
      context,
      lines: lines,
      invoiceSubtotal: data.subtotal,
      invoiceDiscount: data.discount,
      invoiceRemaining: asDouble(bundle.document['reste']),
      currency: data.currency,
      decimals: data.decimals,
    );
    if (result == null) return;
    final plan = CreditNotePlan(lines: lines, quantities: result.quantities, invoiceSubtotal: data.subtotal, invoiceDiscount: data.discount, invoiceRemaining: asDouble(bundle.document['reste']));
    await _run(() async {
      final created = await _service.createCreditNote(plan.toPayload(id: const Uuid().v4(), invoiceId: bundle.id, returnStock: result.returnStock, reason: result.reason, refunds: result.refunds));
      showMessage(l10n.documentCreated);
      Get.toNamed<void>(Routes.documentDetail, arguments: created['id']);
    });
  }

  Widget _actions(AppLocalizations l10n, DocumentBundle bundle, InvoiceData data) {
    if (_shop.readOnly) return const SizedBox.shrink();
    final actions = availableActions(
      type: bundle.type,
      status: bundle.status,
      canCreate: _shop.can('documents.creer'),
      canManage: _shop.can('documents.gerer'),
      alreadyConverted: bundle.hasActiveDerived,
    );
    if (actions.isEmpty) return const SizedBox.shrink();
    Widget button(DocumentAction action, IconData icon, String label, VoidCallback onPressed, {bool primary = false, bool danger = false}) {
      final child = Text(label);
      final style = danger ? OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error) : null;
      if (!actions.contains(action)) return const SizedBox.shrink();
      return primary
          ? FilledButton.icon(onPressed: _busy ? null : onPressed, icon: Icon(icon), label: child)
          : OutlinedButton.icon(style: style, onPressed: _busy ? null : onPressed, icon: Icon(icon), label: child);
    }

    return Wrap(spacing: 8, runSpacing: 8, children: [
      button(DocumentAction.send, Icons.send_outlined, l10n.actionSend, () => _run(() async => _service.setQuoteStatus(bundle.id, 'envoye'))),
      button(DocumentAction.accept, Icons.thumb_up_outlined, l10n.actionAccept, () => _run(() async => _service.setQuoteStatus(bundle.id, 'accepte'))),
      button(DocumentAction.refuse, Icons.thumb_down_outlined, l10n.actionRefuse, () => _run(() async => _service.setQuoteStatus(bundle.id, 'refuse'))),
      button(DocumentAction.validate, Icons.inventory_outlined, l10n.actionValidate, () => _run(() async => _service.setDeliveryStatus(bundle.id, 'valide')), primary: true),
      button(DocumentAction.deliver, Icons.local_shipping_outlined, l10n.actionDeliver, () => _run(() async => _service.setDeliveryStatus(bundle.id, 'livre')), primary: true),
      button(DocumentAction.convertToDelivery, Icons.local_shipping_outlined, l10n.convertToDelivery, () => _convert(bundle, data, 'bon_livraison')),
      button(DocumentAction.convertToInvoice, Icons.receipt_long_outlined, l10n.convertToInvoice, () => _convert(bundle, data, 'facture'), primary: true),
      button(DocumentAction.createCredit, Icons.assignment_return_outlined, l10n.createCreditNote, () => _credit(bundle, data)),
      button(DocumentAction.cancel, Icons.cancel_outlined, l10n.cancelDocument, () async {
        final reason = await askCancelReason(context);
        if (reason == null) return;
        await _run(() async => _service.cancel(bundle.id, reason));
      }, danger: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuDocuments)),
      body: FutureBuilder<(DocumentBundle, InvoiceData)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: _reload);
          final (bundle, d) = snapshot.data!;
          String money(double v) => formatMoney(v, currency: d.currency, decimals: d.decimals);
          final isCommercial = d.type == 'facture' || d.type == 'ticket';
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(child: Text('${documentTitle(d.type, arabic: arabic)} ${d.number ?? ''}', style: Theme.of(context).textTheme.headlineSmall, textDirection: TextDirection.ltr)),
              Chip(label: Text(documentStatusLabel(l10n, bundle.status))),
            ]),
            Text(formatDate(d.date, Localizations.localeOf(context), time: true)),
            if (d.type == 'devis' && d.dueDate != null) Text('${l10n.validUntil}: ${formatDate(d.dueDate!, Localizations.localeOf(context))}'),
            if (d.customerName != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(d.customerName!)),
            if (bundle.document['motif_annulation'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('${l10n.cancelReason}: ${bundle.document['motif_annulation']}', style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  for (final l in d.lines) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text('${formatQuantity(l.quantity)} × ${localName(l.labelAr, l.labelFr, arabic: arabic)}')), Text(money(l.total))])),
                  const Divider(),
                  if (d.discount > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.discount), Text('-${money(d.discount)}')]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.bold)), Text(money(d.total), style: const TextStyle(fontWeight: FontWeight.bold))]),
                  if (isCommercial) ...[
                    for (final p in d.payments) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(localName(p.nameAr, p.nameFr, arabic: arabic)), Text(money(p.amount))]),
                    if (d.remaining > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.remainingDue), Text(money(d.remaining), style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold))]),
                  ],
                ]),
              ),
            ),
            if (bundle.sources.isNotEmpty || bundle.derived.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.linkedDocuments, style: Theme.of(context).textTheme.titleSmall),
              for (final linked in [...bundle.sources, ...bundle.derived])
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link),
                  title: Text('${documentTitle(linked['type'] as String, arabic: arabic)} ${linked['numero']}', textDirection: TextDirection.ltr),
                  subtitle: Text(documentStatusLabel(l10n, linked['statut'] as String)),
                  onTap: () => Get.toNamed<void>(Routes.documentDetail, arguments: linked['id']),
                ),
            ],
            const SizedBox(height: 16),
            _actions(l10n, bundle, d),
            const SizedBox(height: 16),
            InvoiceActions(invoice: d, customerPhone: d.customerPhone),
          ]);
        },
      ),
    );
  }
}
