import 'package:flutter/material.dart';

/// Icônes proposées pour une catégorie sans image (`categories.icone`). Les clés doivent rester identiques à
/// celles de la boutique en ligne (`app_boutique/src/lib/icones.ts`), qui les affiche en emoji.
const categoryIcons = <String, IconData>{
  'robe': Icons.checkroom,
  'vetements': Icons.dry_cleaning,
  'chaussures': Icons.directions_walk,
  'sac': Icons.shopping_bag,
  'bijoux': Icons.diamond,
  'parfum': Icons.spa,
  'beaute': Icons.face_retouching_natural,
  'montre': Icons.watch,
  'enfants': Icons.child_care,
  'bebe': Icons.child_friendly,
  'maison': Icons.home,
  'meubles': Icons.chair,
  'cuisine': Icons.restaurant,
  'alimentation': Icons.shopping_basket,
  'fruits': Icons.eco,
  'boissons': Icons.local_drink,
  'boulangerie': Icons.bakery_dining,
  'viande': Icons.set_meal,
  'electronique': Icons.smartphone,
  'ordinateur': Icons.laptop,
  'sport': Icons.sports_soccer,
  'livres': Icons.menu_book,
  'papeterie': Icons.edit,
  'outils': Icons.build,
  'jardin': Icons.yard,
  'auto': Icons.directions_car,
  'sante': Icons.medication,
  'cadeaux': Icons.card_giftcard,
  'tissus': Icons.content_cut,
  'animaux': Icons.pets,
  'nettoyage': Icons.cleaning_services,
  'autre': Icons.category,
};

/// Icône d'une clé de catégorie, ou null si la clé est absente ou inconnue.
IconData? categoryIconFor(String? key) => key == null ? null : categoryIcons[key];
