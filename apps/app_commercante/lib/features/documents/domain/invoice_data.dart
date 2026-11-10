import '../../../core/util/format.dart';
import '../../pos/domain/cart.dart';

class InvoiceLine {
  const InvoiceLine({required this.labelAr, required this.labelFr, required this.quantity, required this.unitPrice, required this.discount, required this.total});

  final String labelAr;
  final String labelFr;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double total;
}

class InvoicePayment {
  const InvoicePayment({required this.nameAr, required this.nameFr, required this.amount});

  final String? nameAr;
  final String? nameFr;
  final double amount;
}

/// Document de vente reconstitué pour l'affichage et le PDF : en-tête figé à l'émission + lignes + paiements.
/// Aucun PDF n'est stocké : il est généré à la demande depuis ces données.
class InvoiceData {
  const InvoiceData({
    required this.type,
    required this.number,
    required this.date,
    required this.shopNameAr,
    required this.shopNameFr,
    required this.currency,
    required this.lines,
    required this.payments,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.shopAddress,
    this.shopPhone,
    this.customerName,
    this.customerPhone,
    this.footerAr,
    this.footerFr,
    this.notes,
    this.decimals,
  });

  final String type;

  /// Null tant que le numéro n'est pas attribué (vente hors ligne sans plage de numéros).
  final String? number;
  final DateTime date;
  final String? shopNameAr;
  final String? shopNameFr;
  final String? shopAddress;
  final String? shopPhone;
  final String currency;
  final int? decimals;
  final String? customerName;
  final String? customerPhone;
  final String? footerAr;
  final String? footerFr;
  final String? notes;
  final List<InvoiceLine> lines;
  final List<InvoicePayment> payments;
  final double subtotal;
  final double discount;
  final double total;

  double get paid => payments.fold(0.0, (sum, p) => sum + p.amount);
  double get remaining => (total - paid).clamp(0, double.infinity).toDouble();

  /// Document issu d'une vente de caisse (avant ou sans aller-retour serveur).
  factory InvoiceData.fromCart(
    Cart cart, {
    required String? number,
    required DateTime date,
    required Map<String, dynamic> shop,
    required String currency,
    int? decimals,
    String type = 'facture',
  }) =>
      InvoiceData(
        type: type,
        number: number,
        date: date,
        shopNameAr: shop['nom_ar'] as String?,
        shopNameFr: shop['nom_fr'] as String?,
        shopAddress: shop['adresse'] as String?,
        shopPhone: shop['telephone'] as String?,
        footerAr: shop['pied_page_ar'] as String?,
        footerFr: shop['pied_page_fr'] as String?,
        currency: currency,
        decimals: decimals,
        customerName: cart.customerName,
        notes: cart.note,
        lines: [
          for (final l in cart.lines)
            InvoiceLine(labelAr: l.variant.libelleAr, labelFr: l.variant.libelleFr, quantity: l.quantity, unitPrice: l.unitPrice, discount: l.discount, total: l.net),
        ],
        payments: [for (final p in cart.payments) if (p.modeType != 'credit') InvoicePayment(nameAr: p.nameAr, nameFr: p.nameFr, amount: p.amount)],
        subtotal: cart.subtotal,
        discount: cart.globalDiscount,
        total: cart.total,
      );

  /// Document enregistré : `documents_vente` (+ `entete` figé), lignes (vue sans coût) et paiements.
  factory InvoiceData.fromServer({
    required Map<String, dynamic> document,
    required List<Map<String, dynamic>> lines,
    required List<Map<String, dynamic>> payments,
    required Map<String, String?> modeNamesAr,
    required Map<String, String?> modeNamesFr,
  }) {
    final header = (document['entete'] as Map?)?.cast<String, dynamic>() ?? const {};
    final customer = (header['client'] as Map?)?.cast<String, dynamic>();
    return InvoiceData(
      type: document['type'] as String,
      number: document['numero'] as String?,
      date: DateTime.parse(document['date_emission'] as String),
      shopNameAr: header['nom_ar'] as String?,
      shopNameFr: header['nom_fr'] as String?,
      shopAddress: [header['adresse'], header['ville']].whereType<String>().join(', ').isEmpty ? null : [header['adresse'], header['ville']].whereType<String>().join(', '),
      shopPhone: header['telephone'] as String?,
      footerAr: header['pied_page_ar'] as String?,
      footerFr: header['pied_page_fr'] as String?,
      currency: (header['devise'] as String?) ?? 'MRU',
      customerName: customer == null ? null : localName(customer['nom_ar'] as String?, customer['nom_fr'] as String?, arabic: true),
      customerPhone: customer?['telephone'] as String?,
      notes: document['notes'] as String?,
      lines: [
        for (final l in lines)
          InvoiceLine(
            labelAr: (l['libelle_ar'] ?? l['libelle_fr'] ?? '') as String,
            labelFr: (l['libelle_fr'] ?? l['libelle_ar'] ?? '') as String,
            quantity: asDouble(l['quantite']),
            unitPrice: asDouble(l['prix_unitaire']),
            discount: asDouble(l['remise']),
            total: asDouble(l['total']),
          ),
      ],
      payments: [
        for (final p in payments)
          InvoicePayment(nameAr: modeNamesAr[p['mode_paiement_id']], nameFr: modeNamesFr[p['mode_paiement_id']], amount: asDouble(p['montant'])),
      ],
      subtotal: asDouble(document['sous_total']),
      discount: asDouble(document['remise']),
      total: asDouble(document['total']),
    );
  }

  /// Message texte pour WhatsApp (sans pièce jointe) : numéro, total et reste dû.
  String summaryText({required bool arabic}) {
    String money(double v) => formatMoney(v, currency: currency, decimals: decimals);
    final lines = <String>[
      arabic ? 'فاتورة ${number ?? ''}' : 'Facture ${number ?? ''}',
      '${arabic ? 'المجموع' : 'Total'} : ${money(total)}',
      if (remaining > 0) '${arabic ? 'المتبقي' : 'Reste dû'} : ${money(remaining)}',
      localName(shopNameAr, shopNameFr, arabic: arabic),
    ];
    return lines.join('\n');
  }
}
