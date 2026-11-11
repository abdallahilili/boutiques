import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/shop_controller.dart';
import '../../core/util/errors.dart';
import '../../core/widgets/common.dart';
import '../../l10n/app_localizations.dart';
import '../documents/presentation/documents_pages.dart' show ensureOnline;

/// Tables exportables et libellé de leur fichier (mêmes noms que l'Edge Function `export-data`).
const exportableTables = [
  'produits',
  'variantes_produit',
  'categories',
  'clients',
  'fournisseurs',
  'documents_vente',
  'lignes_document_vente',
  'paiements',
  'receptions_stock',
  'lots_stock',
  'mouvements_stock',
  'depenses',
  'commandes',
  'lignes_commande',
];

/// Fichiers CSV d'un export : `[{nom, contenu}]` extraits de la réponse de l'Edge Function.
List<({String name, Uint8List bytes, int rows, bool truncated})> exportFilesFrom(Map<String, dynamic> response) => [
      for (final f in (response['fichiers'] as List? ?? const []).cast<Map<String, dynamic>>())
        (name: f['nom'] as String, bytes: Uint8List.fromList(utf8.encode(f['contenu'] as String)), rows: (f['lignes'] as num?)?.toInt() ?? 0, truncated: f['tronque'] == true),
    ];

/// Sauvegarde : export des données de la boutique en CSV (ouvrable dans Excel), partagé depuis le téléphone.
/// Réservé à la propriétaire ; limité à 3 exports par heure.
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final _client = Get.find<SupabaseClient>();
  final _shop = Get.find<ShopController>();
  final Set<String> _selected = {...exportableTables};
  bool _busy = false;
  List<({String name, Uint8List bytes, int rows, bool truncated})> _files = const [];

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    if (!ensureOnline(l10n)) return;
    setState(() => _busy = true);
    try {
      final response = await _client.functions.invoke('export-data', body: {'boutique_id': _shop.shopId, 'tables': _selected.toList()});
      final data = Map<String, dynamic>.from(response.data as Map);
      setState(() => _files = exportFilesFrom(data));
      showMessage(l10n.exportReady);
    } on FunctionException catch (e) {
      final details = e.details is Map ? (e.details as Map)['erreur'] : null;
      showMessage(details == 'trop_de_requetes' ? l10n.serverError_trop_de_requetes : friendlyError(l10n, e), error: true);
    } catch (e) {
      showMessage(friendlyError(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    await SharePlus.instance.share(ShareParams(
      files: [for (final f in _files) XFile.fromData(f.bytes, mimeType: 'text/csv', name: f.name)],
      fileNameOverrides: [for (final f in _files) f.name],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportData)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(l10n.exportHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          TextButton(onPressed: () => setState(() => _selected..clear()..addAll(exportableTables)), child: Text(l10n.selectAll)),
          TextButton(onPressed: () => setState(_selected.clear), child: Text(l10n.selectNone)),
        ]),
        for (final t in exportableTables) CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(t, textDirection: TextDirection.ltr), value: _selected.contains(t), onChanged: (v) => setState(() => v == true ? _selected.add(t) : _selected.remove(t))),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _busy || _selected.isEmpty ? null : _export, icon: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download_outlined), label: Text(l10n.exportData)),
        if (_files.isNotEmpty) ...[
          const Divider(height: 32),
          for (final f in _files) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.table_chart_outlined), title: Text(f.name, textDirection: TextDirection.ltr), subtitle: Text('${f.rows}${f.truncated ? ' (${l10n.exportTruncated})' : ''}')),
          OutlinedButton.icon(onPressed: _share, icon: const Icon(Icons.share), label: Text(l10n.shareFiles)),
        ],
      ]),
    );
  }
}
