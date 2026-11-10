import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/routing/app_pages.dart';
import '../../../core/session/shop_controller.dart';
import '../../../core/types/database_types.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/util/storage_urls.dart';
import '../../../core/widgets/color_picker.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/shop_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../documents/presentation/documents_pages.dart' show ensureOnline;
import '../data/site_service.dart';
import '../domain/site_models.dart';

SiteService siteService() => SiteService(Get.find<SupabaseClient>(), Get.find<ShopController>().shopId);

/// Exécute une écriture de gestion du site : connexion requise, message d'erreur lisible, jamais d'exception brute.
Future<bool> runSiteAction(BuildContext context, Future<void> Function() action, {String? success}) async {
  final l10n = AppLocalizations.of(context);
  if (!ensureOnline(l10n)) return false;
  try {
    await action();
    if (success != null) showMessage(success);
    return true;
  } catch (e) {
    showMessage(friendlyError(l10n, e), error: true);
    return false;
  }
}

/// Accueil de la gestion de la boutique en ligne (permission « site.gerer » pour modifier).
class SitePage extends StatelessWidget {
  const SitePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget item(IconData icon, String label, String route) => ListTile(leading: Icon(icon), title: Text(label), trailing: const Icon(Icons.chevron_right), onTap: () => Get.toNamed<void>(route));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuSite)),
      body: ListView(children: [
        item(Icons.language, l10n.siteGeneral, Routes.siteGeneral),
        item(Icons.palette_outlined, l10n.siteAppearance, Routes.siteAppearance),
        item(Icons.view_carousel_outlined, l10n.siteBanners, Routes.siteBanners),
        item(Icons.view_agenda_outlined, l10n.siteSections, Routes.siteSections),
        item(Icons.article_outlined, l10n.sitePages, Routes.sitePages),
        item(Icons.local_shipping_outlined, l10n.siteSales, Routes.siteSales),
        item(Icons.push_pin_outlined, l10n.siteCatalog, Routes.siteCatalog),
      ]),
    );
  }
}

String domainStatusLabel(AppLocalizations l10n, String? status) => switch (status) {
      'verifie' => l10n.domainVerified,
      'en_attente' => l10n.domainPending,
      'erreur' => l10n.domainError,
      _ => l10n.domainNotConfigured,
    };

/// Publication, sous-domaine (lecture seule), domaine personnalisé (instructions DNS et vérification), contact.
class SiteGeneralPage extends StatefulWidget {
  const SiteGeneralPage({super.key});

  @override
  State<SiteGeneralPage> createState() => _SiteGeneralPageState();
}

class _SiteGeneralPageState extends State<SiteGeneralPage> {
  final _service = siteService();
  final _shop = Get.find<ShopController>();
  final _domain = TextEditingController();
  final _hours = TextEditingController();
  final _facebook = TextEditingController();
  final _instagram = TextEditingController();
  final _whatsapp = TextEditingController();
  late Future<(Map<String, dynamic>, Map<String, dynamic>?)> _future = _load();
  List<dynamic> _instructions = const [];
  bool _published = true;

  Future<(Map<String, dynamic>, Map<String, dynamic>?)> _load() async {
    final settings = await _service.settings();
    final domain = await _service.domain();
    _published = settings['publie'] as bool? ?? true;
    _domain.text = domain?['domaine_personnalise'] as String? ?? '';
    final social = (settings['liens_sociaux'] as Map?)?.cast<String, dynamic>() ?? const {};
    _facebook.text = social['facebook'] as String? ?? '';
    _instagram.text = social['instagram'] as String? ?? '';
    _whatsapp.text = _shop.active.value?.whatsapp ?? '';
    final hours = (settings['horaires'] as Map?)?.cast<String, dynamic>() ?? const {};
    _hours.text = hours['texte'] as String? ?? '';
    return (settings, domain);
  }

  @override
  void dispose() {
    for (final c in [_domain, _hours, _facebook, _instagram, _whatsapp]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveContact() async {
    final l10n = AppLocalizations.of(context);
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    await runSiteAction(context, () async {
      await _service.updateSettings({
        'liens_sociaux': {'facebook': ?text(_facebook), 'instagram': ?text(_instagram)},
        'horaires': {if (text(_hours) != null) 'texte': text(_hours)},
      });
      await _service.updateShop({'whatsapp': text(_whatsapp)});
      await _shop.refreshActive();
    }, success: l10n.saved);
  }

  Future<void> _saveDomain() async {
    final l10n = AppLocalizations.of(context);
    final domain = normalizeDomain(_domain.text);
    if (domain.isNotEmpty && !isValidCustomDomain(domain)) {
      showMessage(l10n.domainInvalid, error: true);
      return;
    }
    final ok = await runSiteAction(context, () => _service.setCustomDomain(domain.isEmpty ? null : domain), success: l10n.saved);
    if (ok) setState(() => _future = _load());
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context);
    if (!ensureOnline(l10n)) return;
    try {
      final result = await _service.verifyDomain();
      setState(() {
        _instructions = (result['instructions'] as List?) ?? const [];
        _future = _load();
      });
    } catch (e) {
      showMessage(friendlyError(l10n, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = _shop.can('site.gerer') && !_shop.readOnly;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.siteGeneral)),
      body: FutureBuilder<(Map<String, dynamic>, Map<String, dynamic>?)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: () => setState(() => _future = _load()));
          final domain = snapshot.data!.$2;
          return ListView(padding: const EdgeInsets.all(16), children: [
            SwitchListTile(
              title: Text(l10n.sitePublished),
              value: _published,
              onChanged: !canEdit ? null : (v) async {
                final ok = await runSiteAction(context, () => _service.updateSettings({'publie': v}));
                if (ok) setState(() => _published = v);
              },
            ),
            const Divider(),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.link), title: Text(l10n.subdomain), subtitle: Text(domain?['sous_domaine'] as String? ?? _shop.active.value?.slug ?? '', textDirection: TextDirection.ltr), trailing: const Icon(Icons.lock_outline, size: 18)),
            Text(l10n.subdomainReadOnlyHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            TextField(controller: _domain, enabled: canEdit, textDirection: TextDirection.ltr, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: l10n.customDomain, hintText: 'maboutique.com')),
            const SizedBox(height: 8),
            if (domain?['domaine_personnalise'] != null) Wrap(spacing: 8, children: [Chip(label: Text('DNS : ${domainStatusLabel(l10n, domain?['statut_dns'] as String?)}')), Chip(label: Text('SSL : ${domainStatusLabel(l10n, domain?['statut_ssl'] as String?)}'))]),
            if (canEdit) Row(children: [OutlinedButton(onPressed: _saveDomain, child: Text(l10n.save)), const SizedBox(width: 8), if (domain?['domaine_personnalise'] != null) FilledButton(onPressed: _verify, child: Text(l10n.verifyDomain))]),
            if (_instructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.dnsInstructions),
              for (final i in _instructions) SelectableText('${(i as Map)['type']}  ${i['nom']}  →  ${i['valeur']}', textDirection: TextDirection.ltr),
            ],
            const Divider(height: 32),
            TextField(controller: _whatsapp, enabled: canEdit, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l10n.whatsapp)),
            const SizedBox(height: 12),
            TextField(controller: _facebook, enabled: canEdit, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'Facebook')),
            const SizedBox(height: 12),
            TextField(controller: _instagram, enabled: canEdit, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'Instagram')),
            const SizedBox(height: 12),
            TextField(controller: _hours, enabled: canEdit, maxLines: 2, decoration: InputDecoration(labelText: l10n.openingHours)),
            const SizedBox(height: 16),
            if (canEdit) FilledButton(onPressed: _saveContact, child: Text(l10n.save)),
          ]);
        },
      ),
    );
  }
}

/// Identité visuelle : logo, favicon, couleurs, police, forme, thème ; aperçu en direct, brouillon puis publication.
class SiteAppearancePage extends StatefulWidget {
  const SiteAppearancePage({super.key});

  @override
  State<SiteAppearancePage> createState() => _SiteAppearancePageState();
}

class _SiteAppearancePageState extends State<SiteAppearancePage> {
  final _service = siteService();
  final _shop = Get.find<ShopController>();
  late Future<(Map<String, dynamic>, List<Map<String, dynamic>>)> _future = _load();
  ThemeDraft _draft = ThemeDraft();
  bool _hasDraft = false;
  bool _busy = false;
  String? _favicon;

  Future<(Map<String, dynamic>, List<Map<String, dynamic>>)> _load() async {
    final settings = await _service.settings();
    final themes = await _service.themes();
    final draftJson = (settings['config_brouillon'] as Map?)?.cast<String, dynamic>();
    _hasDraft = draftJson != null;
    _draft = ThemeDraft.fromJson(draftJson ?? {...((settings['config_theme'] as Map?)?.cast<String, dynamic>() ?? {}), 'theme_id': settings['theme_id']});
    _favicon = settings['favicon_url'] as String?;
    return (settings, themes);
  }

  Future<void> _pickLogo() async {
    final l10n = AppLocalizations.of(context);
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (file == null || !mounted) return;
    await runSiteAction(context, () async => _shop.setLogo(await file.readAsBytes()), success: l10n.saved);
  }

  Future<void> _pickFavicon() async {
    final l10n = AppLocalizations.of(context);
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 256, imageQuality: 90);
    if (file == null || !mounted) return;
    final ok = await runSiteAction(context, () async {
      final previous = _favicon;
      final path = await _service.uploadAsset(await file.readAsBytes(), 'favicon');
      await _service.updateSettings({'favicon_url': path});
      await _service.removeAsset(previous);
      _favicon = path;
    }, success: l10n.saved);
    if (ok) setState(() {});
  }

  Future<void> _color(String label, Color current, ValueChanged<Color> apply) async {
    final l10n = AppLocalizations.of(context);
    var picked = current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: SingleChildScrollView(child: ColorPicker(color: current, onChanged: (c) => picked = c)),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.confirm))],
      ),
    );
    if (ok == true) setState(() => apply(picked));
  }

  Future<void> _saveDraft() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final ok = await runSiteAction(context, () => _service.saveDraft(_draft), success: l10n.draftSaved);
    if (mounted) setState(() { _busy = false; if (ok) _hasDraft = true; });
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final ok = await runSiteAction(context, () => _service.publishDraft(_draft), success: l10n.draftPublished);
    if (mounted) setState(() { _busy = false; if (ok) _hasDraft = false; });
  }

  String _label(AppLocalizations l10n, String group, String value) => switch ((group, value)) {
        ('font', 'systeme') => l10n.fontSystem,
        ('font', 'serif') => l10n.fontSerif,
        ('font', 'naskh') => l10n.fontNaskh,
        ('font', 'arrondie') => l10n.fontRounded,
        ('radius', 'aucun') => l10n.radiusNone,
        ('radius', 'petit') => l10n.radiusSmall,
        ('radius', 'moyen') => l10n.radiusMedium,
        ('radius', 'grand') => l10n.radiusLarge,
        ('radius', 'pilule') => l10n.radiusPill,
        ('card', 'bordure') => l10n.cardBorder,
        ('card', 'ombre') => l10n.cardShadow,
        ('card', 'minimal') => l10n.cardMinimal,
        ('header', 'centre') => l10n.headerCenter,
        ('header', 'gauche') => l10n.headerLeft,
        _ => value,
      };

  Widget _choices(String title, List<String> values, String selected, String group, ValueChanged<String> onSelected) {
    final l10n = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 12, bottom: 4), child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
      Wrap(spacing: 8, children: [for (final v in values) ChoiceChip(label: Text(_label(l10n, group, v)), selected: selected == v, onSelected: (_) => setState(() => onSelected(v)))]),
    ]);
  }

  Widget _swatch(String label, Color color, ValueChanged<Color> apply) => InkWell(
        onTap: () => _color(label, color, apply),
        child: Column(children: [CircleAvatar(radius: 20, backgroundColor: color, child: Icon(Icons.edit, size: 14, color: ThemeDraft.onColor(color))), const SizedBox(height: 4), SizedBox(width: 72, child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)))]),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = _shop.can('site.gerer') && !_shop.readOnly;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.siteAppearance)),
      body: FutureBuilder<(Map<String, dynamic>, List<Map<String, dynamic>>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: () => setState(() => _future = _load()));
          final themes = snapshot.data!.$2;
          final radius = radiusPixels(_draft.radius);
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              const ShopLogoAvatar(radius: 32),
              const SizedBox(width: 12),
              if (canEdit) ...[OutlinedButton(onPressed: _pickLogo, child: Text(l10n.chooseLogo)), const SizedBox(width: 8), OutlinedButton(onPressed: _pickFavicon, child: Text(l10n.faviconLabel))],
            ]),
            if (_favicon != null) Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [Image.network(shopAssetUrl(_favicon!), width: 24, height: 24, errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined)), const SizedBox(width: 8), Text(l10n.faviconLabel, style: Theme.of(context).textTheme.bodySmall)])),
            const Divider(height: 32),
            // Aperçu en direct de la boutique avec les choix en cours.
            Text(l10n.previewLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _draft.background, borderRadius: BorderRadius.circular(radius.clamp(0, 24)), border: Border.all(color: Colors.black12)),
              child: Column(crossAxisAlignment: _draft.header == 'centre' ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
                Text(_shop.active.value?.nomFr ?? _shop.active.value?.nomAr ?? '', style: TextStyle(color: _draft.text, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Row(children: [
                  for (var i = 0; i < _draft.grid; i++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _draft.background,
                          borderRadius: BorderRadius.circular(radius.clamp(0, 24)),
                          border: _draft.cardStyle == 'bordure' ? Border.all(color: _draft.text.withValues(alpha: 0.2)) : null,
                          boxShadow: _draft.cardStyle == 'ombre' ? const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))] : null,
                        ),
                        child: Column(children: [
                          Container(height: 36, decoration: BoxDecoration(color: _draft.secondary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(radius.clamp(0, 12)))),
                          const SizedBox(height: 6),
                          Text('1 500', style: TextStyle(color: _draft.text, fontSize: 12)),
                        ]),
                      ),
                    ),
                ]),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: _draft.primary, borderRadius: BorderRadius.circular(radius)), child: Text(l10n.confirm, style: TextStyle(color: ThemeDraft.onColor(_draft.primary)))),
              ]),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, children: [
              _swatch(l10n.primaryColor, _draft.primary, (c) => _draft.primary = c),
              _swatch(l10n.secondaryColor, _draft.secondary, (c) => _draft.secondary = c),
              _swatch(l10n.backgroundColor, _draft.background, (c) => _draft.background = c),
              _swatch(l10n.textColor, _draft.text, (c) => _draft.text = c),
            ]),
            _choices(l10n.fontLabel, siteFonts, _draft.font, 'font', (v) => _draft.font = v),
            _choices(l10n.radiusLabel, siteRadii, _draft.radius, 'radius', (v) => _draft.radius = v),
            _choices(l10n.cardStyleLabel, siteCardStyles, _draft.cardStyle, 'card', (v) => _draft.cardStyle = v),
            _choices(l10n.headerLabel, siteHeaders, _draft.header, 'header', (v) => _draft.header = v),
            Padding(padding: const EdgeInsets.only(top: 12, bottom: 4), child: Text(l10n.gridLabel, style: Theme.of(context).textTheme.titleSmall)),
            Wrap(spacing: 8, children: [for (final g in siteGrids) ChoiceChip(label: Text('$g'), selected: _draft.grid == g, onSelected: (_) => setState(() => _draft.grid = g))]),
            Padding(padding: const EdgeInsets.only(top: 12, bottom: 4), child: Text(l10n.themeLabel, style: Theme.of(context).textTheme.titleSmall)),
            Wrap(spacing: 8, children: [for (final t in themes) ChoiceChip(label: Text(localName(t['nom_ar'] as String?, t['nom_fr'] as String?, arabic: arabic)), selected: _draft.themeId == t['id'], onSelected: (_) => setState(() => _draft.themeId = t['id'] as String))]),
            const SizedBox(height: 16),
            if (_hasDraft) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(Icons.edit_note, color: Colors.orange), const SizedBox(width: 6), Text(l10n.unpublishedDraft)])),
            if (canEdit) Row(children: [
              Expanded(child: OutlinedButton(onPressed: _busy ? null : _saveDraft, child: Text(l10n.saveDraft))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton(onPressed: _busy ? null : _publish, child: Text(l10n.publishChanges))),
            ]),
          ]);
        },
      ),
    );
  }
}

/// Bannières du site : ajout (image envoyée dans le stockage public), ordre par glisser-déposer, activation.
class SiteBannersPage extends StatefulWidget {
  const SiteBannersPage({super.key});

  @override
  State<SiteBannersPage> createState() => _SiteBannersPageState();
}

class _SiteBannersPageState extends State<SiteBannersPage> {
  final _service = siteService();
  final _shop = Get.find<ShopController>();
  late Future<List<Map<String, dynamic>>> _future = _service.rows(Tables.bannieresSite);

  void _reload() => setState(() => _future = _service.rows(Tables.bannieresSite));

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
    if (file == null || !mounted) return;
    final titleAr = TextEditingController();
    final titleFr = TextEditingController();
    final link = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addBanner),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleAr, textDirection: TextDirection.rtl, decoration: InputDecoration(labelText: l10n.sectionTitleAr)),
          const SizedBox(height: 8),
          TextField(controller: titleFr, decoration: InputDecoration(labelText: l10n.sectionTitleFr)),
          const SizedBox(height: 8),
          TextField(controller: link, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l10n.bannerLink)),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save))],
      ),
    );
    final values = (titleAr.text.trim(), titleFr.text.trim(), link.text.trim());
    titleAr.dispose();
    titleFr.dispose();
    link.dispose();
    if (ok != true || !mounted) return;
    final count = (await _future).length;
    if (!mounted) return;
    final added = await runSiteAction(context, () async {
      final path = await _service.uploadAsset(await file.readAsBytes(), 'bannieres/${const Uuid().v4()}');
      await _service.insert(Tables.bannieresSite, {'image_url': path, 'titre_ar': values.$1.isEmpty ? null : values.$1, 'titre_fr': values.$2.isEmpty ? null : values.$2, 'lien': values.$3.isEmpty ? null : values.$3, 'ordre': count});
    }, success: l10n.saved);
    if (added) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = _shop.can('site.gerer') && !_shop.readOnly;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.siteBanners)),
      floatingActionButton: canEdit ? FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add_photo_alternate_outlined), label: Text(l10n.addBanner)) : null,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: _reload);
          final banners = snapshot.data!;
          if (banners.isEmpty) return const EmptyState(icon: Icons.view_carousel_outlined);
          return Column(children: [
            Padding(padding: const EdgeInsets.all(8), child: Text(l10n.reorderHint, style: Theme.of(context).textTheme.bodySmall)),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: banners.length,
                onReorderItem: !canEdit ? (_, _) {} : (oldIndex, newIndex) async {
                  final ids = [for (final b in banners) b['id'] as String];
                  final after = reordered(ids, oldIndex, newIndex);
                  final ok = await runSiteAction(context, () => _service.saveOrder(Tables.bannieresSite, orderUpdates(ids, after)));
                  if (ok) _reload();
                },
                itemBuilder: (_, i) {
                  final b = banners[i];
                  return ListTile(
                    key: ValueKey(b['id']),
                    leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(shopAssetUrl(b['image_url'] as String), width: 64, height: 40, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined))),
                    title: Text(localName(b['titre_ar'] as String?, b['titre_fr'] as String?, arabic: Localizations.localeOf(context).languageCode == 'ar')),
                    subtitle: b['lien'] == null ? null : Text(b['lien'] as String, textDirection: TextDirection.ltr),
                    trailing: canEdit
                        ? Row(mainAxisSize: MainAxisSize.min, children: [
                            Switch(value: b['actif'] as bool, onChanged: (v) async { if (await runSiteAction(context, () => _service.update(Tables.bannieresSite, b['id'] as String, {'actif': v}))) _reload(); }),
                            IconButton(icon: const Icon(Icons.delete_outline), tooltip: l10n.delete, onPressed: () async {
                              if (!await confirmDialog(context, title: l10n.delete)) return;
                              if (!context.mounted) return;
                              final ok = await runSiteAction(context, () async {
                                await _service.delete(Tables.bannieresSite, b['id'] as String);
                                await _service.removeAsset(b['image_url'] as String?);
                              });
                              if (ok) _reload();
                            }),
                          ])
                        : null,
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}
