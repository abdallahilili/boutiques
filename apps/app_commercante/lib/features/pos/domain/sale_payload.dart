import 'cart.dart';

/// Corps de la fonction SQL `enregistrer_vente` (idempotente : tous les identifiants viennent de l'appareil).
Map<String, dynamic> buildSalePayload({
  required Cart cart,
  required String saleId,
  required String shopId,
  required String Function() newId,
  String type = 'facture',
  String? number,
  String? deviceId,
  String? sessionId,
}) {
  return {
    'id': saleId,
    'boutique_id': shopId,
    'type': type,
    'canal': 'caisse',
    'client_id': ?cart.customerId,
    'numero': ?number,
    if (number != null && deviceId != null) 'appareil_id': deviceId,
    'session_caisse_id': ?sessionId,
    if (cart.globalDiscount > 0) 'remise': cart.globalDiscount,
    if (cart.note != null && cart.note!.trim().isNotEmpty) 'notes': cart.note!.trim(),
    'lignes': [
      for (final l in cart.lines)
        {
          'id': newId(),
          'variante_id': l.variant.id,
          'quantite': l.quantity,
          'prix_unitaire': l.unitPrice,
          if (l.discount > 0) 'remise': l.discount,
        },
    ],
    'paiements': [
      for (final p in cart.payments)
        if (p.modeType != 'credit') {'id': newId(), 'mode_paiement_id': p.modeId, 'montant': p.amount},
    ],
  };
}
