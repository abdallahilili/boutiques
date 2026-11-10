import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:get/get.dart' hide Value;
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/session/shop_controller.dart';
import 'data/sales_service.dart';
import 'domain/cart.dart';

/// État de la caisse : panier, remises, cliente, ventes suspendues. Le modèle (`Cart`) est du Dart pur, testé à part.
class CartController extends GetxController {
  CartController(this._db, this._shop, this._sales, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final ShopController _shop;
  final SalesService _sales;
  final DateTime Function() _clock;

  final cart = Cart();

  /// Compteur de version : les widgets `Obx` le lisent pour se reconstruire à chaque changement du panier.
  final version = 0.obs;
  final saving = false.obs;

  void _touch() => version.value++;

  bool get canModifyPrice => _shop.can('pos.modifier_prix');
  bool get canDiscount => _shop.can('pos.remise');

  void addVariant(LocalVariant variant) {
    cart.addVariant(variant, _clock());
    _touch();
  }

  void setQuantity(CartLine line, double quantity) {
    if (quantity <= 0) {
      cart.lines.remove(line);
    } else {
      line.quantity = quantity;
    }
    _touch();
  }

  void setPrice(CartLine line, double price) {
    if (!canModifyPrice || price < 0) return;
    line.unitPrice = price;
    _touch();
  }

  /// Remise de ligne en montant ou en pourcentage du brut de la ligne.
  void setLineDiscount(CartLine line, double value, DiscountMode mode) {
    if (!canDiscount) return;
    final raw = mode == DiscountMode.percent ? line.gross * value / 100 : value;
    line.discount = raw.clamp(0, line.gross).toDouble();
    _touch();
  }

  void setGlobalDiscount(double value, DiscountMode mode) {
    if (!canDiscount) return;
    cart
      ..globalDiscountValue = value < 0 ? 0 : value
      ..globalDiscountMode = mode;
    _touch();
  }

  void setCustomer(String? id, String? name) {
    cart
      ..customerId = id
      ..customerName = name;
    _touch();
  }

  void setNote(String? note) {
    cart.note = note;
    _touch();
  }

  void removePayment(PaymentEntry payment) {
    cart.payments.remove(payment);
    _touch();
  }

  /// Ajoute un paiement ; retourne la monnaie à rendre (espèces).
  double addPayment(PaymentEntry entry, {double? tendered}) {
    final change = cart.addPayment(entry, tendered: tendered);
    _touch();
    return change;
  }

  void clear() {
    cart.clear();
    _touch();
  }

  // ------------------------------------------------------------- Ventes suspendues

  Future<void> suspend({String? label}) async {
    if (cart.isEmpty) return;
    await _db.saveSuspended(SuspendedSalesCompanion.insert(id: const Uuid().v4(), boutiqueId: _shop.shopId, label: Value(label ?? cart.customerName), cartJson: jsonEncode(cart.toJson()), createdAt: _clock()));
    clear();
  }

  /// Reprend une vente suspendue : les lignes sont reconstruites depuis le cache local (prix de la vente conservés).
  Future<void> resume(SuspendedSale sale) async {
    final json = jsonDecode(sale.cartJson) as Map<String, dynamic>;
    clear();
    for (final item in (json['lines'] as List).cast<Map<String, dynamic>>()) {
      final variant = await (_db.select(_db.localVariants)..where((v) => v.id.equals(item['variantId'] as String))).getSingleOrNull();
      if (variant == null) continue;
      cart.lines.add(CartLine(variant: variant, unitPrice: (item['price'] as num).toDouble(), quantity: (item['qty'] as num).toDouble(), discount: (item['discount'] as num).toDouble()));
    }
    cart
      ..customerId = json['customerId'] as String?
      ..customerName = json['customerName'] as String?
      ..note = json['note'] as String?
      ..globalDiscountValue = (json['discountValue'] as num).toDouble()
      ..globalDiscountMode = DiscountMode.values.byName(json['discountMode'] as String);
    await _db.deleteSuspended(sale.id);
    _touch();
  }

  // ------------------------------------------------------------------- Encaissement

  Future<SaleReceipt?> checkout({String? sessionId, double change = 0}) async {
    if (cart.isEmpty || saving.value) return null;
    saving.value = true;
    try {
      final receipt = await _sales.record(cart, sessionId: sessionId, change: change, now: _clock());
      clear();
      return receipt;
    } finally {
      saving.value = false;
    }
  }
}
