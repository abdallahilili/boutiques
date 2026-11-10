import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/types/database_types.dart';
import '../../../core/util/contact.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../orders_controller.dart';

String orderStatusLabel(AppLocalizations l10n, String status) => switch (status) {
      'nouvelle' => l10n.orderNew,
      'confirmee' => l10n.orderConfirmed,
      'en_preparation' => l10n.orderPreparing,
      'prete' => l10n.orderReady,
      'expediee' => l10n.orderShipped,
      'livree' => l10n.orderDelivered,
      'annulee' => l10n.orderCancelled,
      'retournee' => l10n.orderReturned,
      _ => status,
    };

Color orderStatusColor(String status) => switch (status) {
      'nouvelle' => Colors.blue,
      'confirmee' || 'en_preparation' => Colors.orange,
      'prete' || 'expediee' => Colors.teal,
      'livree' => Colors.green,
      _ => Colors.grey,
    };

/// Commandes en ligne en temps réel (Realtime Supabase, repli sur interrogation périodique).
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrdersController _c = Get.put(OrdersController(Get.find(), Get.find()));
  final _shop = Get.find<ShopController>();

  @override
  void initState() {
    super.initState();
    _c.onNewOrder = (order) {
      if (mounted) showMessage('${AppLocalizations.of(context).newOrderReceived}: ${order['numero'] ?? ''}');
    };
  }

  @override
  void dispose() {
    Get.delete<OrdersController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String money(num v) => formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);
    const statuses = ['nouvelle', 'confirmee', 'en_preparation', 'prete', 'expediee', 'livree', 'annulee'];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuOrders), actions: [Obx(() => Icon(_c.realtimeConnected.value ? Icons.wifi_tethering : Icons.wifi_tethering_off, color: _c.realtimeConnected.value ? Colors.green : Colors.grey)), const SizedBox(width: 12)]),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: Obx(() => ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(l10n.all), selected: _c.statusFilter.value == null, onSelected: (_) { _c.statusFilter.value = null; _c.load(); })),
                for (final s in statuses) Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(orderStatusLabel(l10n, s)), selected: _c.statusFilter.value == s, onSelected: (_) { _c.statusFilter.value = s; _c.load(); })),
              ])),
        ),
        Expanded(
          child: Obx(() {
            if (_c.loading.value && _c.orders.isEmpty) return const Center(child: CircularProgressIndicator());
            if (_c.error.value != null && _c.orders.isEmpty) return ErrorView(message: friendlyError(l10n, _c.error.value!), onRetry: _c.load);
            if (_c.orders.isEmpty) return const EmptyState(icon: Icons.shopping_bag_outlined);
            return RefreshIndicator(
              onRefresh: _c.load,
              child: ListView.separated(
                itemCount: _c.orders.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final o = _c.orders[i];
                  final status = o['statut'] as String;
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: orderStatusColor(status).withValues(alpha: 0.15), child: Icon(Icons.shopping_bag_outlined, color: orderStatusColor(status))),
                    title: Text('${o['numero']} · ${o['nom_client']}', textDirection: TextDirection.ltr),
                    subtitle: Text('${orderStatusLabel(l10n, status)} · ${formatDate(DateTime.parse(o['cree_le'] as String), Localizations.localeOf(context), time: true)}'),
                    trailing: Text(money(asDouble(o['total'])), style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => Get.toNamed(Routes.orderDetail, arguments: o['id']),
                  );
                },
              ),
            );
          }),
        ),
      ]),
    );
  }
}

/// Fiche commande : articles, cliente, livraison, preuve de paiement, historique et actions de statut.
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final String _id = Get.arguments as String;
  final _client = Get.find<SupabaseClient>();
  final _shop = Get.find<ShopController>();
  late Future<(Map<String, dynamic>, List<Map<String, dynamic>>, List<Map<String, dynamic>>)> _future = _load();

  Future<(Map<String, dynamic>, List<Map<String, dynamic>>, List<Map<String, dynamic>>)> _load() async {
    final order = await _client.from(Tables.commandes).select().eq('id', _id).single();
    final lines = await _client.from(Tables.lignesCommande).select().eq('commande_id', _id);
    final history = await _client.from(Tables.historiqueStatutsCommande).select().eq('commande_id', _id).order('date_statut');
    return (order, lines, history);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    try {
      await action();
      _reload();
    } catch (e) {
      showMessage(friendlyError(l10n, e), error: true);
    }
  }

  Future<void> _openProof(String path) async {
    final url = await _client.storage.from('payment-proofs').createSignedUrl(path, 120);
    await openUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String money(num v) => formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);
    final controller = Get.find<OrdersController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetail)),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: _reload);
          final (order, lines, history) = snapshot.data!;
          final status = order['statut'] as String;
          final next = nextStatuses(status, canManage: _shop.can('commandes.gerer'), canPrepare: _shop.can('commandes.preparer'));
          final phone = order['telephone'] as String;
          final hasDocument = order['document_id'] != null;

          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(child: Text(order['numero'] as String, style: Theme.of(context).textTheme.headlineSmall, textDirection: TextDirection.ltr)),
              Chip(label: Text(orderStatusLabel(l10n, status)), backgroundColor: orderStatusColor(status).withValues(alpha: 0.15)),
            ]),
            const SizedBox(height: 8),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.person_outline), title: Text(order['nom_client'] as String), subtitle: Text(phone, textDirection: TextDirection.ltr), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.call), onPressed: () => callPhone(phone)), IconButton(icon: const Icon(Icons.chat), onPressed: () => openWhatsapp(phone, l10n.orderStatusMessage(order['numero'] as String, orderStatusLabel(l10n, status))))])),
            if (order['adresse'] != null) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.location_on_outlined), title: Text('${order['adresse']}${order['ville'] == null ? '' : ', ${order['ville']}'}')),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.local_shipping_outlined), title: Text(order['mode_livraison'] == 'retrait' ? l10n.pickup : l10n.delivery), subtitle: Text('${l10n.paymentMode}: ${order['mode_paiement']}')),
            if (order['notes'] != null) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.notes), title: Text(order['notes'] as String)),
            if (order['justificatif_url'] != null) OutlinedButton.icon(onPressed: () => _openProof(order['justificatif_url'] as String), icon: const Icon(Icons.receipt_outlined), label: Text(l10n.paymentProof)),
            const Divider(height: 24),
            for (final l in lines) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text('${formatQuantity(asDouble(l['quantite']))} × ${localName(l['libelle_ar'] as String?, l['libelle_fr'] as String?, arabic: arabic)}')), Text(money(asDouble(l['total'])))])),
            const Divider(),
            if (asDouble(order['frais_livraison']) > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.deliveryFee), Text(money(asDouble(order['frais_livraison'])))]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.bold)), Text(money(asDouble(order['total'])), style: const TextStyle(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            if (!_shop.readOnly) Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in next)
                s == 'annulee'
                    ? OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error), onPressed: hasDocument ? null : () async { if (await confirmDialog(context, title: l10n.cancelOrderConfirm)) await _run(() => controller.changeStatus(_id, s)); }, child: Text(orderStatusLabel(l10n, s)))
                    : FilledButton(onPressed: () => _run(() => controller.changeStatus(_id, s)), child: Text(orderStatusLabel(l10n, s))),
              if (_shop.can('commandes.gerer') && !hasDocument && !{'nouvelle', 'annulee', 'retournee'}.contains(status)) OutlinedButton.icon(icon: const Icon(Icons.receipt_long), label: Text(l10n.generateInvoice), onPressed: () => _run(() async { final r = await controller.generateInvoice(_id, const Uuid().v4()); showMessage('${l10n.invoiceCreated}: ${r['numero']}'); })),
              if (hasDocument) OutlinedButton.icon(icon: const Icon(Icons.receipt_long), label: Text(l10n.viewInvoice), onPressed: () => Get.toNamed(Routes.documentDetail, arguments: order['document_id'])),
            ]),
            const Divider(height: 32),
            Text(l10n.stockHistory, style: Theme.of(context).textTheme.titleSmall),
            for (final h in history) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(orderStatusLabel(l10n, h['statut'] as String)), trailing: Text(formatDate(DateTime.parse(h['date_statut'] as String), Localizations.localeOf(context), time: true))),
          ]);
        },
      ),
    );
  }
}
