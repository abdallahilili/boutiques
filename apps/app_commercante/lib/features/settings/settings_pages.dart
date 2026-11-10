import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/shop_controller.dart';
import '../../core/types/database_types.dart';
import '../../core/util/contact.dart';
import '../../core/util/errors.dart';
import '../../core/util/format.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/shop_logo.dart';
import '../../l10n/app_localizations.dart';
import 'appearance_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shop = Get.find<ShopController>();
    Widget item(IconData icon, String label, Widget Function() page, {bool visible = true}) => visible ? ListTile(leading: Icon(icon), title: Text(label), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page()))) : const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuSettings)),
      body: ListView(children: [
        Obx(() {
          final row = shop.active.value;
          final arabic = Localizations.localeOf(context).languageCode == 'ar';
          final canEdit = shop.can('parametres.gerer');
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: const ShopLogoAvatar(radius: 28),
            title: Text(localName(row?.nomAr, row?.nomFr, arabic: arabic), style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text(l10n.shopIdentity),
            trailing: canEdit ? const Icon(Icons.edit_outlined) : null,
            onTap: canEdit ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ShopProfilePage())) : null,
          );
        }),
        const Divider(height: 1),
        item(Icons.storefront_outlined, l10n.shopProfile, () => const ShopProfilePage(), visible: shop.can('parametres.gerer')),
        item(Icons.palette_outlined, l10n.appearance, () => const AppearancePage()),
        item(Icons.public, l10n.onlineStore, () => const OnlineStorePage()),
        item(Icons.group_outlined, l10n.employees, () => const EmployeesPage(), visible: shop.can('employes.gerer')),
        item(Icons.workspace_premium_outlined, l10n.menuSubscription, () => const SubscriptionPage(), visible: shop.can('abonnement.voir')),
      ]),
    );
  }
}

/// Profil de la boutique : noms, coordonnées, pied de page des documents, seuil de stock par défaut.
class ShopProfilePage extends StatefulWidget {
  const ShopProfilePage({super.key});

  @override
  State<ShopProfilePage> createState() => _ShopProfilePageState();
}

class _ShopProfilePageState extends State<ShopProfilePage> {
  final _shop = Get.find<ShopController>();
  final _client = Get.find<SupabaseClient>();
  final _key = GlobalKey<FormState>();
  late final BoutiquesRow _row = _shop.active.value!;
  late final Map<String, dynamic> _settings = _row.parametres is Map ? Map<String, dynamic>.from(_row.parametres as Map) : {};
  late final _ar = TextEditingController(text: _row.nomAr ?? '');
  late final _fr = TextEditingController(text: _row.nomFr ?? '');
  late final _address = TextEditingController(text: _row.adresse ?? '');
  late final _city = TextEditingController(text: _row.ville ?? '');
  late final _phone = TextEditingController(text: _row.telephone ?? '');
  late final _whatsapp = TextEditingController(text: _row.whatsapp ?? '');
  late final _footerAr = TextEditingController(text: _settings['pied_page_ar'] as String? ?? '');
  late final _footerFr = TextEditingController(text: _settings['pied_page_fr'] as String? ?? '');
  late final _threshold = TextEditingController(text: '${_settings['seuil_stock_defaut'] ?? 2}');
  late bool _negative = _settings['stock_negatif_autorise'] == true;
  bool _saving = false;
  bool _logoBusy = false;

  Future<void> _changeLogo() async {
    final l10n = AppLocalizations.of(context);
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (file == null) return;
    setState(() => _logoBusy = true);
    try {
      await _shop.setLogo(await file.readAsBytes());
      showMessage(l10n.saved);
    } catch (e) {
      showMessage(friendlyError(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  Future<void> _removeLogo() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _logoBusy = true);
    try {
      await _shop.removeLogo();
    } catch (e) {
      showMessage(friendlyError(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_key.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
      await _client.from(Tables.boutiques).update({
        'nom_ar': text(_ar),
        'nom_fr': text(_fr),
        'adresse': text(_address),
        'ville': text(_city),
        'telephone': text(_phone),
        'whatsapp': text(_whatsapp),
        'parametres': {..._settings, 'pied_page_ar': text(_footerAr), 'pied_page_fr': text(_footerFr), 'seuil_stock_defaut': parseAmount(_threshold.text) ?? 2, 'stock_negatif_autorise': _negative},
      }).eq('id', _shop.shopId);
      await _shop.refreshActive();
      showMessage(l10n.saved);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      showMessage(friendlyError(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shopProfile)),
      body: Form(
        key: _key,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const ShopLogoAvatar(radius: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.shopLogo, style: Theme.of(context).textTheme.titleMedium),
                Text(l10n.shopLogoHint, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                if (_logoBusy)
                  const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                else
                  Wrap(spacing: 8, children: [
                    OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: _changeLogo, icon: const Icon(Icons.image_outlined), label: Text(l10n.changeLogo)),
                    Obx(() => (_shop.logoPath ?? '').isEmpty ? const SizedBox.shrink() : TextButton(onPressed: _removeLogo, child: Text(l10n.removeLogo))),
                  ]),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          BilingualNameFields(arabic: _ar, french: _fr),
          const SizedBox(height: 12),
          TextFormField(controller: _address, decoration: InputDecoration(labelText: l10n.address)),
          const SizedBox(height: 12),
          TextFormField(controller: _city, decoration: InputDecoration(labelText: l10n.city)),
          const SizedBox(height: 12),
          TextFormField(controller: _phone, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l10n.phone)),
          const SizedBox(height: 12),
          TextFormField(controller: _whatsapp, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l10n.whatsapp)),
          const SizedBox(height: 12),
          InputDecorator(decoration: InputDecoration(labelText: l10n.currency), child: Text(_row.devise)),
          const SizedBox(height: 12),
          TextFormField(controller: _footerAr, textDirection: TextDirection.rtl, maxLines: 2, decoration: InputDecoration(labelText: l10n.documentFooterAr)),
          const SizedBox(height: 12),
          TextFormField(controller: _footerFr, maxLines: 2, decoration: InputDecoration(labelText: l10n.documentFooterFr)),
          const SizedBox(height: 12),
          NumberField(controller: _threshold, label: l10n.defaultStockThreshold, min: 0),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.allowNegativeStock), value: _negative, onChanged: (v) => setState(() => _negative = v)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ]),
      ),
    );
  }
}

/// Boutique en ligne : sous-domaine en lecture seule (attribué à la création, modifiable par l'éditeur seulement) et domaine personnalisé.
class OnlineStorePage extends StatelessWidget {
  const OnlineStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shop = Get.find<ShopController>();
    final client = Get.find<SupabaseClient>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onlineStore)),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: client.from(Tables.domainesBoutique).select().eq('boutique_id', shop.shopId).maybeSingle(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final d = snapshot.data;
          return ListView(children: [
            ListTile(leading: const Icon(Icons.link), title: Text(l10n.subdomain), subtitle: Text(d?['sous_domaine'] as String? ?? shop.active.value?.slug ?? '', textDirection: TextDirection.ltr), trailing: const Icon(Icons.lock_outline, size: 18)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.subdomainReadOnlyHint, style: Theme.of(context).textTheme.bodySmall)),
            const Divider(),
            ListTile(leading: const Icon(Icons.dns_outlined), title: Text(l10n.customDomain), subtitle: Text(d?['domaine_personnalise'] as String? ?? l10n.none, textDirection: TextDirection.ltr), trailing: d?['domaine_personnalise'] == null ? null : Text('${d?['statut_dns']}')),
            ListTile(leading: const Icon(Icons.qr_code_2), title: Text(l10n.shopCode), subtitle: Text(shop.active.value?.codeBoutique ?? '', textDirection: TextDirection.ltr)),
          ]);
        },
      ),
    );
  }
}

/// Employées : liste, invitation (téléphone + rôle), activation / désactivation, réinitialisation du code.
class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final _shop = Get.find<ShopController>();
  final _client = Get.find<SupabaseClient>();
  late Future<(List<Map<String, dynamic>>, Map<String, Map<String, dynamic>>, Map<String, String>)> _future = _load();

  Future<(List<Map<String, dynamic>>, Map<String, Map<String, dynamic>>, Map<String, String>)> _load() async {
    final members = await _client.from(Tables.membresBoutique).select().eq('boutique_id', _shop.shopId);
    final profiles = await _client.from(Tables.profils).select();
    final roles = await _client.from(Tables.roles).select();
    return (members, {for (final p in profiles) p['id'] as String: p}, {for (final r in roles) r['id'] as String: r['cle'] as String});
  }

  void _reload() => setState(() => _future = _load());

  String _roleLabel(AppLocalizations l10n, String? key) => switch (key) {
        'proprietaire' => l10n.roleOwner,
        'manager' => l10n.roleManager,
        'vendeuse' => l10n.roleCashier,
        'magasiniere' => l10n.roleStockKeeper,
        _ => key ?? '',
      };

  Future<void> _showCode(String code, String link) => showDialog<void>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l10n.initialCode),
            content: Column(mainAxisSize: MainAxisSize.min, children: [Text(code, style: Theme.of(context).textTheme.displaySmall, textDirection: TextDirection.ltr), const SizedBox(height: 8), Text(l10n.initialCodeHint, textAlign: TextAlign.center)]),
            actions: [TextButton(onPressed: () => openUrl(link), child: Text(l10n.whatsapp)), FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close))],
          );
        },
      );

  Future<void> _invite() async {
    final l10n = AppLocalizations.of(context);
    final phone = TextEditingController();
    final name = TextEditingController();
    String role = 'vendeuse';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.inviteEmployee),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: InputDecoration(labelText: l10n.nameFr)),
              const SizedBox(height: 8),
              TextField(controller: phone, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l10n.phone)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(initialValue: role, decoration: InputDecoration(labelText: l10n.role), items: [for (final r in ['manager', 'vendeuse', 'magasiniere']) DropdownMenuItem(value: r, child: Text(_roleLabel(l10n, r)))], onChanged: (v) => setState(() => role = v ?? role)),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.confirm))],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final response = await _client.functions.invoke('invite-member', body: {'boutique_id': _shop.shopId, 'telephone': phone.text, 'nom_fr': name.text, 'nom_ar': name.text, 'role': role});
      final data = response.data as Map<String, dynamic>;
      _reload();
      if (data['code_initial'] != null) await _showCode(data['code_initial'] as String, data['lien_whatsapp'] as String);
    } on FunctionException catch (e) {
      showMessage((e.details is Map && (e.details as Map)['erreur'] == 'quota_depasse') ? l10n.serverError_quota_depasse : l10n.genericError, error: true);
    }
  }

  Future<void> _resetCode(String userId) async {
    try {
      final response = await _client.functions.invoke('reset-pin', body: {'utilisateur_id': userId});
      final data = response.data as Map<String, dynamic>;
      await _showCode(data['code'] as String, data['lien_whatsapp'] as String);
    } catch (_) {
      if (mounted) showMessage(AppLocalizations.of(context).genericError, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.employees)),
      floatingActionButton: _shop.readOnly ? null : FloatingActionButton(onPressed: _invite, child: const Icon(Icons.person_add_alt_1)),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!), onRetry: _reload);
          final (members, profiles, roles) = snapshot.data!;
          return ListView(children: [
            for (final m in members)
              Builder(builder: (context) {
                final profile = profiles[m['utilisateur_id']];
                final role = roles[m['role_id']];
                final active = m['statut'] == 'actif';
                return ListTile(
                  leading: CircleAvatar(child: Text((localName(profile?['nom_ar'] as String?, profile?['nom_fr'] as String?, arabic: arabic)).characters.first)),
                  title: Text(localName(profile?['nom_ar'] as String?, profile?['nom_fr'] as String?, arabic: arabic), style: active ? null : const TextStyle(decoration: TextDecoration.lineThrough)),
                  subtitle: Text('${_roleLabel(l10n, role)} · ${profile?['telephone'] ?? ''}', textDirection: TextDirection.ltr),
                  trailing: role == 'proprietaire' || _shop.readOnly
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'reset') await _resetCode(m['utilisateur_id'] as String);
                            if (v == 'toggle') {
                              await _client.from(Tables.membresBoutique).update({'statut': active ? 'desactive' : 'actif'}).eq('id', m['id'] as String);
                              _reload();
                            }
                          },
                          itemBuilder: (_) => [PopupMenuItem(value: 'reset', child: Text(l10n.resetCode)), PopupMenuItem(value: 'toggle', child: Text(active ? l10n.deactivate : l10n.activate))],
                        ),
                );
              }),
          ]);
        },
      ),
    );
  }
}

/// Abonnement : plan actuel, échéance, quotas ; le paiement est enregistré par l'éditeur (V1).
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shop = Get.find<ShopController>();
    final client = Get.find<SupabaseClient>();
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuSubscription)),
      body: FutureBuilder(
        future: () async {
          final subscription = await client.from(Tables.abonnements).select().eq('boutique_id', shop.shopId).inFilter('statut', ['essai', 'actif', 'grace', 'suspendu', 'expire']).order('cree_le', ascending: false).limit(1).maybeSingle();
          final plan = subscription == null ? null : await client.from(Tables.plans).select().eq('id', subscription['plan_id'] as String).single();
          return (subscription, plan);
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final (subscription, plan) = snapshot.data ?? (null, null);
          if (subscription == null || plan == null) return const EmptyState(icon: Icons.workspace_premium_outlined);
          final limits = (plan['limites'] as Map).cast<String, dynamic>();
          String limit(String key) => limits[key] == null ? l10n.unlimited : '${limits[key]}';
          return ListView(children: [
            ListTile(leading: const Icon(Icons.workspace_premium_outlined), title: Text(localName(plan['nom_ar'] as String?, plan['nom_fr'] as String?, arabic: arabic)), subtitle: Text('${subscription['statut']}')),
            ListTile(leading: const Icon(Icons.event_outlined), title: Text(l10n.expiresOn(subscription['fin_le'] == null ? '—' : formatDate(DateTime.parse(subscription['fin_le'] as String), Localizations.localeOf(context))))),
            ListTile(leading: const Icon(Icons.group_outlined), title: Text('${l10n.employees}: ${limit('utilisateurs')}')),
            ListTile(leading: const Icon(Icons.inventory_2_outlined), title: Text('${l10n.productsTitle}: ${limit('produits')}')),
            Padding(padding: const EdgeInsets.all(16), child: Text(l10n.renewalHint)),
          ]);
        },
      ),
    );
  }
}
