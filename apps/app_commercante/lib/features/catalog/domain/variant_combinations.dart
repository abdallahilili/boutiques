/// Combinaison modèle × couleur × taille d'une variante (null = dimension non utilisée).
class VariantCombo {
  const VariantCombo(this.modelId, this.colorId, this.sizeId);

  final String? modelId;
  final String? colorId;
  final String? sizeId;

  @override
  bool operator ==(Object other) => other is VariantCombo && other.modelId == modelId && other.colorId == colorId && other.sizeId == sizeId;

  @override
  int get hashCode => Object.hash(modelId, colorId, sizeId);
}

/// Produit cartésien des dimensions choisies. Une dimension vide est ignorée ; aucune dimension
/// choisie donne l'unique variante « simple » (null, null, null).
List<VariantCombo> generateCombinations({
  Iterable<String> models = const [],
  Iterable<String> colors = const [],
  Iterable<String> sizes = const [],
}) {
  final m = models.isEmpty ? <String?>[null] : models.toList();
  final c = colors.isEmpty ? <String?>[null] : colors.toList();
  final s = sizes.isEmpty ? <String?>[null] : sizes.toList();
  return [for (final a in m) for (final b in c) for (final d in s) VariantCombo(a, b, d)];
}

/// Combinaisons à créer : celles qui n'existent pas déjà pour le produit.
List<VariantCombo> missingCombinations(List<VariantCombo> wanted, Iterable<VariantCombo> existing) {
  final have = existing.toSet();
  return wanted.where((c) => !have.contains(c)).toList();
}
