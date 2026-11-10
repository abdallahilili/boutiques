import 'package:app_commercante/features/catalog/domain/variant_combinations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('modèles × couleurs × tailles : toutes les combinaisons', () {
    final combos = generateCombinations(models: ['m1', 'm2'], colors: ['c1', 'c2', 'c3'], sizes: ['s1']);
    expect(combos.length, 6);
    expect(combos.toSet().length, 6);
    expect(combos.first, const VariantCombo('m1', 'c1', 's1'));
  });

  test('une dimension vide est ignorée', () {
    final combos = generateCombinations(colors: ['noir', 'rouge']);
    expect(combos, [const VariantCombo(null, 'noir', null), const VariantCombo(null, 'rouge', null)]);
  });

  test('aucune dimension : une variante simple', () {
    expect(generateCombinations(), [const VariantCombo(null, null, null)]);
  });

  test('seules les combinaisons manquantes sont créées', () {
    final wanted = generateCombinations(colors: ['a', 'b', 'c']);
    final existing = [const VariantCombo(null, 'b', null)];
    expect(missingCombinations(wanted, existing).map((c) => c.colorId), ['a', 'c']);
  });
}
