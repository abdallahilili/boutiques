import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../session/shop_controller.dart';
import '../util/storage_urls.dart';

/// Logo de la boutique active en pastille ronde (icône de boutique tant qu'aucun logo n'est choisi).
class ShopLogoAvatar extends StatelessWidget {
  const ShopLogoAvatar({super.key, this.radius = 28});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final shop = Get.find<ShopController>();
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final path = shop.active.value?.logoUrl;
      final fallback = Icon(Icons.storefront_outlined, size: radius, color: scheme.onPrimaryContainer);
      return CircleAvatar(
        radius: radius,
        backgroundColor: scheme.primaryContainer,
        child: path == null || path.isEmpty
            ? fallback
            : ClipOval(
                child: Image.network(
                  shopAssetUrl(path),
                  key: ValueKey(path),
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  cacheWidth: (radius * 4).round(),
                  errorBuilder: (_, _, _) => fallback,
                ),
              ),
      );
    });
  }
}
