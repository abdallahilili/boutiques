import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/types/database_types.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/site_models.dart';
import 'site_pages.dart';

String sectionTypeLabel(AppLocalizations l10n, String type) => switch (type) {
      'banniere' => l10n.sectionBanner,
      'categories_vedettes' => l10n.sectionFeaturedCategories,
      'nouveautes' => l10n.sectionNew,
      'promotions' => l10n.sectionPromotions,
      'produits_populaires' => l10n.sectionPopular,
      'a_propos' => l10n.sectionAbout,
      'contact' => l10n.sectionContact,
      _ => type,
    };

/// Sections de la page d'accueil : ordre par glisser-déposer, affichage, titre et texte.
class SiteSectionsPage extends StatefulWidget {
  const SiteSectionsPage({super.key});

  @override
  State<SiteSectionsPage> createState() => _SiteSectionsPageState();
}

class _SiteSectionsPageState extends State<SiteSectionsPage> {
  final _service = siteService();
  final _shop = Get.find<ShopController>();
  late Future<List<Map<String, dynamic>>> _future = _service.rows(Tables.sectionsSite);

  void _reload() => setState(() => _future = _service.rows(Tables.sectionsSite));

  Future<void> _edit(Map<String, dynamic> section) async {
    final l10n = AppLocalizations.of(context);
    final titleAr = TextEditingController(text: section['titre_ar'] as String? ?? '');
    final titleFr = TextEditingController(text: section['titre_fr'] as String? ?? '');
    final contentAr = TextEditingController(text: section['contenu_ar'] as String? ?? '');
    final contentFr = TextEditingController(text: section['contenu_fr'] as String? ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sectionTypeLabel(l10n, section['type'] as String)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleAr, textDirection: TextDirection.rtl, decoration: InputDecoration(labelText: l10n.sectionTitleAr)),
          const SizedBox(height: 8),
          TextField(controller: titleFr, decoration: InputDecoration(labelText: l10n.sectionTitleFr)),
          if (const {'a_propos', 'contact', 'banniere'}.contains(section['type'])) ...[
            const SizedBox(height: 8),
            TextField(controller: contentAr, textDirection: TextDirection.rtl, maxLines: 3, decoration: InputDecoration(labelText: l10n.contentAr)),
            const SizedBox(height: 8),
            TextField(controller: contentFr, maxLines: 3, decoration: InputDecoration(labelText: l10n.contentFr)),
          ],
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save))],
      ),
    );
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final values = {'titre_ar': text(titleAr), 'titre_fr': text(titleFr), 'contenu_ar': text(contentAr), 'contenu_fr': text(contentFr)};
    for (final c in [titleAr, titleFr, contentAr, contentFr]) {
      c.dispose();
    }
    if (ok != true || !mounted) return;
    if (await runSiteAction(context, () => _service.update(Tables.sectionsSite, section['id'] as String, values), success: l10n.saved)) _reload();
  }

  Future<void> _add(List<Map<String, dynamic>> sections) async {
    final l10n = AppLocalizations.of(context);
    final used = {for (final s in sections) s['type'] as String};
    final available = [for (final t in siteSectionTypes) if (!used.contains(t)) t];
    if (available.isEmpty) return;
    final type = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(shrinkWrap: true, children: [for (final t in available) ListTile(title: Text(sectionTypeLabel(l10n, t)), onTap: () => Navigator.pop(context, t))]),
    );
    if (type == null || !mounted) return;
    if (await runSiteAction(context, () async => _service.insert(Tables.sectionsSite, {'type': type, 'ordre': sections.length}))) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = _shop.can('site.gerer') && !_shop.readOnly;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        final sections = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.siteSections)),
          floatingActionButton: canEdit && sections != null ? FloatingActionButton.extended(onPressed: () => _add(sections), icon: const Icon(Icons.add), label: Text(l10n.addSection)) : null,
          body: sections == null
              ? (snapshot.hasError ? ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: _reload) : const Center(child: CircularProgressIndicator()))
              : Column(children: [
                  Padding(padding: const EdgeInsets.all(8), child: Text(l10n.reorderHint, style: Theme.of(context).textTheme.bodySmall)),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: sections.length,
                      onReorderItem: !canEdit ? (_, _) {} : (oldIndex, newIndex) async {
                        final ids = [for (final s in sections) s['id'] as String];
                        if (await runSiteAction(context, () => _service.saveOrder(Tables.sectionsSite, orderUpdates(ids, reordered(ids, oldIndex, newIndex))))) _reload();
                      },
                      itemBuilder: (_, i) {
                        final s = sections[i];
                        return ListTile(
                          key: ValueKey(s['id']),
                          leading: const Icon(Icons.drag_handle),
                          title: Text(sectionTypeLabel(l10n, s['type'] as String)),
                          subtitle: Text(localName(s['titre_ar'] as String?, s['titre_fr'] as String?, arabic: Localizations.localeOf(context).languageCode == 'ar')),
                          onTap: canEdit ? () => _edit(s) : null,
                          trailing: canEdit
                              ? Row(mainAxisSize: MainAxisSize.min, children: [
                                  Switch(value: s['visible'] as bool, onChanged: (v) async { if (await runSiteAction(context, () => _service.update(Tables.sectionsSite, s['id'] as String, {'visible': v}))) _reload(); }),
                                  IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { if (await confirmDialog(context, title: l10n.delete) && context.mounted && await runSiteAction(context, () => _service.delete(Tables.sectionsSite, s['id'] as String))) _reload(); }),
                                ])
                              : null,
                        );
                      },
                    ),
                  ),
                ]),
        );
      },
    );
  }
}

/// Pages statiques (à propos, livraison, retours, conditions…) : création, modification, affichage.
class SitePagesPage extends StatefulWidget {
  const SitePagesPage({super.key});

  @override
  State<SitePagesPage> createState() => _SitePagesPageState();
}

class _SitePagesPageState extends State<SitePagesPage> {
  final _service = siteService();
  final _shop = Get.find<ShopController>();
  late Future<List<Map<String, dynamic>>> _future = _service.rows(Tables.pagesSite);

  void _reload() => setState(() => _future = _service.rows(Tables.pagesSite));

  Future<void> _edit({Map<String, dynamic>? page}) async {
    final l10n = AppLocalizations.of(context);
    final slug = TextEditingController(text: page?['slug'] as String? ?? '');
    final titleAr = TextEditingController(text: page?['titre_ar'] as String? ?? '');
    final titleFr = TextEditingController(text: page?['titre_fr'] as String? ?? '');
    final contentAr = TextEditingController(text: page?['contenu_ar'] as String? ?? '');
    final contentFr = TextEditingController(text: page?['contenu_fr'] as String? ?? '');
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(page == null ? l10n.addPage : l10n.edit),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: slug, enabled: page == null, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l10n.pageSlug, errorText: error)),
            const SizedBox(height: 8),
            TextField(controller: titleAr, textDirection: TextDirection.rtl, decoration: InputDecoration(labelText: l10n.sectionTitleAr)),
            const SizedBox(height: 8),
            TextField(controller: titleFr, decoration: InputDecoration(labelText: l10n.sectionTitleFr)),
            const SizedBox(height: 8),
            TextField(controller: contentAr, textDirection: TextDirection.rtl, maxLines: 5, decoration: InputDecoration(labelText: l10n.contentAr)),
            const SizedBox(height: 8),
            TextField(controller: contentFr, maxLines: 5, decoration: InputDecoration(labelText: l10n.contentFr)),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () {
                if (!isValidPageSlug(slug.text.trim())) {
                  setLocal(() => error = l10n.pageSlugInvalid);
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final values = {'slug': slug.text.trim(), 'titre_ar': text(titleAr), 'titre_fr': text(titleFr), 'contenu_ar': text(contentAr), 'contenu_fr': text(contentFr)};
    for (final c in [slug, titleAr, titleFr, contentAr, contentFr]) {
      c.dispose();
    }
    if (saved != true || !mounted) return;
    final ok = await runSiteAction(context, () async {
      if (page == null) {
        await _service.insert(Tables.pagesSite, values);
      } else {
        await _service.update(Tables.pagesSite, page['id'] as String, {...values}..remove('slug'));
      }
    }, success: l10n.saved);
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = _shop.can('site.gerer') && !_shop.readOnly;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sitePages)),
      floatingActionButton: canEdit ? FloatingActionButton.extended(onPressed: _edit, icon: const Icon(Icons.add), label: Text(l10n.addPage)) : null,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: _reload);
          final pages = snapshot.data!;
          if (pages.isEmpty) return const EmptyState(icon: Icons.article_outlined);
          return ListView(children: [
            for (final p in pages)
              ListTile(
                title: Text(localName(p['titre_ar'] as String?, p['titre_fr'] as String?, arabic: arabic)),
                subtitle: Text('/${p['slug']}', textDirection: TextDirection.ltr),
                onTap: canEdit ? () => _edit(page: p) : null,
                trailing: canEdit
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        Switch(value: p['visible'] as bool, onChanged: (v) async { if (await runSiteAction(context, () => _service.update(Tables.pagesSite, p['id'] as String, {'visible': v}))) _reload(); }),
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { if (await confirmDialog(context, title: l10n.delete) && context.mounted && await runSiteAction(context, () => _service.delete(Tables.pagesSite, p['id'] as String))) _reload(); }),
                      ])
                    : null,
              ),
          ]);
        },
      ),
    );
  }
}

/// Paramètres de vente : modes de livraison et de paiement, commande minimale, messages, zones de livraison.
class SiteSalesPage extends StatefulWidget {
  const SiteSalesPage({super.key});

  @override
  State<SiteSalesPage> createState() => _SiteSalesPageState();
}

class _SiteSalesPageState extends State<SiteSalesPage> {
  final _service = siteService();
  final _shop = Get.find<ShopController>();
  final _minimum = TextEditingController();
  final _confirmFr = TextEditingController();
  final _confirmAr = TextEditingController();
  final _payFr = TextEditingController();
  final _payAr = TextEditingController();
  final Map<String, bool> _flags = {};
  late Future<(Map<String, dynamic>, List<Map<String, dynamic>>)> _future = _load();

  static const _flagKeys = ['livraison_active', 'retrait_boutique_actif', 'paiement_livraison_actif', 'mobile_money_actif', 'afficher_stock', 'masquer_epuises'];

  Future<(Map<String, dynamic>, List<Map<String, dynamic>>)> _load() async {
    final s = await _service.settings();
    for (final k in _flagKeys) {
      _flags[k] = s[k] as bool? ?? false;
    }
    _minimum.text = formatQuantity(asDouble(s['commande_minimale']));
    _confirmFr.text = s['message_confirmation_fr'] as String? ?? '';
    _confirmAr.text = s['message_confirmation_ar'] as String? ?? '';
    final pay = (s['infos_paiement'] as Map?)?.cast<String, dynamic>() ?? const {};
    _payFr.text = pay['instructions_fr'] as String? ?? '';
    _payAr.text = pay['instructions_ar'] as String? ?? '';
    return (s, await _service.rows(Tables.zonesLivraison));
  }

  @override
  void dispose() {
    for (final c in [_minimum, _confirmFr, _confirmAr, _payFr, _payAr]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    await runSiteAction(context, () => _service.updateSettings({
          ..._flags,
          'commande_minimale': parseAmount(_minimum.text) ?? 0,
          'message_confirmation_fr': text(_confirmFr),
          'message_confirmation_ar': text(_confirmAr),
          'infos_paiement': {'instructions_fr': ?text(_payFr), 'instructions_ar': ?text(_payAr)},
        }), success: l10n.saved);
  }

  Future<void> _zone({Map<String, dynamic>? zone}) async {
    final l10n = AppLocalizations.of(context);
    final ar = TextEditingController(text: zone?['nom_ar'] as String? ?? '');
    final fr = TextEditingController(text: zone?['nom_fr'] as String? ?? '');
    final fee = TextEditingController(text: zone == null ? '0' : formatQuantity(asDouble(zone['frais'])));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(zone == null ? l10n.addZone : l10n.edit),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ar, textDirection: TextDirection.rtl, decoration: InputDecoration(labelText: l10n.nameAr)),
          const SizedBox(height: 8),
          TextField(controller: fr, decoration: InputDecoration(labelText: l10n.nameFr)),
          const SizedBox(height: 8),
          NumberField(controller: fee, label: l10n.zoneFee, min: 0),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save))],
      ),
    );
    final values = {'nom_ar': ar.text.trim().isEmpty ? null : ar.text.trim(), 'nom_fr': fr.text.trim().isEmpty ? null : fr.text.trim(), 'frais': parseAmount(fee.text) ?? 0};
    ar.dispose();
    fr.dispose();
    fee.dispose();
    if (ok != true || !mounted || (values['nom_ar'] == null && values['nom_fr'] == null)) return;
    final saved = await runSiteAction(context, () async {
      if (zone == null) {
        await _service.insert(Tables.zonesLivraison, values);
      } else {
        await _service.update(Tables.zonesLivraison, zone['id'] as String, values);
      }
    }, success: l10n.saved);
    if (saved) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = _shop.can('site.gerer') && !_shop.readOnly;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final labels = {
      'livraison_active': l10n.deliveryEnabled,
      'retrait_boutique_actif': l10n.pickupEnabled,
      'paiement_livraison_actif': l10n.cashOnDelivery,
      'mobile_money_actif': l10n.mobileMoneyEnabled,
      'afficher_stock': l10n.showStockOnline,
      'masquer_epuises': l10n.hideSoldOut,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.siteSales)),
      body: FutureBuilder<(Map<String, dynamic>, List<Map<String, dynamic>>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: () => setState(() => _future = _load()));
          final zones = snapshot.data!.$2;
          return ListView(padding: const EdgeInsets.all(16), children: [
            for (final k in _flagKeys) SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(labels[k]!), value: _flags[k] ?? false, onChanged: canEdit ? (v) => setState(() => _flags[k] = v) : null),
            const SizedBox(height: 8),
            NumberField(controller: _minimum, label: l10n.minimumOrder, min: 0, required: false),
            const SizedBox(height: 12),
            TextField(controller: _payAr, enabled: canEdit, textDirection: TextDirection.rtl, maxLines: 2, decoration: InputDecoration(labelText: l10n.paymentInstructionsAr)),
            const SizedBox(height: 12),
            TextField(controller: _payFr, enabled: canEdit, maxLines: 2, decoration: InputDecoration(labelText: l10n.paymentInstructionsFr)),
            const SizedBox(height: 12),
            TextField(controller: _confirmAr, enabled: canEdit, textDirection: TextDirection.rtl, maxLines: 2, decoration: InputDecoration(labelText: l10n.confirmationMessageAr)),
            const SizedBox(height: 12),
            TextField(controller: _confirmFr, enabled: canEdit, maxLines: 2, decoration: InputDecoration(labelText: l10n.confirmationMessageFr)),
            const SizedBox(height: 12),
            if (canEdit) FilledButton(onPressed: _save, child: Text(l10n.save)),
            const Divider(height: 32),
            Row(children: [Expanded(child: Text(l10n.deliveryZones, style: Theme.of(context).textTheme.titleMedium)), if (canEdit) TextButton.icon(onPressed: _zone, icon: const Icon(Icons.add), label: Text(l10n.addZone))]),
            for (final z in zones)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(localName(z['nom_ar'] as String?, z['nom_fr'] as String?, arabic: arabic)),
                subtitle: Text(formatMoney(asDouble(z['frais']), currency: _shop.currency, decimals: _shop.decimals)),
                onTap: canEdit ? () => _zone(zone: z) : null,
                trailing: canEdit ? IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { if (await confirmDialog(context, title: l10n.delete) && context.mounted && await runSiteAction(context, () => _service.delete(Tables.zonesLivraison, z['id'] as String))) setState(() => _future = _load()); }) : null,
              ),
          ]);
        },
      ),
    );
  }
}

/// Catalogue en ligne : ordre des catégories (écran des référentiels), produits visibles ou masqués,
/// épinglage en tête de page avec ordre des produits épinglés.
class SiteCatalogPage extends StatefulWidget {
  const SiteCatalogPage({super.key});

  @override
  State<SiteCatalogPage> createState() => _SiteCatalogPageState();
}

class _SiteCatalogPageState extends State<SiteCatalogPage> {
  final _service = siteService();
  final _shop = Get.find<ShopController>();
  late Future<List<Map<String, dynamic>>> _future = _service.products();

  void _reload() => setState(() => _future = _service.products());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = _shop.can('site.gerer') && !_shop.readOnly;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.siteCatalog)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: _reload);
          final products = snapshot.data!;
          final pinned = [for (final p in products) if (p['epingle'] == true) p]..sort((a, b) => ((a['ordre_epinglage'] as int?) ?? 9999).compareTo((b['ordre_epinglage'] as int?) ?? 9999));
          final others = [for (final p in products) if (p['epingle'] != true) p];
          String name(Map<String, dynamic> p) => localName(p['nom_ar'] as String?, p['nom_fr'] as String?, arabic: arabic);
          return ListView(children: [
            ListTile(leading: const Icon(Icons.category_outlined), title: Text(l10n.categoriesOrder), trailing: const Icon(Icons.chevron_right), onTap: () => Get.toNamed<void>(Routes.referentials)),
            const Divider(),
            if (pinned.isNotEmpty) ...[
              Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Text(l10n.pinnedFirst, style: Theme.of(context).textTheme.titleMedium)),
              Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), child: Text(l10n.pinnedOrderHint, style: Theme.of(context).textTheme.bodySmall)),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorderItem: !canEdit ? (_, _) {} : (oldIndex, newIndex) async {
                  final ids = [for (final p in pinned) p['id'] as String];
                  final after = reordered(ids, oldIndex, newIndex);
                  final ok = await runSiteAction(context, () async {
                    for (var i = 0; i < after.length; i++) {
                      await _service.setProductOnline(after[i], pinned: true, pinOrder: i + 1);
                    }
                  });
                  if (ok) _reload();
                },
                children: [
                  for (final p in pinned)
                    ListTile(
                      key: ValueKey('pin-${p['id']}'),
                      leading: const Icon(Icons.drag_handle),
                      title: Text(name(p)),
                      trailing: canEdit ? IconButton(icon: const Icon(Icons.push_pin), tooltip: l10n.pinnedFirst, onPressed: () async { if (await runSiteAction(context, () => _service.setProductOnline(p['id'] as String, pinned: false))) _reload(); }) : null,
                    ),
                ],
              ),
              const Divider(),
            ],
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Text(l10n.productsOnline, style: Theme.of(context).textTheme.titleMedium)),
            for (final p in others)
              ListTile(
                title: Text(name(p)),
                subtitle: p['statut'] == 'actif' ? null : Text('${p['statut']}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (canEdit) IconButton(icon: const Icon(Icons.push_pin_outlined), tooltip: l10n.pinnedFirst, onPressed: () async { if (await runSiteAction(context, () => _service.setProductOnline(p['id'] as String, pinned: true, pinOrder: pinned.length + 1))) _reload(); }),
                  Switch(value: p['visible_en_ligne'] as bool, onChanged: canEdit ? (v) async { if (await runSiteAction(context, () => _service.setProductOnline(p['id'] as String, visible: v))) _reload(); } : null),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}
