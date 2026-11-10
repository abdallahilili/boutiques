import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/session/shop_controller.dart';
import '../../core/sync/sync_service.dart';
import '../../core/types/database_types.dart';
import '../../core/util/errors.dart';
import '../../core/util/format.dart';
import '../../core/widgets/common.dart';
import '../../l10n/app_localizations.dart';

/// Charge utile de `enregistrer_depense` (identifiant UUID généré par l'appareil : rejeu sans doublon).
Map<String, dynamic> expensePayload({required String id, required String shopId, required double amount, String? categoryId, String? modeId, String? reason, DateTime? date}) => {
      'id': id,
      'boutique_id': shopId,
      'montant': amount,
      'categorie_id': ?categoryId,
      'mode_paiement_id': ?modeId,
      if (reason != null && reason.trim().isNotEmpty) 'motif': reason.trim(),
      if (date != null) 'date_depense': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    };

/// Dépenses simples (loyer, transport, salaire…) : saisie possible hors ligne (outbox), consultation en ligne.
class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final _client = Get.find<SupabaseClient>();
  final _db = Get.find<AppDatabase>();
  final _shop = Get.find<ShopController>();
  final _sync = Get.find<SyncService>();
  late Future<_ExpenseData> _future = _load();

  String get _categoriesKey => 'expense_categories:${_shop.shopId}';

  Future<List<Map<String, dynamic>>> _categories() async {
    try {
      final rows = await _client.from(Tables.categoriesDepenses).select('id,nom_ar,nom_fr').eq('boutique_id', _shop.shopId).order('nom_fr');
      await _db.setMeta(_categoriesKey, jsonEncode(rows));
      return rows;
    } catch (_) {
      final cached = await _db.meta(_categoriesKey);
      return cached == null ? const [] : [for (final r in jsonDecode(cached) as List) Map<String, dynamic>.from(r as Map)];
    }
  }

  Future<_ExpenseData> _load() async {
    final categories = await _categories();
    List<Map<String, dynamic>> rows = const [];
    try {
      rows = await _client.from(Tables.depenses).select('id,montant,date_depense,motif,categorie_id').eq('boutique_id', _shop.shopId).order('date_depense', ascending: false).limit(100);
    } catch (e) {
      if (!isTransientError(e)) rethrow;
    }
    final pending = [
      for (final item in await _db.pendingItems(_shop.shopId))
        if (item.kind == OutboxKind.expense) jsonDecode(item.payload) as Map<String, dynamic>,
    ];
    return _ExpenseData(categories, rows, pending);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _add(List<Map<String, dynamic>> categories) async {
    final l10n = AppLocalizations.of(context);
    final modes = (await _db.watchPaymentModes(_shop.shopId).first).where((m) => m.type != 'credit' && m.actif).toList();
    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ExpenseSheet(categories: categories, modes: modes),
    );
    if (result == null) return;
    final id = const Uuid().v4();
    await _sync.enqueue(OutboxKind.expense, id, expensePayload(id: id, shopId: _shop.shopId, amount: result['amount'] as double, categoryId: result['category'] as String?, modeId: result['mode'] as String?, reason: result['reason'] as String?, date: result['date'] as DateTime?));
    showMessage(_sync.online.value ? l10n.expenseSaved : l10n.expenseQueued);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) _reload();
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String money(num v) => formatMoney(v, currency: _shop.currency, decimals: _shop.decimals);
    return FutureBuilder<_ExpenseData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        String categoryName(String? id) {
          final c = data?.categories.where((c) => c['id'] == id).firstOrNull;
          return c == null ? '' : localName(c['nom_ar'] as String?, c['nom_fr'] as String?, arabic: arabic);
        }

        return Scaffold(
          appBar: AppBar(title: Text(l10n.menuExpenses)),
          floatingActionButton: _shop.can('depenses.gerer') && !_shop.readOnly && data != null ? FloatingActionButton.extended(onPressed: () => _add(data.categories), icon: const Icon(Icons.add), label: Text(l10n.newExpense)) : null,
          body: data == null
              ? (snapshot.hasError ? ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: _reload) : const Center(child: CircularProgressIndicator()))
              : RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: data.pending.isEmpty && data.rows.isEmpty
                      ? ListView(children: const [SizedBox(height: 120), EmptyState(icon: Icons.payments_outlined)])
                      : ListView(children: [
                          for (final p in data.pending)
                            ListTile(
                              leading: const Icon(Icons.cloud_upload_outlined, color: Colors.orange),
                              title: Text(money(asDouble(p['montant']))),
                              subtitle: Text('${l10n.expensePending}${p['motif'] == null ? '' : ' · ${p['motif']}'}'),
                            ),
                          for (final r in data.rows)
                            ListTile(
                              leading: const Icon(Icons.payments_outlined),
                              title: Text(money(asDouble(r['montant']))),
                              subtitle: Text([categoryName(r['categorie_id'] as String?), if (r['motif'] != null) r['motif'] as String, r['date_depense'] as String].where((s) => s.isNotEmpty).join(' · ')),
                            ),
                        ]),
                ),
        );
      },
    );
  }
}

class _ExpenseData {
  const _ExpenseData(this.categories, this.rows, this.pending);

  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> rows;
  final List<Map<String, dynamic>> pending;
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({required this.categories, required this.modes});

  final List<Map<String, dynamic>> categories;
  final List<LocalPaymentMode> modes;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  String? _category;
  String? _mode;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final amount = parseAmount(_amount.text);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.newExpense, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          NumberField(controller: _amount, label: l10n.amount, min: 0.01, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          if (widget.categories.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(labelText: l10n.expenseCategory),
              items: [for (final c in widget.categories) DropdownMenuItem(value: c['id'] as String, child: Text(localName(c['nom_ar'] as String?, c['nom_fr'] as String?, arabic: arabic)))],
              onChanged: (v) => setState(() => _category = v),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _mode,
            decoration: InputDecoration(labelText: l10n.paymentMode),
            items: [for (final m in widget.modes) DropdownMenuItem(value: m.id, child: Text(localName(m.nomAr, m.nomFr, arabic: arabic)))],
            onChanged: (v) => setState(() => _mode = v),
          ),
          const SizedBox(height: 12),
          TextField(controller: _reason, decoration: InputDecoration(labelText: l10n.expenseReason)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.event_outlined),
            label: Text(formatDate(_date, Localizations.localeOf(context))),
            onPressed: () async {
              final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: amount == null || amount <= 0 ? null : () => Navigator.pop(context, {'amount': amount, 'category': _category, 'mode': _mode, 'reason': _reason.text, 'date': _date}),
            child: Text(l10n.save),
          ),
        ]),
      ),
    );
  }
}
