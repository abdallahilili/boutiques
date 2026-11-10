import 'package:app_commercante/features/orders/orders_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('transitions de statut d\'une commande', () {
    test('propriétaire / manager : toutes les suites valides', () {
      expect(nextStatuses('nouvelle', canManage: true, canPrepare: false), ['confirmee', 'annulee']);
      expect(nextStatuses('prete', canManage: true, canPrepare: false), ['expediee', 'livree', 'annulee']);
    });

    test('magasinière : uniquement préparation et « prête »', () {
      expect(nextStatuses('confirmee', canManage: false, canPrepare: true), ['en_preparation']);
      expect(nextStatuses('en_preparation', canManage: false, canPrepare: true), ['prete']);
      expect(nextStatuses('nouvelle', canManage: false, canPrepare: true), isEmpty);
    });

    test('statuts terminaux : aucune suite', () {
      for (final s in ['livree', 'annulee', 'retournee']) {
        expect(nextStatuses(s, canManage: true, canPrepare: true), isEmpty);
      }
    });

    test('sans droit : aucune action', () {
      expect(nextStatuses('nouvelle', canManage: false, canPrepare: false), isEmpty);
    });
  });
}
