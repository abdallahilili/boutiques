import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/sync/sync_service.dart';
import '../../documents/domain/invoice_data.dart';
import '../domain/cart.dart';
import '../domain/sale_payload.dart';

class SaleReceipt {
  const SaleReceipt({required this.saleId, required this.number, required this.invoice, required this.change});

  final String saleId;

  /// Numéro pris dans la plage réservée de l'appareil ; null : le serveur l'attribuera à la synchronisation.
  final String? number;
  final InvoiceData invoice;
  final double change;
}

/// Enregistre une vente : numéro de la plage de l'appareil, file d'attente (outbox), stock local décrémenté.
/// La vente est donc possible hors ligne et envoyée de façon idempotente (UUID d'appareil).
class SalesService {
  SalesService(this._db, this._shop, this._sync);

  final AppDatabase _db;
  final ShopController _shop;
  final SyncService _sync;

  Future<SaleReceipt> record(Cart cart, {String? sessionId, double change = 0, DateTime? now}) async {
    final date = now ?? DateTime.now();
    final saleId = const Uuid().v4();
    final number = await _db.takeNextNumber(_shop.shopId, OutboxKindDocument.invoice, date.year);
    final payload = buildSalePayload(
      cart: cart,
      saleId: saleId,
      shopId: _shop.shopId,
      newId: () => const Uuid().v4(),
      number: number,
      deviceId: _shop.deviceId,
      sessionId: sessionId,
    );

    final shop = _shop.active.value!;
    final settings = shop.parametres is Map ? (shop.parametres as Map).cast<String, dynamic>() : const <String, dynamic>{};
    final invoice = InvoiceData.fromCart(
      cart,
      number: number,
      date: date,
      currency: shop.devise,
      decimals: _shop.decimals,
      shop: {'nom_ar': shop.nomAr, 'nom_fr': shop.nomFr, 'adresse': shop.adresse, 'telephone': shop.telephone, 'pied_page_ar': settings['pied_page_ar'], 'pied_page_fr': settings['pied_page_fr']},
    );

    await _sync.enqueue(OutboxKind.sale, saleId, payload);
    for (final line in cart.lines) {
      await _db.adjustLocalStock(line.variant.id, -line.quantity);
    }
    return SaleReceipt(saleId: saleId, number: number, invoice: invoice, change: change);
  }
}
