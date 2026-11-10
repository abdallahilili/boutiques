import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/types/database_types.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../../pos/presentation/receipt_page.dart' show InvoiceActions;
import '../domain/invoice_data.dart';

/// Liste des factures et tickets (connexion requise) : tout / impayées, détail et PDF à la demande.
class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final _client = Get.find<SupabaseClient>();
  final _shop = Get.find<ShopController>();
  bool _unpaidOnly = false;
  late Future<List<Map<String, dynamic>>> _future = _load();

  Future<List<Map<String, dynamic>>> _load() {
    var q = _client.from(Tables.documentsVente).select('id,numero,date_emission,total,reste,statut,type').inFilter('type', ['facture', 'ticket']);
    if (_unpaidOnly) q = q.gt('reste', 0).neq('statut', 'annulee');
    return q.order('date_emission', ascending: false).limit(100);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String money(num v) => formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuDocuments), actions: [FilterChip(label: Text(l10n.unpaidOnly), selected: _unpaidOnly, onSelected: (v) => setState(() { _unpaidOnly = v; _future = _load(); })), const SizedBox(width: 8)]),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: () => setState(() => _future = _load()));
            final docs = snapshot.data!;
            if (docs.isEmpty) return const EmptyState(icon: Icons.receipt_long_outlined);
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = docs[i];
                final remaining = asDouble(d['reste']);
                return ListTile(
                  leading: Icon(d['statut'] == 'annulee' ? Icons.cancel_outlined : remaining > 0 ? Icons.pending_outlined : Icons.check_circle_outline, color: remaining > 0 ? Colors.orange : null),
                  title: Text(d['numero'] as String, textDirection: TextDirection.ltr),
                  subtitle: Text(formatDate(DateTime.parse(d['date_emission'] as String), Localizations.localeOf(context), time: true)),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(money(asDouble(d['total'])), style: const TextStyle(fontWeight: FontWeight.w600)), if (remaining > 0) Text('${l10n.remainingDue}: ${money(remaining)}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.error))]),
                  onTap: () => Get.toNamed(Routes.documentDetail, arguments: d['id']),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Document reconstitué depuis la base (en-tête figé + lignes + paiements) ; le PDF est généré à la demande.
class DocumentDetailPage extends StatefulWidget {
  const DocumentDetailPage({super.key});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  final String _id = Get.arguments as String;
  late final Future<InvoiceData> _future = _load();

  Future<InvoiceData> _load() async {
    final client = Get.find<SupabaseClient>();
    final shop = Get.find<ShopController>();
    final document = await client.from(Tables.documentsVente).select().eq('id', _id).single();
    final lines = await client.from(Tables.lignesDocumentVenteVue).select().eq('document_id', _id).order('ordre');
    final payments = await client.from(Tables.paiements).select().eq('document_id', _id).order('paye_le');
    final modes = await Get.find<AppDatabase>().watchPaymentModes(shop.shopId).first;
    return InvoiceData.fromServer(
      document: document,
      lines: lines,
      payments: payments,
      modeNamesAr: {for (final m in modes) m.id: m.nomAr},
      modeNamesFr: {for (final m in modes) m.id: m.nomFr},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuDocuments)),
      body: FutureBuilder<InvoiceData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!));
          final d = snapshot.data!;
          String money(double v) => formatMoney(v, currency: d.currency, decimals: d.decimals);
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(d.number ?? '', style: Theme.of(context).textTheme.headlineSmall, textDirection: TextDirection.ltr),
            Text(formatDate(d.date, Localizations.localeOf(context), time: true)),
            if (d.customerName != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(d.customerName!)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  for (final l in d.lines) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text('${formatQuantity(l.quantity)} × ${localName(l.labelAr, l.labelFr, arabic: arabic)}')), Text(money(l.total))])),
                  const Divider(),
                  if (d.discount > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.discount), Text('-${money(d.discount)}')]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.bold)), Text(money(d.total), style: const TextStyle(fontWeight: FontWeight.bold))]),
                  for (final p in d.payments) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(localName(p.nameAr, p.nameFr, arabic: arabic)), Text(money(p.amount))]),
                  if (d.remaining > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.remainingDue), Text(money(d.remaining), style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold))]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            InvoiceActions(invoice: d, customerPhone: d.customerPhone),
          ]);
        },
      ),
    );
  }
}
