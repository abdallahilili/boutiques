import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/env.dart';
import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import 'products_controller.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _controller = Get.put(ProductsController(Get.find(), Get.find(), Get.find()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shop = Get.find<ShopController>();
    final arabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      floatingActionButton: Obx(() => shop.can('produits.ecrire') && !shop.readOnly ? FloatingActionButton(onPressed: () => Get.toNamed(Routes.productForm), child: const Icon(Icons.add)) : const SizedBox.shrink()),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            onChanged: (v) => _controller.query.value = v,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.searchProducts, isDense: true),
          ),
        ),
        SizedBox(
          height: 52,
          child: Obx(() => ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                Padding(padding: const EdgeInsets.only(right: 8, left: 0), child: FilterChip(label: Text(l10n.lowStockFilter), selected: _controller.lowStockOnly.value, onSelected: (v) => _controller.lowStockOnly.value = v)),
                Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(l10n.allCategories), selected: _controller.categoryId.value == null, onSelected: (_) => _controller.categoryId.value = null)),
                for (final c in _controller.categories)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(label: Text(localName(c.nomAr, c.nomFr, arabic: arabic)), selected: _controller.categoryId.value == c.id, onSelected: (_) => _controller.categoryId.value = c.id),
                  ),
              ])),
        ),
        Expanded(
          child: Obx(() {
            final items = _controller.items;
            if (items.isEmpty) return EmptyState(message: l10n.noProducts, icon: Icons.inventory_2_outlined);
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = items[i];
                final p = s.product;
                final price = s.minPrice == s.maxPrice
                    ? formatMoney(s.minPrice, currency: shop.currency, decimals: shop.decimals)
                    : l10n.priceFrom(formatMoney(s.minPrice, currency: shop.currency, decimals: shop.decimals));
                return ListTile(
                  leading: _Thumb(url: p.imageUrl, shopId: shop.shopId),
                  title: Text(localName(p.nomAr, p.nomFr, arabic: arabic)),
                  subtitle: Text('$price · ${l10n.variantCount(s.variantCount)}'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(l10n.stockCount(formatQuantity(s.totalStock)), style: TextStyle(color: s.lowStock ? Theme.of(context).colorScheme.error : null, fontWeight: FontWeight.w600)),
                    if (p.statut != 'actif') Text(l10n.inactive, style: Theme.of(context).textTheme.labelSmall),
                  ]),
                  onTap: () => Get.toNamed(Routes.productForm, arguments: p.id),
                );
              },
            );
          }),
        ),
      ]),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.shopId});

  final String? url;
  final String shopId;

  @override
  Widget build(BuildContext context) {
    final image = url == null ? null : productImageUrl(url!, width: 120);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(width: 48, height: 48, child: image == null ? const ColoredBox(color: Colors.black12, child: Icon(Icons.image_outlined)) : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined))),
    );
  }
}

/// URL publique transformée (WebP, redimensionnée) d'une image du bucket product-images.
String productImageUrl(String path, {int width = 400}) {
  if (path.startsWith('http')) return path;
  return '${Env.supabaseUrl}/storage/v1/render/image/public/product-images/$path?width=$width&quality=75&format=webp';
}
