import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routing/app_pages.dart';
import '../../core/session/shop_controller.dart';
import '../../core/sync/sync_service.dart';
import '../../core/util/format.dart';
import '../../core/widgets/common.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/auth_controller.dart';
import '../catalog/presentation/products_page.dart';
import '../pos/presentation/pos_page.dart';
import '../stock/presentation/stock_page.dart';
import 'home_controller.dart';

/// Coque de navigation : Accueil, Vente (POS), Produits, Stock, Plus.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shop = Get.find<ShopController>();
    final titles = [l10n.tabHome, l10n.tabSell, l10n.tabProducts, l10n.tabStock, l10n.tabMore];

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(_index == 0 ? localName(shop.active.value?.nomAr, shop.active.value?.nomFr, arabic: Localizations.localeOf(context).languageCode == 'ar') : titles[_index])),
        actions: [const _SyncIndicator(), if (shop.shops.length > 1) const _ShopSwitcher()],
      ),
      body: Column(children: [
        const StatusBanners(),
        Expanded(
          child: IndexedStack(index: _index, children: const [DashboardTab(), PosPage(), ProductsPage(), StockPage(), MoreTab()]),
        ),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n.tabHome),
          NavigationDestination(icon: const Icon(Icons.point_of_sale_outlined), selectedIcon: const Icon(Icons.point_of_sale), label: l10n.tabSell),
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), selectedIcon: const Icon(Icons.inventory_2), label: l10n.tabProducts),
          NavigationDestination(icon: const Icon(Icons.warehouse_outlined), selectedIcon: const Icon(Icons.warehouse), label: l10n.tabStock),
          NavigationDestination(icon: const Icon(Icons.menu), label: l10n.tabMore),
        ],
      ),
    );
  }
}

/// Indicateur de synchronisation : état réseau, opérations en attente, synchronisation manuelle.
class _SyncIndicator extends StatelessWidget {
  const _SyncIndicator();

  @override
  Widget build(BuildContext context) {
    final sync = Get.find<SyncService>();
    return Obx(() => IconButton(
          tooltip: AppLocalizations.of(context).syncNow,
          onPressed: sync.syncing.value ? null : sync.syncAll,
          icon: sync.syncing.value
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(sync.online.value ? Icons.cloud_done_outlined : Icons.cloud_off_outlined),
        ));
  }
}

class _ShopSwitcher extends StatelessWidget {
  const _ShopSwitcher();

  @override
  Widget build(BuildContext context) {
    final shop = Get.find<ShopController>();
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return PopupMenuButton<String>(
      icon: const Icon(Icons.store_outlined),
      tooltip: AppLocalizations.of(context).switchShop,
      onSelected: (id) async {
        await shop.select(id);
        await Get.find<SyncService>().syncAll();
        Get.offAllNamed(Routes.home);
      },
      itemBuilder: (_) => [for (final s in shop.shops) PopupMenuItem(value: s.id, child: Text(localName(s.nomAr, s.nomFr, arabic: arabic)))],
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _controller = Get.put(HomeController(Get.find(), Get.find()));

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shop = Get.find<ShopController>();

    Widget metric(String label, String value, {IconData? icon, Color? color, VoidCallback? onTap}) => Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [if (icon != null) Icon(icon, size: 18, color: color), if (icon != null) const SizedBox(width: 6), Expanded(child: Text(label, style: Theme.of(context).textTheme.labelMedium))]),
                const SizedBox(height: 6),
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        );

    return RefreshIndicator(
      onRefresh: () async {
        await Get.find<SyncService>().syncAll();
        await _controller.load();
      },
      child: Obx(() {
        final stats = _controller.stats.value;
        if (stats == null) {
          return ListView(children: [
            if (_controller.error.value != null) ErrorView(message: l10n.networkError, onRetry: _controller.load) else const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
          ]);
        }
        String money(double? v) => formatMoney(v ?? 0, currency: shop.currency, decimals: shop.decimals);
        return ListView(padding: const EdgeInsets.all(12), children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.9,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              if (stats.hasFinancials) metric('${l10n.revenue} · ${l10n.dashboardToday}', money(stats.revenueToday), icon: Icons.payments_outlined),
              if (stats.hasFinancials) metric('${l10n.revenue} · ${l10n.dashboardWeek}', money(stats.revenueWeek), icon: Icons.date_range_outlined),
              if (stats.hasFinancials) metric('${l10n.revenue} · ${l10n.dashboardMonth}', money(stats.revenueMonth), icon: Icons.calendar_month_outlined),
              metric(l10n.salesCount, '${stats.salesToday}', icon: Icons.receipt_long_outlined),
              metric(l10n.outOfStock, '${stats.outOfStock}', icon: Icons.production_quantity_limits, color: Colors.red),
              metric(l10n.lowStock, '${stats.lowStock}', icon: Icons.trending_down, color: Colors.orange),
              metric(l10n.ordersToProcess, '${stats.ordersToProcess}', icon: Icons.shopping_bag_outlined, onTap: () => Get.toNamed(Routes.orders)),
              if (stats.hasFinancials) metric(l10n.unpaidCustomers, money(stats.unpaid), icon: Icons.account_balance_wallet_outlined, onTap: () => Get.toNamed(Routes.customers)),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.shortcuts, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (shop.can('pos.vendre')) ActionChip(avatar: const Icon(Icons.point_of_sale), label: Text(l10n.newSale), onPressed: () => Get.toNamed(Routes.sale)),
            if (shop.can('produits.ecrire')) ActionChip(avatar: const Icon(Icons.add_box_outlined), label: Text(l10n.newProduct), onPressed: () => Get.toNamed(Routes.productForm)),
            if (shop.can('stock.ecrire')) ActionChip(avatar: const Icon(Icons.move_to_inbox_outlined), label: Text(l10n.stockEntry), onPressed: () => Get.toNamed(Routes.stockEntry)),
          ]),
        ]);
      }),
    );
  }
}

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shop = Get.find<ShopController>();
    final auth = Get.find<AuthController>();

    Widget item(IconData icon, String label, String route, {bool visible = true, Widget? trailing}) => visible
        ? ListTile(leading: Icon(icon), title: Text(label), trailing: trailing ?? const Icon(Icons.chevron_right), onTap: () => Get.toNamed(route))
        : const SizedBox.shrink();

    return Obx(() => ListView(children: [
          item(Icons.shopping_bag_outlined, l10n.menuOrders, Routes.orders, visible: shop.can('commandes.lire')),
          item(Icons.receipt_long_outlined, l10n.menuDocuments, Routes.documents, visible: shop.can('documents.creer')),
          item(Icons.storefront_outlined, l10n.menuSite, Routes.site, visible: shop.can('parametres.lire')),
          item(Icons.bar_chart, l10n.menuReports, Routes.reports, visible: shop.can('rapports.financiers')),
          item(Icons.payments_outlined, l10n.menuExpenses, Routes.expenses, visible: shop.can('depenses.gerer')),
          item(Icons.swap_horiz, l10n.menuTransfers, Routes.transfers, visible: shop.can('stock.lire')),
          item(Icons.people_outline, l10n.menuCustomers, Routes.customers, visible: shop.can('clients.lire')),
          item(Icons.palette_outlined, l10n.menuReferentials, Routes.referentials, visible: shop.can('referentiels.lire')),
          item(Icons.notifications_outlined, l10n.menuNotifications, Routes.notifications),
          item(Icons.sync, l10n.menuSync, Routes.sync),
          item(Icons.print_outlined, l10n.printerSettings, Routes.printer),
          item(Icons.download_outlined, l10n.exportData, Routes.exportData, visible: shop.can('parametres.gerer')),
          item(Icons.brightness_6_outlined, l10n.appearance, Routes.appearance),
          item(Icons.settings_outlined, l10n.menuSettings, Routes.settings, visible: shop.can('parametres.lire')),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout), title: Text(l10n.logout), onTap: auth.signOut),
        ]));
  }
}
