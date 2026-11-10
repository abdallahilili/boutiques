import 'package:app_commercante/features/customers/customers_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('répartition d\'un règlement client', () {
    final unpaid = [
      (documentId: 'f1', remaining: 500.0),
      (documentId: 'f2', remaining: 1000.0),
      (documentId: 'f3', remaining: 300.0),
    ];

    test('solde d\'abord la facture la plus ancienne', () {
      expect(allocatePayment(400, unpaid), [(documentId: 'f1', amount: 400.0)]);
    });

    test('déborde sur les factures suivantes', () {
      expect(allocatePayment(1200, unpaid), [(documentId: 'f1', amount: 500.0), (documentId: 'f2', amount: 700.0)]);
    });

    test('un règlement supérieur à la dette n\'affecte que les factures dues', () {
      final result = allocatePayment(5000, unpaid);
      expect(result.fold<double>(0, (s, a) => s + a.amount), 1800);
      expect(result.length, 3);
    });

    test('montant nul ou aucune facture : rien à répartir', () {
      expect(allocatePayment(0, unpaid), isEmpty);
      expect(allocatePayment(100, const []), isEmpty);
    });
  });
}
