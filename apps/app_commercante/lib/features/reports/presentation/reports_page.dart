import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/session/shop_controller.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../../documents/data/invoice_pdf.dart' show loadPdfTheme;
import '../data/reports_service.dart';
import '../domain/report_models.dart';

enum _Section { byDay, byProduct, byCategory, bySeller, byPayment, byChannel, best, dormant, stockValue, unpaid }

/// Rapports : synthèse de la période puis détail par axe. Export CSV (Excel) et PDF à la demande.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _service = ReportsService(Get.find<SupabaseClient>());
  final _shop = Get.find<ShopController>();
  ReportPeriod _period = ReportPeriod.of(ReportPeriodKind.month, DateTime.now());
  _Section _section = _Section.byDay;
  late Future<_ReportData> _future = _load();

  Future<_ReportData> _load() async {
    final id = _shop.shopId;
    final summary = await _service.summary(id, _period);
    switch (_section) {
      case _Section.byDay:
        return _ReportData(summary, rows: await _service.sales(id, _period, SalesAxis.jour));
      case _Section.byProduct:
        return _ReportData(summary, rows: await _service.sales(id, _period, SalesAxis.produit));
      case _Section.byCategory:
        return _ReportData(summary, rows: await _service.sales(id, _period, SalesAxis.categorie));
      case _Section.bySeller:
        return _ReportData(summary, rows: await _service.sales(id, _period, SalesAxis.vendeuse));
      case _Section.byPayment:
        return _ReportData(summary, rows: await _service.sales(id, _period, SalesAxis.modePaiement));
      case _Section.byChannel:
        return _ReportData(summary, rows: await _service.sales(id, _period, SalesAxis.canal));
      case _Section.best:
        return _ReportData(summary, rows: await _service.products(id, _period, dormant: false));
      case _Section.dormant:
        return _ReportData(summary, rows: await _service.products(id, _period, dormant: true));
      case _Section.stockValue:
        final stock = await _service.stock(id);
        return _ReportData(summary, rows: stock.rows, stockTotal: stock.total);
      case _Section.unpaid:
        return _ReportData(summary, unpaid: await _service.unpaid(id));
    }
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _pickPeriod(ReportPeriodKind kind) async {
    if (kind == ReportPeriodKind.custom) {
      final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)), initialDateRange: DateTimeRange(start: _period.start, end: _period.end));
      if (picked == null) return;
      _period = ReportPeriod.of(kind, DateTime.now(), customStart: picked.start, customEnd: picked.end);
    } else {
      _period = ReportPeriod.of(kind, DateTime.now());
    }
    _reload();
  }

  String _sectionLabel(AppLocalizations l10n, _Section s) => switch (s) {
        _Section.byDay => l10n.reportByDay,
        _Section.byProduct => l10n.reportByProduct,
        _Section.byCategory => l10n.reportByCategory,
        _Section.bySeller => l10n.reportBySeller,
        _Section.byPayment => l10n.reportByPayment,
        _Section.byChannel => l10n.reportByChannel,
        _Section.best => l10n.reportBest,
        _Section.dormant => l10n.reportDormant,
        _Section.stockValue => l10n.reportStockValue,
        _Section.unpaid => l10n.reportUnpaid,
      };

  String _rowLabel(AppLocalizations l10n, ReportRow row, bool arabic) {
    if (_section == _Section.byChannel) {
      return switch (row.key) {
        'caisse' => l10n.channelCashier,
        'site_web' => l10n.channelWeb,
        'whatsapp' => l10n.channelWhatsapp,
        'instagram' => l10n.channelInstagram,
        'facebook' => l10n.channelFacebook,
        'telephone' => l10n.channelPhone,
        _ => l10n.channelOther,
      };
    }
    return localName(row.labelAr, row.labelFr, arabic: arabic);
  }

  /// Tableau exportable de la section courante : en-têtes + lignes de texte.
  ({List<String> headers, List<List<String>> rows}) _table(AppLocalizations l10n, _ReportData data, bool arabic) {
    String money(double? v) => v == null ? '' : formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);
    if (_section == _Section.unpaid) {
      final customers = (data.unpaid?['clients'] as List? ?? const []).cast<Map<String, dynamic>>();
      final suppliers = (data.unpaid?['fournisseurs'] as List? ?? const []).cast<Map<String, dynamic>>();
      return (
        headers: [l10n.nameFr, l10n.total],
        rows: [
          for (final c in customers) [localName(c['nom_ar'] as String?, c['nom_fr'] as String?, arabic: arabic), money(asDouble(c['solde']))],
          for (final s in suppliers) ['${l10n.suppliersOwed}: ${localName(s['nom_ar'] as String?, s['nom_fr'] as String?, arabic: arabic)}', money(asDouble(s['solde']))],
        ],
      );
    }
    final dormant = _section == _Section.dormant;
    final stock = _section == _Section.stockValue;
    final headers = dormant || stock ? [l10n.nameFr, l10n.colQuantity, l10n.colValue] : [l10n.nameFr, l10n.colSales, l10n.colQuantity, l10n.revenue, l10n.colMargin];
    return (
      headers: headers,
      rows: [
        for (final r in data.rows)
          dormant || stock
              ? [_rowLabel(l10n, r, arabic), r.quantity == null ? '' : formatQuantity(r.quantity!), money(r.value)]
              : [_rowLabel(l10n, r, arabic), '${r.count ?? ''}', r.quantity == null ? '' : formatQuantity(r.quantity!), money(r.revenue), money(r.margin)],
      ],
    );
  }

  Future<void> _shareCsv(AppLocalizations l10n, _ReportData data, bool arabic) async {
    final table = _table(l10n, data, arabic);
    final bytes = Uint8List.fromList(utf8.encode(toCsv(table.headers, table.rows)));
    await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, mimeType: 'text/csv', name: 'rapport.csv')], fileNameOverrides: ['rapport.csv']));
  }

  Future<void> _sharePdf(AppLocalizations l10n, _ReportData data, bool arabic) async {
    final table = _table(l10n, data, arabic);
    final s = data.summary;
    String money(double? v) => v == null ? '—' : formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);
    final doc = pw.Document(theme: await loadPdfTheme());
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      build: (_) => [
        pw.Text('${l10n.menuReports} — ${_sectionLabel(l10n, _section)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text('${_period.startParam} → ${_period.endParam}'),
        pw.SizedBox(height: 10),
        pw.Wrap(spacing: 18, runSpacing: 4, children: [
          pw.Text('${l10n.revenue}: ${money(s.revenue)}'),
          pw.Text('${l10n.grossMargin}: ${money(s.margin)}'),
          pw.Text('${l10n.expensesTotal}: ${money(s.expenses)}'),
          pw.Text('${l10n.netResult}: ${money(s.result)}'),
        ]),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(headers: table.headers, data: table.rows, cellAlignment: pw.Alignment.centerLeft, headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold), headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200)),
      ],
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'rapport.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String money(double? v) => v == null ? '—' : formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);
    final periodLabels = {ReportPeriodKind.today: l10n.periodToday, ReportPeriodKind.week: l10n.periodWeek, ReportPeriodKind.month: l10n.periodMonth, ReportPeriodKind.custom: l10n.periodCustom};

    Widget metric(String label, String value, {Color? color}) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.labelMedium), const SizedBox(height: 4), Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color))]),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuReports)),
      body: FutureBuilder<_ReportData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(padding: const EdgeInsets.all(12), children: [
              Wrap(spacing: 8, children: [for (final k in ReportPeriodKind.values) ChoiceChip(label: Text(periodLabels[k]!), selected: _period.kind == k, onSelected: (_) => _pickPeriod(k))]),
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${_period.startParam} → ${_period.endParam}', style: Theme.of(context).textTheme.bodySmall, textDirection: TextDirection.ltr)),
              if (snapshot.connectionState != ConnectionState.done) const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
              if (snapshot.hasError) ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: _reload),
              if (data != null) ...[
                GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 2.2, mainAxisSpacing: 8, crossAxisSpacing: 8, children: [
                  metric(l10n.revenue, money(data.summary.revenue)),
                  metric(l10n.salesCount, '${data.summary.salesCount}'),
                  metric(l10n.grossMargin, money(data.summary.margin)),
                  metric(l10n.expensesTotal, money(data.summary.expenses)),
                  metric(l10n.netResult, money(data.summary.result), color: (data.summary.result ?? 0) < 0 ? Colors.red : null),
                  metric(l10n.cashCollected, money(data.summary.collected)),
                  metric(l10n.stockValue, money(data.summary.stockValue)),
                  metric(l10n.unpaidCustomers, money(data.summary.unpaidCustomers)),
                  metric(l10n.supplierDebts, money(data.summary.supplierDebts)),
                ]),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [for (final s in _Section.values) Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(_sectionLabel(l10n, s)), selected: _section == s, onSelected: (_) { _section = s; _reload(); }))]),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  OutlinedButton.icon(onPressed: () => _shareCsv(l10n, data, arabic), icon: const Icon(Icons.table_chart_outlined), label: Text(l10n.exportCsv)),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(onPressed: () => _sharePdf(l10n, data, arabic), icon: const Icon(Icons.picture_as_pdf_outlined), label: Text(l10n.exportPdf)),
                ]),
                const SizedBox(height: 8),
                if (_section == _Section.unpaid) ..._unpaidSection(l10n, data, arabic, money) else ..._rowsSection(l10n, data, arabic, money),
              ],
            ]),
          );
        },
      ),
    );
  }

  List<Widget> _rowsSection(AppLocalizations l10n, _ReportData data, bool arabic, String Function(double?) money) {
    if (data.rows.isEmpty) return const [EmptyState(icon: Icons.bar_chart)];
    final dormant = _section == _Section.dormant;
    final stock = _section == _Section.stockValue;
    return [
      if (stock && data.stockTotal != null) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${l10n.stockValue}: ${money(data.stockTotal)}', style: Theme.of(context).textTheme.titleMedium)),
      for (final r in data.rows)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(_rowLabel(l10n, r, arabic)),
          subtitle: Text([
            if (r.count != null) '${l10n.colSales}: ${r.count}',
            if (r.quantity != null) '${l10n.colQuantity}: ${formatQuantity(r.quantity!)}',
            if (r.margin != null) '${l10n.colMargin}: ${money(r.margin)}',
            if (dormant && r.lastSale != null) '${l10n.colLastSale}: ${formatDate(r.lastSale!, Localizations.localeOf(context))}',
          ].join(' · ')),
          trailing: Text(money(dormant || stock ? r.value : r.revenue), style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
    ];
  }

  List<Widget> _unpaidSection(AppLocalizations l10n, _ReportData data, bool arabic, String Function(double?) money) {
    final customers = (data.unpaid?['clients'] as List? ?? const []).cast<Map<String, dynamic>>();
    final suppliers = (data.unpaid?['fournisseurs'] as List? ?? const []).cast<Map<String, dynamic>>();
    return [
      Text(l10n.customersOwing, style: Theme.of(context).textTheme.titleSmall),
      if (customers.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('—')),
      for (final c in customers)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(localName(c['nom_ar'] as String?, c['nom_fr'] as String?, arabic: arabic)),
          subtitle: c['plus_ancienne'] == null ? null : Text(l10n.oldestDue('${c['plus_ancienne']}')),
          trailing: Text(money(asDouble(c['solde'])), style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.error)),
        ),
      const SizedBox(height: 8),
      Text(l10n.suppliersOwed, style: Theme.of(context).textTheme.titleSmall),
      if (suppliers.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('—')),
      for (final s in suppliers) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(localName(s['nom_ar'] as String?, s['nom_fr'] as String?, arabic: arabic)), trailing: Text(money(asDouble(s['solde'])), style: const TextStyle(fontWeight: FontWeight.w600))),
    ];
  }
}

class _ReportData {
  const _ReportData(this.summary, {this.rows = const [], this.stockTotal, this.unpaid});

  final ReportSummary summary;
  final List<ReportRow> rows;
  final double? stockTotal;
  final Map<String, dynamic>? unpaid;
}
