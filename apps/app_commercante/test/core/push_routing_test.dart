import 'package:app_commercante/core/push/push_service.dart';
import 'package:app_commercante/core/routing/app_pages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nouvelle commande et changement de statut : liste des commandes', () {
    expect(routeForPush({'type': 'commande'}).route, Routes.orders);
    expect(routeForPush({'type': 'commande_statut'}).route, Routes.orders);
  });

  test('transfert : détail si l\'identifiant est fourni, sinon liste', () {
    final detail = routeForPush({'type': 'transfert', 'transfert_id': 't-1'});
    expect((detail.route, detail.arguments), (Routes.transferDetail, 't-1'));
    expect(routeForPush({'type': 'transfert'}).route, Routes.transfers);
  });

  test('écart de stock, impayés, abonnement', () {
    expect(routeForPush({'type': 'ecart_stock'}).route, Routes.sync);
    expect(routeForPush({'type': 'impaye_echu'}).route, Routes.customers);
    expect(routeForPush({'type': 'abonnement'}).route, Routes.settings);
  });

  test('type inconnu ou absent : notifications', () {
    expect(routeForPush({'type': 'annonce'}).route, Routes.notifications);
    expect(routeForPush(const {}).route, Routes.notifications);
  });
}
