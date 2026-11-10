import 'package:app_commercante/core/util/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localName : langue demandée puis repli', () {
    expect(localName('حقيبة', 'Sac', arabic: true), 'حقيبة');
    expect(localName(null, 'Sac', arabic: true), 'Sac');
    expect(localName('  ', null, arabic: false), '—');
  });

  test('formatMoney : MRU sans décimales, autres devises avec 2 décimales', () {
    expect(formatMoney(12500, currency: 'MRU'), '12,500 MRU');
    expect(formatMoney(12.5, currency: 'EUR'), '12.50 EUR');
    expect(formatMoney(1234.5, currency: 'MRU', decimals: 1), '1,234.5 MRU');
  });

  test('formatQuantity', () {
    expect(formatQuantity(3), '3');
    expect(formatQuantity(2.5), '2.5');
  });

  test('parseAmount : virgule, point et chiffres arabo-indiens', () {
    expect(parseAmount('1250'), 1250);
    expect(parseAmount('12,5'), 12.5);
    expect(parseAmount('١٢٥٠'), 1250);
    expect(parseAmount('abc'), isNull);
  });

  test('asDouble accepte les nombres et les chaînes', () {
    expect(asDouble(3), 3.0);
    expect(asDouble('4.5'), 4.5);
    expect(asDouble(null, 7), 7);
  });
}
