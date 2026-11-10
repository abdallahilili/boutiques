import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/routing/app_pages.dart';
import '../../core/session/shop_controller.dart';
import '../../core/sync/sync_service.dart';
import '../../core/types/database_types.dart';
import '../../core/util/errors.dart';
import '../../core/util/format.dart';
import '../../core/widgets/common.dart';
import '../../l10n/app_localizations.dart';

/// Assistant du premier lancement : infos boutique, logo, catégories de départ, mode de paiement par défaut.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _shop = Get.find<ShopController>();
  final _client = Get.find<SupabaseClient>();
  final _key = GlobalKey<FormState>();
  int _step = 0;
  bool _busy = false;

  late final _ar = TextEditingController(text: _shop.active.value?.nomAr ?? '');
  late final _fr = TextEditingController(text: _shop.active.value?.nomFr ?? '');
  late final _address = TextEditingController(text: _shop.active.value?.adresse ?? '');
  late final _phone = TextEditingController(text: _shop.active.value?.telephone ?? '');
  XFile? _logo;

  List<Map<String, dynamic>> _categories = [];
  final _kept = <String>{};
  List<Map<String, dynamic>> _modes = [];
  String? _defaultMode;

  @override
  void initState() {
    super.initState();
    _loadChoices();
  }

  Future<void> _loadChoices() async {
    final categories = await _client.from(Tables.categories).select().eq('boutique_id', _shop.shopId).order('ordre');
    final modes = await _client.from(Tables.modesPaiement).select().eq('boutique_id', _shop.shopId).order('ordre');
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _kept.addAll(categories.map((c) => c['id'] as String));
      _modes = modes;
      _defaultMode = modes.where((m) => m['par_defaut'] == true).firstOrNull?['id'] as String?;
    });
  }

  Future<void> _next() async {
    final l10n = AppLocalizations.of(context);
    if (_step == 0 && !(_key.currentState?.validate() ?? false)) return;
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    setState(() => _busy = true);
    try {
      String? logoPath;
      if (_logo != null) {
        logoPath = '${_shop.shopId}/logo-${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _client.storage.from('shop-assets').uploadBinary(logoPath, await _logo!.readAsBytes(), fileOptions: const FileOptions(contentType: 'image/jpeg'));
      }
      final current = _shop.active.value!;
      final settings = current.parametres is Map ? Map<String, dynamic>.from(current.parametres as Map) : <String, dynamic>{};
      await _client.from(Tables.boutiques).update({
        'nom_ar': _ar.text.trim().isEmpty ? null : _ar.text.trim(),
        'nom_fr': _fr.text.trim().isEmpty ? null : _fr.text.trim(),
        'adresse': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'telephone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'logo_url': ?logoPath,
        'parametres': {...settings, 'onboarding_termine': true},
      }).eq('id', _shop.shopId);
      for (final c in _categories) {
        if (!_kept.contains(c['id'])) await _client.from(Tables.categories).update({'actif': false}).eq('id', c['id'] as String);
      }
      if (_defaultMode != null) {
        for (final m in _modes) {
          await _client.from(Tables.modesPaiement).update({'par_defaut': m['id'] == _defaultMode}).eq('id', m['id'] as String);
        }
      }
      await _shop.refreshActive();
      await Get.find<SyncService>().syncAll();
      Get.offAllNamed(Routes.home);
    } catch (e) {
      showMessage(friendlyError(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final steps = [l10n.onboardingShop, l10n.onboardingCategories, l10n.onboardingPayment];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: Column(children: [
        LinearProgressIndicator(value: (_step + 1) / steps.length),
        Padding(padding: const EdgeInsets.all(16), child: Text('${_step + 1}/${steps.length} · ${steps[_step]}', style: Theme.of(context).textTheme.titleMedium)),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            if (_step == 0)
              Form(
                key: _key,
                child: Column(children: [
                  BilingualNameFields(arabic: _ar, french: _fr),
                  const SizedBox(height: 12),
                  TextFormField(controller: _address, decoration: InputDecoration(labelText: l10n.address)),
                  const SizedBox(height: 12),
                  TextFormField(controller: _phone, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l10n.phone)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(onPressed: () async { final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85); if (f != null) setState(() => _logo = f); }, icon: const Icon(Icons.image_outlined), label: Text(_logo == null ? l10n.chooseLogo : _logo!.name)),
                ]),
              ),
            if (_step == 1) ...[
              Text(l10n.onboardingCategoriesHint),
              for (final c in _categories)
                CheckboxListTile(value: _kept.contains(c['id']), title: Text(localName(c['nom_ar'] as String?, c['nom_fr'] as String?, arabic: arabic)), onChanged: (v) => setState(() => v == true ? _kept.add(c['id'] as String) : _kept.remove(c['id'])), controlAffinity: ListTileControlAffinity.leading),
            ],
            if (_step == 2) ...[
              Text(l10n.onboardingPaymentHint),
              RadioGroup<String?>(
                groupValue: _defaultMode,
                onChanged: (v) => setState(() => _defaultMode = v),
                child: Column(children: [for (final m in _modes.where((m) => m['type'] != 'credit')) RadioListTile<String?>(value: m['id'] as String, title: Text(localName(m['nom_ar'] as String?, m['nom_fr'] as String?, arabic: arabic)))]),
              ),
            ],
          ]),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              if (_step > 0) TextButton(onPressed: () => setState(() => _step--), child: Text(l10n.back)),
              const Spacer(),
              FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(140, 52)), onPressed: _busy ? null : _next, child: Text(_step == steps.length - 1 ? l10n.finish : l10n.next)),
            ]),
          ),
        ),
      ]),
    );
  }
}
