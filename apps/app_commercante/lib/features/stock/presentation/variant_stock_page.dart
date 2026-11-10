import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/types/database_types.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';

/// Détail d'une variante : lots (FIFO/FEFO) et historique des mouvements (connexion requise).
/// Les coûts d'achat ne sont renseignés par le serveur que pour les rôles autorisés.
class VariantStockPage extends StatefulWidget {
  const VariantStockPage({super.key});

  @override
  State<VariantStockPage> createState() => _VariantStockPageState();
}

class _VariantStockPageState extends State<VariantStockPage> {
  final LocalVariant _variant = Get.arguments as LocalVariant;
  final _shop = Get.find<ShopController>();
  late final Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)> _data = _load();

  Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)> _load() async {
    final client = Get.find<SupabaseClient>();
    final lots = await client.from(Tables.lotsStockVue).select().eq('variante_id', _variant.id).order('recu_le');
    final movements = await client.from(Tables.mouvementsStockVue).select().eq('variante_id', _variant.id).order('cree_le', ascending: false).limit(100);
    return (lots, movements);
  }

  String _movementLabel(AppLocalizations l10n, String type) => switch (type) {
        'entree' => l10n.movement_entree,
        'sortie_vente' => l10n.movement_sortie_vente,
        'sortie_manuelle' => l10n.movement_sortie_manuelle,
        'retour_client' => l10n.movement_retour_client,
        'retour_fournisseur' => l10n.movement_retour_fournisseur,
        'ajustement' => l10n.movement_ajustement,
        'reservation' => l10n.movement_reservation,
        'liberation' => l10n.movement_liberation,
        'transfert_sortie' => l10n.movement_transfert_sortie,
        'transfert_entree' => l10n.movement_transfert_entree,
        _ => type,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String money(Object? v) => formatMoney(asDouble(v), currency: _shop.currency, decimals: _shop.decimals);

    return Scaffold(
      appBar: AppBar(title: Text(arabic ? _variant.libelleAr : _variant.libelleFr)),
      body: FutureBuilder(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!));
          final (lots, movements) = snapshot.data!;
          return ListView(children: [
            ListTile(
              title: Text(l10n.stockInStock),
              trailing: Text(formatQuantity(_variant.enStock), style: Theme.of(context).textTheme.headlineSmall),
              subtitle: Text('${l10n.stockReserved}: ${formatQuantity(_variant.reserve)} · ${l10n.stockAvailable}: ${formatQuantity(_variant.enStock - _variant.reserve)}'),
            ),
            const Divider(),
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Text(l10n.lots, style: Theme.of(context).textTheme.titleMedium)),
            for (final lot in lots.where((l) => asDouble(l['quantite_restante']) != 0))
              ListTile(
                dense: true,
                title: Text(lot['numero_lot'] as String, textDirection: TextDirection.ltr),
                subtitle: Text([
                  l10n.lotRemaining(formatQuantity(asDouble(lot['quantite_restante'])), formatQuantity(asDouble(lot['quantite_initiale']))),
                  if (lot['date_expiration'] != null) l10n.expiresOn(formatDate(DateTime.parse(lot['date_expiration'] as String), Localizations.localeOf(context))),
                ].join(' · ')),
                trailing: lot['cout_unitaire'] == null ? null : Text(l10n.costLabel(money(lot['cout_unitaire']))),
              ),
            const Divider(),
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Text(l10n.stockHistory, style: Theme.of(context).textTheme.titleMedium)),
            for (final m in movements)
              ListTile(
                dense: true,
                title: Text(_movementLabel(l10n, m['type'] as String)),
                subtitle: Text(formatDate(DateTime.parse(m['cree_le'] as String), Localizations.localeOf(context), time: true)),
                trailing: Text('${asDouble(m['quantite']) > 0 ? '+' : ''}${formatQuantity(asDouble(m['quantite']))}', style: TextStyle(fontWeight: FontWeight.bold, color: asDouble(m['quantite']) < 0 ? Colors.red.shade700 : Colors.green.shade700)),
              ),
          ]);
        },
      ),
    );
  }
}
