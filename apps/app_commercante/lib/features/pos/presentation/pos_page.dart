import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../../core/db/app_database.dart';
import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/variant_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/presentation/products_page.dart' show productImageUrl;
import '../cart_controller.dart';
import '../cash_session_controller.dart';
import 'cash_session_sheets.dart';

/// Écran de vente rapide : recherche, scan, grille par catégorie, choix de variante, barre de panier.
class PosPage extends StatefulWidget {
  const PosPage({super.key, this.standalone = false});

  /// Ouvert depuis un raccourci (hors onglet) : ajoute une barre d'application.
  final bool standalone;

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final _db = Get.find<AppDatabase>();
  final _shop = Get.find<ShopController>();
  final _cart = Get.find<CartController>();
  final _session = Get.find<CashSessionController>();
  String _query = '';
  String? _categoryId;
  Map<String, LocalProduct> _products = {};
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _worker = ever(Get.find<SyncService>().lastSync, (_) => _loadProducts());
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final rows = await (_db.select(_db.localProducts)..where((p) => p.boutiqueId.equals(_shop.shopId))).get();
    if (mounted) setState(() => _products = {for (final p in rows) p.id: p});
  }

  void _add(LocalVariant variant) {
    final l10n = AppLocalizations.of(context);
    if (_shop.readOnly) {
      showMessage(l10n.readOnlyBanner, error: true);
      return;
    }
    if (variant.enStock - variant.reserve <= 0 && !_shop.negativeStockAllowed) {
      showMessage(l10n.stockInsufficient, error: true);
      return;
    }
    _cart.addVariant(variant);
  }

  Future<void> _scan() async {
    final l10n = AppLocalizations.of(context);
    final code = await scanBarcode(context);
    if (code == null) return;
    final variant = await _db.variantByBarcode(_shop.shopId, code);
    if (variant == null) {
      showMessage(l10n.scanNotFound, error: true);
    } else {
      _add(variant);
    }
  }

  Future<void> _chooseVariant(List<LocalVariant> variants, String productName) async {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<LocalVariant>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(shrinkWrap: true, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Text(productName, style: Theme.of(context).textTheme.titleMedium)),
        for (final v in variants)
          ListTile(
            leading: v.couleurHex == null ? const Icon(Icons.label_outline) : CircleAvatar(radius: 14, backgroundColor: Color(0xFF000000 | int.parse(v.couleurHex!.substring(1), radix: 16))),
            title: Text(_variantOnlyLabel(v, productName, arabic)),
            subtitle: Text('${l10n.stockInStock}: ${formatQuantity(v.enStock - v.reserve)}', style: TextStyle(color: v.enStock - v.reserve <= 0 ? Theme.of(context).colorScheme.error : null)),
            trailing: Text(formatMoney(v.prixPromo != null ? v.prixPromo! : v.prixVente, currency: _shop.currency, decimals: _shop.decimals), style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pop(context, v),
          ),
      ]),
    );
    if (picked != null) _add(picked);
  }

  /// Libellé de la variante sans le nom du produit (« Rouge - M »).
  String _variantOnlyLabel(LocalVariant v, String productName, bool arabic) {
    final full = arabic ? v.libelleAr : v.libelleFr;
    return full.startsWith(productName) && full.length > productName.length ? full.substring(productName.length).replaceFirst(RegExp(r'^\s*-\s*'), '') : full;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';

    final body = Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          Expanded(child: TextField(onChanged: (v) => setState(() => _query = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.stockSearch, isDense: true))),
          const SizedBox(width: 8),
          IconButton.filledTonal(onPressed: _scan, icon: const Icon(Icons.qr_code_scanner), tooltip: l10n.scan),
          const _SuspendedButton(),
          IconButton(onPressed: () => showCashSessionSheet(context), icon: Obx(() => Icon(_session.sessionId.value == null ? Icons.lock_outline : Icons.lock_open, color: _session.sessionId.value == null ? null : Colors.green)), tooltip: l10n.cashSession),
        ]),
      ),
      SizedBox(
        height: 52,
        child: StreamBuilder<List<LocalCategory>>(
          stream: _db.watchCategories(_shop.shopId),
          builder: (context, snapshot) => ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(l10n.allCategories), selected: _categoryId == null, onSelected: (_) => setState(() => _categoryId = null))),
            for (final c in snapshot.data ?? const <LocalCategory>[])
              Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(localName(c.nomAr, c.nomFr, arabic: arabic)), selected: _categoryId == c.id, onSelected: (_) => setState(() => _categoryId = c.id))),
          ]),
        ),
      ),
      Expanded(
        child: StreamBuilder<List<LocalVariant>>(
          stream: _db.watchVariants(_shop.shopId, query: _query, categoryId: _categoryId),
          builder: (context, snapshot) {
            final variants = snapshot.data ?? const <LocalVariant>[];
            if (variants.isEmpty) return const EmptyState(icon: Icons.search_off);
            final groups = <String, List<LocalVariant>>{};
            for (final v in variants) {
              groups.putIfAbsent(v.produitId, () => []).add(v);
            }
            final entries = groups.entries.toList();
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 170, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.82),
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final vs = entries[i].value;
                final product = _products[entries[i].key];
                final name = product == null ? (arabic ? vs.first.libelleAr : vs.first.libelleFr) : localName(product.nomAr, product.nomFr, arabic: arabic);
                final prices = vs.map((v) => v.prixPromo ?? v.prixVente).toList()..sort();
                final stock = vs.fold(0.0, (s, v) => s + (v.enStock - v.reserve));
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => vs.length == 1 ? _add(vs.first) : _chooseVariant(vs, name),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Expanded(child: vs.first.imageUrl == null ? const ColoredBox(color: Colors.black12, child: Icon(Icons.image_outlined, size: 36)) : Image.network(productImageUrl(vs.first.imageUrl!, width: 300), fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black12, child: Icon(Icons.broken_image_outlined)))),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(formatMoney(prices.first, currency: _shop.currency, decimals: _shop.decimals), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                          Text(vs.length > 1 ? l10n.variantCount(vs.length) : '${l10n.stockInStock}: ${formatQuantity(stock)}', style: TextStyle(fontSize: 11, color: stock <= 0 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.outline)),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
      _CartBar(),
    ]);

    return widget.standalone ? Scaffold(appBar: AppBar(title: Text(l10n.newSale)), body: body) : body;
  }
}

class _CartBar extends StatelessWidget {
  final _cart = Get.find<CartController>();
  final _shop = Get.find<ShopController>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(() {
      _cart.version.value;
      if (_cart.cart.isEmpty) return const SizedBox.shrink();
      return Material(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: SafeArea(
          top: false,
          child: InkWell(
            onTap: () => Get.toNamed(Routes.cart),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                const Icon(Icons.shopping_cart_outlined),
                const SizedBox(width: 8),
                Text(l10n.cartItems(formatQuantity(_cart.cart.itemCount))),
                const Spacer(),
                Text(formatMoney(_cart.cart.total, currency: _shop.currency, decimals: _shop.decimals), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(width: 8),
                Text(l10n.viewCart, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );
    });
  }
}

class _SuspendedButton extends StatelessWidget {
  const _SuspendedButton();

  @override
  Widget build(BuildContext context) {
    final db = Get.find<AppDatabase>();
    final shop = Get.find<ShopController>();
    final cart = Get.find<CartController>();
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<SuspendedSale>>(
      stream: db.watchSuspended(shop.shopId),
      builder: (context, snapshot) {
        final sales = snapshot.data ?? const <SuspendedSale>[];
        return IconButton(
          tooltip: l10n.suspendedSales,
          icon: Badge(isLabelVisible: sales.isNotEmpty, label: Text('${sales.length}'), child: const Icon(Icons.pause_circle_outline)),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (sheetContext) => ListView(shrinkWrap: true, children: [
              if (!cart.cart.isEmpty) ListTile(leading: const Icon(Icons.pause), title: Text(l10n.suspendSale), onTap: () async { Navigator.pop(sheetContext); await cart.suspend(); }),
              if (sales.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(l10n.noSuspended))),
              for (final s in sales)
                ListTile(
                  leading: const Icon(Icons.shopping_cart_checkout),
                  title: Text(s.label?.isNotEmpty == true ? s.label! : l10n.suspendedSales),
                  subtitle: Text(formatDate(s.createdAt, Localizations.localeOf(context), time: true)),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { db.deleteSuspended(s.id); Navigator.pop(sheetContext); }),
                  onTap: () async { Navigator.pop(sheetContext); await cart.resume(s); },
                ),
            ]),
          ),
        );
      },
    );
  }
}
