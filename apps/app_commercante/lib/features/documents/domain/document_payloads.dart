import '../../../core/util/format.dart';

/// Famille de documents affichée dans la liste (onglets).
enum DocumentFamily {
  invoices(['facture', 'ticket']),
  quotes(['devis']),
  deliveries(['bon_livraison']),
  credits(['avoir']);

  const DocumentFamily(this.types);

  final List<String> types;
}

/// Ligne en cours de saisie d'un devis ou d'un bon de livraison.
class DraftLine {
  DraftLine({required this.variantId, required this.labelAr, required this.labelFr, required this.unitPrice, this.quantity = 1, this.discount = 0});

  final String variantId;
  final String labelAr;
  final String labelFr;
  double unitPrice;
  double quantity;
  double discount;

  /// Montant net de la ligne, jamais négatif (le serveur recalcule et arrondit à 2 décimales).
  double get net => (quantity * unitPrice - discount).clamp(0, double.infinity).toDouble();

  Map<String, dynamic> toJson() => {
        'variante_id': variantId,
        'quantite': quantity,
        'prix_unitaire': unitPrice,
        if (discount > 0) 'remise': discount,
      };
}

/// Devis ou bon de livraison en cours de saisie (aucun impact sur le stock avant validation).
class DraftDocument {
  DraftDocument({required this.type, this.customerId, this.validUntil, this.discount = 0, this.notes, List<DraftLine>? lines}) : lines = lines ?? [];

  /// `devis` ou `bon_livraison`.
  final String type;
  String? customerId;
  DateTime? validUntil;
  double discount;
  String? notes;
  final List<DraftLine> lines;

  double get subtotal => lines.fold(0.0, (sum, l) => sum + l.net);
  double get total => (subtotal - discount).clamp(0, double.infinity).toDouble();
  bool get isValid => lines.isNotEmpty && lines.every((l) => l.quantity > 0 && l.unitPrice >= 0) && discount >= 0 && discount <= subtotal;

  /// Ajoute une quantité à la ligne existante de la même variante, sinon crée la ligne.
  void addOrIncrement(DraftLine line) {
    final existing = lines.where((l) => l.variantId == line.variantId).firstOrNull;
    if (existing != null) {
      existing.quantity += line.quantity;
    } else {
      lines.add(line);
    }
  }

  static String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Charge utile de `creer_devis` / `creer_bon_livraison` (identifiant généré par l'appelant : idempotence).
  Map<String, dynamic> toPayload({required String id, required String shopId, bool sent = false}) => {
        'id': id,
        'boutique_id': shopId,
        if (customerId != null) 'client_id': customerId,
        if (type == 'devis' && validUntil != null) 'date_validite': _date(validUntil!),
        if (type == 'devis' && sent) 'statut': 'envoye',
        if (discount > 0) 'remise': discount,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
        'lignes': [for (final l in lines) l.toJson()],
      };
}

/// Ligne d'une facture proposée à l'avoir, avec la quantité encore avoirable.
class CreditableLine {
  CreditableLine({required this.id, required this.labelAr, required this.labelFr, required this.quantity, required this.unitPrice, required this.discount, required this.alreadyCredited});

  final String id;
  final String labelAr;
  final String labelFr;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double alreadyCredited;

  double get remaining => (quantity - alreadyCredited).clamp(0, double.infinity).toDouble();

  /// Montant de l'avoir pour [qty] unités (remise de ligne proportionnelle, comme le serveur).
  double amountFor(double qty) => _round2(qty * unitPrice - (quantity == 0 ? 0 : discount * qty / quantity));
}

double _round2(double v) => (v * 100).roundToDouble() / 100;

/// Calcul prévisionnel d'un avoir : total, imputation sur le reste dû, somme à rembourser ou à créditer.
class CreditNotePlan {
  CreditNotePlan({required this.lines, required this.quantities, required this.invoiceSubtotal, required this.invoiceDiscount, required this.invoiceRemaining});

  final List<CreditableLine> lines;
  final Map<String, double> quantities;
  final double invoiceSubtotal;
  final double invoiceDiscount;
  final double invoiceRemaining;

  double get subtotal => lines.fold(0.0, (sum, l) => sum + l.amountFor(quantities[l.id] ?? 0));
  double get discount => invoiceSubtotal > 0 ? _round2(subtotal * invoiceDiscount / invoiceSubtotal) : 0;
  double get total => _round2(subtotal - discount);

  /// Part imputée sur le reste à payer de la facture.
  double get applied => total < invoiceRemaining ? total : invoiceRemaining;

  /// Somme déjà encaissée à rendre à la cliente (remboursement ou crédit sur son compte).
  double get dueBack => _round2(total - applied);

  bool get isValid => quantities.entries.any((e) => e.value > 0) && lines.every((l) => (quantities[l.id] ?? 0) <= l.remaining + 1e-9);

  Map<String, dynamic> toPayload({required String id, required String invoiceId, required bool returnStock, String? reason, String? sessionId, List<Map<String, dynamic>> refunds = const []}) => {
        'id': id,
        'facture_id': invoiceId,
        'retour_stock': returnStock,
        if (reason != null && reason.trim().isNotEmpty) 'motif': reason.trim(),
        'session_caisse_id': ?sessionId,
        'lignes': [
          for (final l in lines)
            if ((quantities[l.id] ?? 0) > 0) {'ligne_id': l.id, 'quantite': quantities[l.id]},
        ],
        if (refunds.isNotEmpty) 'remboursements': refunds,
      };
}

/// Actions proposées selon le type et le statut du document (les droits sont vérifiés aussi côté serveur).
enum DocumentAction { send, accept, refuse, validate, deliver, convertToDelivery, convertToInvoice, createCredit, cancel }

Set<DocumentAction> availableActions({required String type, required String status, required bool canCreate, required bool canManage, bool alreadyConverted = false}) {
  final actions = <DocumentAction>{};
  switch (type) {
    case 'devis':
      if (canCreate) {
        if (status == 'brouillon') actions.add(DocumentAction.send);
        if (status == 'brouillon' || status == 'envoye') actions.addAll([DocumentAction.accept, DocumentAction.refuse]);
      }
      if (canManage && !alreadyConverted && const {'brouillon', 'envoye', 'accepte'}.contains(status)) {
        actions.addAll([DocumentAction.convertToDelivery, DocumentAction.convertToInvoice]);
      }
      if (canManage && !alreadyConverted && const {'brouillon', 'envoye', 'accepte'}.contains(status)) actions.add(DocumentAction.cancel);
    case 'bon_livraison':
      if (canCreate && status == 'brouillon') actions.add(DocumentAction.validate);
      if (canCreate && status == 'valide') actions.add(DocumentAction.deliver);
      if (canManage && (status == 'valide' || status == 'livre') && !alreadyConverted) actions.add(DocumentAction.convertToInvoice);
      if (canManage && status != 'facture' && status != 'annulee') actions.add(DocumentAction.cancel);
    case 'facture' || 'ticket':
      if (canManage && const {'emise', 'partiellement_payee', 'payee'}.contains(status)) actions.add(DocumentAction.createCredit);
      if (canManage && status == 'emise') actions.add(DocumentAction.cancel);
  }
  return actions;
}

/// Montant arrondi comme le serveur (2 décimales) pour les contrôles d'affichage.
String moneyText(double v, String currency, int? decimals) => formatMoney(v, currency: currency, decimals: decimals);
