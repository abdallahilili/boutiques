import 'package:app_commercante/features/home/home_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rôle financier : montants lus (nombres ou chaînes)', () {
    final stats = DashboardStats.fromJson({
      'ca_jour': 12500, 'ca_semaine': '40000.00', 'ca_mois': 90000.5, 'impayes': 3000,
      'nb_ventes_jour': 7, 'ruptures': 2, 'sous_seuil': 4, 'commandes_a_traiter': 1,
    });
    expect(stats.hasFinancials, isTrue);
    expect(stats.revenueToday, 12500);
    expect(stats.revenueWeek, 40000);
    expect(stats.salesToday, 7);
    expect(stats.ordersToProcess, 1);
  });

  test('vendeuse : montants financiers absents, compteurs conservés', () {
    final stats = DashboardStats.fromJson({
      'ca_jour': null, 'ca_semaine': null, 'ca_mois': null, 'impayes': null,
      'nb_ventes_jour': 3, 'ruptures': 0, 'sous_seuil': 1, 'commandes_a_traiter': 2,
    });
    expect(stats.hasFinancials, isFalse);
    expect(stats.unpaid, isNull);
    expect(stats.salesToday, 3);
    expect(stats.lowStock, 1);
  });
}
