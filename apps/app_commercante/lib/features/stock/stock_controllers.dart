import 'package:get/get.dart' hide Value;
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/session/shop_controller.dart';
import '../../core/sync/sync_service.dart';

class StockLine {
  StockLine(this.variant, {this.quantity = 1, this.unitCost = 0, this.expiry, this.salePrice});

  final LocalVariant variant;
  double quantity;
  double unitCost;
  DateTime? expiry;
  double? salePrice;
}

String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Corps de `recevoir_stock` (UUID générés côté appareil : l'envoi peut être rejoué sans doublon).
Map<String, dynamic> buildReceptionPayload({
  required String id,
  required String shopId,
  required List<StockLine> lines,
  String? supplierId,
  String? reference,
  double amountPaid = 0,
  String Function() newId = _newId,
}) =>
    {
      'id': id,
      'boutique_id': shopId,
      'fournisseur_id': ?supplierId,
      if (reference != null && reference.trim().isNotEmpty) 'reference': reference.trim(),
      if (amountPaid > 0) 'montant_paye': amountPaid,
      'lignes': [
        for (final l in lines)
          {
            'id': newId(),
            'variante_id': l.variant.id,
            'quantite': l.quantity,
            'cout_unitaire': l.unitCost,
            if (l.expiry != null) 'date_expiration': _date(l.expiry!),
            if (l.salePrice != null) 'prix_vente': l.salePrice,
          },
      ],
    };

String _newId() => const Uuid().v4();

/// Corps de `ajuster_stock` : sortie manuelle (quantité à retirer) ou inventaire (quantité comptée).
Map<String, dynamic> buildAdjustmentPayload({
  required String id,
  required String shopId,
  required String type,
  required List<StockLine> lines,
  String? reasonId,
  String? note,
  String Function() newId = _newId,
}) =>
    {
      'id': id,
      'boutique_id': shopId,
      'type': type,
      'motif_id': ?reasonId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      'lignes': [
        for (final l in lines)
          {
            'id': newId(),
            'variante_id': l.variant.id,
            if (type == 'inventaire') 'quantite_comptee': l.quantity else 'quantite': l.quantity,
          },
      ],
    };

/// Entrée de stock (achat / réception) : peut être saisie hors ligne puis envoyée par l'outbox.
class StockEntryController extends GetxController {
  StockEntryController(this._db, this._shop, this._sync);

  final AppDatabase _db;
  final ShopController _shop;
  final SyncService _sync;

  final lines = <StockLine>[].obs;
  final supplierId = RxnString();
  final reference = ''.obs;
  final amountPaid = 0.0.obs;
  final saving = false.obs;

  double get total => lines.fold(0.0, (sum, l) => sum + l.quantity * l.unitCost);

  void addVariant(LocalVariant variant) {
    final existing = lines.firstWhereOrNull((l) => l.variant.id == variant.id);
    if (existing != null) {
      existing.quantity += 1;
      lines.refresh();
    } else {
      lines.add(StockLine(variant));
    }
  }

  void removeAt(int index) => lines.removeAt(index);

  bool get isValid => lines.isNotEmpty && lines.every((l) => l.quantity > 0 && l.unitCost >= 0) && amountPaid.value <= total;

  Future<void> submit() async {
    if (!isValid || saving.value) return;
    saving.value = true;
    try {
      final id = const Uuid().v4();
      final payload = buildReceptionPayload(
        id: id,
        shopId: _shop.shopId,
        lines: lines.toList(),
        supplierId: supplierId.value,
        reference: reference.value,
        amountPaid: amountPaid.value,
      );
      await _sync.enqueue(OutboxKind.stockReceipt, id, payload);
      for (final l in lines) {
        await _db.adjustLocalStock(l.variant.id, l.quantity);
      }
      lines.clear();
    } finally {
      saving.value = false;
    }
  }
}

/// Sortie manuelle (motif obligatoire) ou inventaire (quantités comptées).
class StockAdjustController extends GetxController {
  StockAdjustController(this._db, this._shop, this._sync, {required this.inventory});

  final AppDatabase _db;
  final ShopController _shop;
  final SyncService _sync;
  final bool inventory;

  final lines = <StockLine>[].obs;
  final reasonId = RxnString();
  final note = ''.obs;
  final saving = false.obs;

  void addVariant(LocalVariant variant) {
    if (lines.any((l) => l.variant.id == variant.id)) return;
    lines.add(StockLine(variant, quantity: inventory ? variant.enStock : 1));
  }

  bool get isValid =>
      lines.isNotEmpty &&
      (inventory || reasonId.value != null) &&
      lines.every((l) => inventory ? l.quantity >= 0 : l.quantity > 0 && l.quantity <= l.variant.enStock || _shop.negativeStockAllowed);

  Future<void> submit() async {
    if (!isValid || saving.value) return;
    saving.value = true;
    try {
      final id = const Uuid().v4();
      final payload = buildAdjustmentPayload(
        id: id,
        shopId: _shop.shopId,
        type: inventory ? 'inventaire' : 'sortie_manuelle',
        lines: lines.toList(),
        reasonId: reasonId.value,
        note: note.value,
      );
      await _sync.enqueue(OutboxKind.stockAdjustment, id, payload);
      for (final l in lines) {
        await _db.adjustLocalStock(l.variant.id, inventory ? l.quantity - l.variant.enStock : -l.quantity);
      }
      lines.clear();
    } finally {
      saving.value = false;
    }
  }
}
