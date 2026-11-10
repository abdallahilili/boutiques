import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../../core/db/app_database.dart';
import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';

/// Tableau de stock (cache local) : recherche, filtre stock bas, accès aux opérations.
class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final _db = Get.find<AppDatabase>();
  final _shop = Get.find<ShopController>();
  String _query = '';
  bool _lowOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final canWrite = _shop.can('stock.ecrire') && !_shop.readOnly;

    return Scaffold(
      floatingActionButton: canWrite
          ? PopupMenuButton<String>(
              onSelected: (route) => Get.toNamed(route),
              itemBuilder: (_) => [
                PopupMenuItem(value: Routes.stockEntry, child: Text(l10n.stockEntryTitle)),
                PopupMenuItem(value: Routes.stockOut, child: Text(l10n.stockOutTitle)),
                PopupMenuItem(value: Routes.inventory, child: Text(l10n.inventoryTitle)),
              ],
              child: FloatingActionButton.extended(onPressed: null, icon: const Icon(Icons.swap_vert), label: Text(l10n.stockActions)),
            )
          : null,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(children: [
            Expanded(child: TextField(onChanged: (v) => setState(() => _query = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.stockSearch, isDense: true))),
            const SizedBox(width: 8),
            FilterChip(label: Text(l10n.lowStockFilter), selected: _lowOnly, onSelected: (v) => setState(() => _lowOnly = v)),
          ]),
        ),
        Expanded(
          child: StreamBuilder<List<LocalVariant>>(
            stream: _db.watchVariants(_shop.shopId, query: _query, lowStockOnly: _lowOnly),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <LocalVariant>[];
              if (items.isEmpty) return const EmptyState(icon: Icons.warehouse_outlined);
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final v = items[i];
                  final low = v.enStock <= 0 || (v.stockMinimum > 0 && v.enStock <= v.stockMinimum);
                  return ListTile(
                    leading: v.couleurHex == null ? const Icon(Icons.label_outline) : CircleAvatar(radius: 12, backgroundColor: Color(0xFF000000 | int.parse(v.couleurHex!.substring(1), radix: 16))),
                    title: Text(arabic ? v.libelleAr : v.libelleFr),
                    subtitle: Text('${l10n.stockReserved}: ${formatQuantity(v.reserve)}'),
                    trailing: Text(formatQuantity(v.enStock), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: low ? Theme.of(context).colorScheme.error : null)),
                    onTap: () => Get.toNamed(Routes.variantStock, arguments: v),
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
