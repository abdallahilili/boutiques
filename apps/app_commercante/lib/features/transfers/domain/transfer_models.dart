import '../../../core/util/format.dart';

/// Désignation de la boutique destinataire : un code boutique (6 caractères) ou un numéro de téléphone.
Map<String, String> recipientFromInput(String input) {
  final text = input.trim();
  final digits = text.replaceAll(RegExp(r'[\s+\-]'), '');
  if (RegExp(r'^\d{8,15}$').hasMatch(digits)) return {'telephone': digits};
  return {'code_boutique': text.toUpperCase()};
}

/// Ligne en cours de saisie d'un transfert sortant.
class TransferDraftLine {
  TransferDraftLine({required this.variantId, required this.labelAr, required this.labelFr, required this.available, required this.price, this.quantity = 1});

  final String variantId;
  final String labelAr;
  final String labelFr;

  /// Stock disponible chez l'émettrice (information locale ; le serveur reste l'arbitre).
  final double available;
  double price;
  double quantity;

  double get total => quantity * price;
  Map<String, dynamic> toJson() => {'variante_id': variantId, 'quantite': quantity, 'prix_unitaire': price};
}

class TransferDraft {
  TransferDraft({this.recipient = '', this.note, List<TransferDraftLine>? lines}) : lines = lines ?? [];

  String recipient;
  String? note;
  final List<TransferDraftLine> lines;

  double get total => lines.fold(0.0, (sum, l) => sum + l.total);
  bool get isValid => recipient.trim().length >= 6 && lines.isNotEmpty && lines.every((l) => l.quantity > 0 && l.price >= 0);

  void addOrIncrement(TransferDraftLine line) {
    final existing = lines.where((l) => l.variantId == line.variantId).firstOrNull;
    if (existing != null) {
      existing.quantity += line.quantity;
    } else {
      lines.add(line);
    }
  }

  /// Charge utile d'`envoyer_transfert` (identifiant UUID généré par l'appelant : idempotence).
  Map<String, dynamic> toPayload({required String id, required String shopId}) => {
        'id': id,
        'boutique_id': shopId,
        'destinataire': recipientFromInput(recipient),
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
        'lignes': [for (final l in lines) l.toJson()],
      };
}

/// Correspondance d'une ligne reçue avec le catalogue de la destinataire : produit existant ou création.
class LineMapping {
  LineMapping({required this.lineId, this.variantId, this.create = true, this.salePrice});

  final String lineId;
  String? variantId;
  bool create;
  double? salePrice;

  bool get isComplete => create ? (salePrice != null && salePrice! >= 0) : variantId != null;

  Map<String, dynamic> toJson() => {
        'ligne_id': lineId,
        if (create) 'creer': true else 'variante_id': variantId,
        'prix_vente': ?salePrice,
      };
}

/// Charge utile de `repondre_transfert` ; l'acceptation exige une correspondance complète de chaque ligne.
Map<String, dynamic> buildTransferResponse({required String transferId, required bool accept, List<LineMapping> mappings = const []}) {
  if (accept && (mappings.isEmpty || mappings.any((m) => !m.isComplete))) {
    throw ArgumentError('Chaque ligne doit être associée à un produit ou créée avec un prix de vente');
  }
  return {
    'transfert_id': transferId,
    'decision': accept ? 'accepter' : 'refuser',
    if (accept) 'correspondances': [for (final m in mappings) m.toJson()],
  };
}

/// Transfert tel que renvoyé par `liste_transferts` / `detail_transfert`.
class TransferSummary {
  const TransferSummary({required this.id, required this.number, required this.status, required this.total, required this.createdAt, required this.sent, required this.otherAr, required this.otherFr});

  factory TransferSummary.fromJson(Map<String, dynamic> json) {
    final other = (json['autre_boutique'] as Map?)?.cast<String, dynamic>() ?? const {};
    return TransferSummary(
      id: json['id'] as String,
      number: json['numero'] as String,
      status: json['statut'] as String,
      total: asDouble(json['total']),
      createdAt: DateTime.parse(json['cree_le'] as String),
      sent: json['sens'] == 'envoye',
      otherAr: other['nom_ar'] as String?,
      otherFr: other['nom_fr'] as String?,
    );
  }

  final String id;
  final String number;
  final String status;
  final double total;
  final DateTime createdAt;
  final bool sent;
  final String? otherAr;
  final String? otherFr;

  bool get pending => status == 'en_attente';
}
