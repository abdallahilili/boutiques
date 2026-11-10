import '../../../core/util/format.dart';

/// Période prédéfinie ou personnalisée d'un rapport (dates locales de la boutique, bornes incluses).
enum ReportPeriodKind { today, week, month, custom }

class ReportPeriod {
  const ReportPeriod(this.kind, this.start, this.end);

  /// Calcule la période à partir de [now] ; `week` = 7 jours glissants, `month` = depuis le 1er du mois.
  factory ReportPeriod.of(ReportPeriodKind kind, DateTime now, {DateTime? customStart, DateTime? customEnd}) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (kind) {
      ReportPeriodKind.today => ReportPeriod(kind, today, today),
      ReportPeriodKind.week => ReportPeriod(kind, today.subtract(const Duration(days: 6)), today),
      ReportPeriodKind.month => ReportPeriod(kind, DateTime(now.year, now.month, 1), today),
      ReportPeriodKind.custom => ReportPeriod(kind, customStart ?? today, customEnd ?? customStart ?? today),
    };
  }

  final ReportPeriodKind kind;
  final DateTime start;
  final DateTime end;

  static String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get startParam => _date(start);
  String get endParam => _date(end);

  /// Paramètres communs des RPC de rapport.
  Map<String, dynamic> params(String shopId) => {'p_boutique': shopId, 'p_debut': startParam, 'p_fin': endParam};
}

/// Axes du rapport de ventes (valeurs acceptées par `rapport_ventes`).
enum SalesAxis { jour, produit, categorie, vendeuse, modePaiement, canal }

extension SalesAxisValue on SalesAxis {
  String get value => switch (this) {
        SalesAxis.modePaiement => 'mode_paiement',
        _ => name,
      };
}

/// Ligne d'un rapport (ventes par axe, meilleurs produits, dormants, stock).
class ReportRow {
  const ReportRow({required this.key, required this.labelAr, required this.labelFr, this.count, this.quantity, this.revenue, this.margin, this.value, this.lastSale});

  factory ReportRow.fromJson(Map<String, dynamic> json) => ReportRow(
        key: '${json['cle'] ?? json['variante_id'] ?? ''}',
        labelAr: (json['libelle_ar'] ?? json['libelle_fr'] ?? '') as String,
        labelFr: (json['libelle_fr'] ?? json['libelle_ar'] ?? '') as String,
        count: json['nb'] == null ? null : (json['nb'] as num).toInt(),
        quantity: json['quantite'] == null ? (json['en_stock'] == null ? null : asDouble(json['en_stock'])) : asDouble(json['quantite']),
        revenue: json['ca'] == null ? null : asDouble(json['ca']),
        margin: json['marge'] == null ? null : asDouble(json['marge']),
        value: json['valeur'] == null ? null : asDouble(json['valeur']),
        lastSale: json['derniere_vente'] == null ? null : DateTime.tryParse('${json['derniere_vente']}'),
      );

  final String key;
  final String labelAr;
  final String labelFr;
  final int? count;
  final double? quantity;
  final double? revenue;
  final double? margin;
  final double? value;
  final DateTime? lastSale;
}

/// Synthèse financière d'une période (les marges sont absentes sans la permission « couts.voir »).
class ReportSummary {
  const ReportSummary({required this.revenue, required this.salesCount, required this.collected, required this.expenses, required this.unpaidCustomers, required this.supplierDebts, this.margin, this.result, this.stockValue});

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        revenue: asDouble(json['chiffre_affaires']),
        salesCount: (json['nb_ventes'] as num?)?.toInt() ?? 0,
        collected: asDouble(json['encaisse']),
        expenses: asDouble(json['depenses']),
        unpaidCustomers: asDouble(json['impayes_clients']),
        supplierDebts: asDouble(json['dettes_fournisseurs']),
        margin: json['marge_brute'] == null ? null : asDouble(json['marge_brute']),
        result: json['resultat'] == null ? null : asDouble(json['resultat']),
        stockValue: json['valeur_stock'] == null ? null : asDouble(json['valeur_stock']),
      );

  final double revenue;
  final int salesCount;
  final double collected;
  final double expenses;
  final double unpaidCustomers;
  final double supplierDebts;
  final double? margin;
  final double? result;
  final double? stockValue;
}

/// Échappe une cellule CSV (séparateur « ; », guillemets doublés) et neutralise les formules Excel.
String csvCell(Object? value) {
  if (value == null) return '';
  var text = '$value';
  if (value is! num && RegExp(r'^[=+\-@\t\r]').hasMatch(text)) text = "'$text";
  return RegExp(r'[";\n\r]').hasMatch(text) ? '"${text.replaceAll('"', '""')}"' : text;
}

/// CSV compatible Excel (UTF-8 avec BOM, fins de ligne CRLF).
String toCsv(List<String> headers, List<List<Object?>> rows) => '﻿${[headers.map(csvCell).join(';'), for (final r in rows) r.map(csvCell).join(';')].join('\r\n')}\r\n';
