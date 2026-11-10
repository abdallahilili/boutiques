import 'dart:math' as math;

import '../../../core/db/app_database.dart';

/// Prix effectif d'une variante à un instant donné (même règle que `prive.prix_effectif` côté serveur).
double effectivePrice(LocalVariant v, DateTime now) {
  final promo = v.prixPromo;
  if (promo == null) return v.prixVente;
  final started = v.promoDebut == null || !now.isBefore(v.promoDebut!);
  final notEnded = v.promoFin == null || !now.isAfter(v.promoFin!);
  return started && notEnded ? promo : v.prixVente;
}

double _round(double value, int decimals) {
  final factor = math.pow(10, decimals).toDouble();
  return (value * factor).round() / factor;
}

class CartLine {
  CartLine({required this.variant, required this.unitPrice, this.quantity = 1, this.discount = 0}) : listPrice = unitPrice;

  final LocalVariant variant;
  final double listPrice;
  double unitPrice;
  double quantity;

  /// Remise de ligne en montant (un pourcentage saisi est converti en montant avant d'arriver ici).
  double discount;

  double get gross => _round(unitPrice * quantity, 2);
  double get net => math.max(0, _round(gross - discount, 2));
  bool get priceModified => unitPrice != listPrice;
  bool get exceedsStock => quantity > variant.enStock - variant.reserve;
}

enum DiscountMode { amount, percent }

class PaymentEntry {
  PaymentEntry({required this.modeId, required this.modeType, required this.nameAr, required this.nameFr, required this.amount});

  final String modeId;
  final String modeType;
  final String? nameAr;
  final String? nameFr;
  double amount;
}

/// Panier de caisse : totaux, remises (par ligne et globale), paiements multiples, reste dû et rendu de monnaie.
class Cart {
  final lines = <CartLine>[];
  final payments = <PaymentEntry>[];
  String? customerId;
  String? customerName;
  String? note;
  double globalDiscountValue = 0;
  DiscountMode globalDiscountMode = DiscountMode.amount;

  bool get isEmpty => lines.isEmpty;
  double get itemCount => lines.fold(0.0, (sum, l) => sum + l.quantity);
  double get subtotal => _round(lines.fold(0.0, (sum, l) => sum + l.net), 2);

  double get globalDiscount {
    final raw = globalDiscountMode == DiscountMode.percent ? subtotal * globalDiscountValue / 100 : globalDiscountValue;
    return _round(raw.clamp(0, subtotal).toDouble(), 2);
  }

  double get total => _round(subtotal - globalDiscount, 2);

  /// Les paiements « crédit » ne sont pas encaissés : ils laissent un reste dû (dette cliente).
  double get paid => _round(payments.where((p) => p.modeType != 'credit').fold(0.0, (sum, p) => sum + p.amount), 2);
  double get remaining => _round(math.max(0, total - paid), 2);
  bool get hasDebt => remaining > 0;
  bool get hasDiscount => globalDiscount > 0 || lines.any((l) => l.discount > 0);

  void addVariant(LocalVariant variant, DateTime now) {
    final existing = lines.where((l) => l.variant.id == variant.id).firstOrNull;
    if (existing != null) {
      existing.quantity += 1;
    } else {
      lines.add(CartLine(variant: variant, unitPrice: effectivePrice(variant, now)));
    }
  }

  /// Ajoute un paiement limité au reste dû. Retourne la monnaie à rendre (espèces seulement).
  double addPayment(PaymentEntry entry, {double? tendered}) {
    final applied = math.min(entry.amount, remaining);
    if (applied <= 0) return 0;
    final existing = payments.where((p) => p.modeId == entry.modeId).firstOrNull;
    if (existing != null) {
      existing.amount = _round(existing.amount + applied, 2);
    } else {
      payments.add(PaymentEntry(modeId: entry.modeId, modeType: entry.modeType, nameAr: entry.nameAr, nameFr: entry.nameFr, amount: applied));
    }
    final given = tendered ?? entry.amount;
    return entry.modeType == 'especes' ? _round(math.max(0, given - applied), 2) : 0;
  }

  void clear() {
    lines.clear();
    payments.clear();
    customerId = null;
    customerName = null;
    note = null;
    globalDiscountValue = 0;
    globalDiscountMode = DiscountMode.amount;
  }

  Map<String, dynamic> toJson() => {
        'lines': [for (final l in lines) {'variantId': l.variant.id, 'qty': l.quantity, 'price': l.unitPrice, 'discount': l.discount}],
        'customerId': customerId,
        'customerName': customerName,
        'note': note,
        'discountValue': globalDiscountValue,
        'discountMode': globalDiscountMode.name,
      };
}
