import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/shop_controller.dart';
import '../../core/sync/sync_service.dart';
import '../../core/util/errors.dart';
import '../../core/util/format.dart';
import '../../core/widgets/color_picker.dart';
import '../../core/widgets/common.dart';
import '../../l10n/app_localizations.dart';
import '../site/data/site_service.dart';
import 'category_image_field.dart';
import 'referential_config.dart';
import 'referential_controller.dart';

/// Menu des référentiels de la boutique.
class ReferentialsPage extends StatelessWidget {
  const ReferentialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shop = Get.find<ShopController>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuReferentials)),
      body: ListView(children: [
        for (final config in RefConfigs.all)
          if (shop.can(config.readPermission))
            ListTile(
              leading: const Icon(Icons.chevron_right),
              title: Text(config.title(l10n)),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReferentialListPage(config: config))),
            ),
      ]),
    );
  }
}

/// Liste générique : recherche locale, ajout/modification, désactivation, suppression si inutilisé, glisser-déposer.
class ReferentialListPage extends StatefulWidget {
  const ReferentialListPage({super.key, required this.config});

  final RefConfig config;

  @override
  State<ReferentialListPage> createState() => _ReferentialListPageState();
}

class _ReferentialListPageState extends State<ReferentialListPage> {
  late final ReferentialController _controller = Get.put(
    ReferentialController(widget.config, Get.find(), Get.find(), Get.find<SyncService>()),
    tag: widget.config.table,
  );

  @override
  void dispose() {
    Get.delete<ReferentialController>(tag: widget.config.table);
    super.dispose();
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RefForm(config: widget.config, controller: _controller, row: row),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final config = widget.config;

    Widget tile(Map<String, dynamic> row, int index) {
      final active = row['actif'] as bool? ?? true;
      final color = row['code_hex'] is String ? _parseHex(row['code_hex'] as String) : null;
      return ListTile(
        key: ValueKey(row['id']),
        leading: color != null
            ? CircleAvatar(backgroundColor: color, radius: 16)
            : config.fields.any((f) => f.kind == RefFieldKind.categoryImage)
                ? CategoryAvatar(imagePath: row['image_url'] as String?, iconKey: row['icone'] as String?)
                : null,
        title: Text(localName(row['nom_ar'] as String?, row['nom_fr'] as String?, arabic: arabic), style: active ? null : const TextStyle(decoration: TextDecoration.lineThrough)),
        subtitle: _subtitle(config, row, l10n),
        trailing: _controller.canWrite
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                if (config.hasActive) Switch(value: active, onChanged: (v) => _controller.setActive(row, v)),
                if (config.reorderable) ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)),
              ])
            : null,
        onTap: _controller.canWrite ? () => _edit(row) : null,
        onLongPress: _controller.canWrite
            ? () async {
                if (!await confirmDialog(context, title: l10n.deleteConfirm)) return;
                try {
                  if (!await _controller.delete(row)) showMessage(l10n.usedCannotDelete, error: true);
                } catch (e) {
                  showMessage(friendlyError(l10n, e), error: true);
                }
              }
            : null,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(config.title(l10n))),
      floatingActionButton: _controller.canWrite ? FloatingActionButton(onPressed: _edit, child: const Icon(Icons.add)) : null,
      body: Obx(() {
        if (_controller.loading.value && _controller.rows.isEmpty) return const Center(child: CircularProgressIndicator());
        if (_controller.error.value != null) return ErrorView(message: friendlyError(l10n, _controller.error.value!), onRetry: _controller.load);
        if (_controller.rows.isEmpty) return const EmptyState();
        final rows = _controller.rows.toList();
        if (config.reorderable && _controller.canWrite) {
          return Column(children: [
            Padding(padding: const EdgeInsets.all(8), child: Text(l10n.reorderHint, style: Theme.of(context).textTheme.bodySmall)),
            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: rows.length,
                onReorderItem: _controller.reorder,
                itemBuilder: (_, i) => tile(rows[i], i),
              ),
            ),
          ]);
        }
        return ListView.builder(itemCount: rows.length, itemBuilder: (_, i) => tile(rows[i], i));
      }),
    );
  }

  Widget? _subtitle(RefConfig config, Map<String, dynamic> row, AppLocalizations l10n) {
    final parts = <String>[
      if (row['code_hex'] != null) row['code_hex'] as String,
      if (row['type'] != null) config.choiceLabel(l10n, row['type'] as String),
      if (row['frais'] != null) '${l10n.deliveryFee}: ${formatMoney(asDouble(row['frais']), currency: Get.find<ShopController>().currency)}',
      if (row['telephone'] != null) row['telephone'] as String,
      if (row['abreviation'] != null) row['abreviation'] as String,
      if (row['par_defaut'] == true) l10n.isDefault,
    ];
    return parts.isEmpty ? null : Text(parts.join(' · '));
  }
}

Color? _parseHex(String hex) {
  final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex);
  return match == null ? null : Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
}

/// Formulaire d'un référentiel : noms ar/fr + champs propres à la configuration.
class RefForm extends StatefulWidget {
  const RefForm({super.key, required this.config, required this.controller, this.row, this.onSaved});

  final RefConfig config;
  final ReferentialController controller;
  final Map<String, dynamic>? row;
  final void Function(Map<String, dynamic> saved)? onSaved;

  @override
  State<RefForm> createState() => _RefFormState();
}

class _RefFormState extends State<RefForm> {
  final _key = GlobalKey<FormState>();
  late final _ar = TextEditingController(text: widget.row?['nom_ar'] as String? ?? '');
  late final _fr = TextEditingController(text: widget.row?['nom_fr'] as String? ?? '');
  late final Map<String, dynamic> _values = {
    for (final f in widget.config.fields) f.key: widget.row?[f.key] ?? f.defaultValue,
  };
  final Map<String, TextEditingController> _text = {};
  late CategoryImageValue _image = CategoryImageValue(imagePath: widget.row?['image_url'] as String?, iconKey: widget.row?['icone'] as String?);
  bool _saving = false;

  TextEditingController _controllerFor(RefField f) =>
      _text.putIfAbsent(f.key, () => TextEditingController(text: _values[f.key]?.toString() ?? ''));

  Future<void> _submit() async {
    if (!(_key.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final values = <String, dynamic>{'nom_ar': _ar.text.trim(), 'nom_fr': _fr.text.trim()};
      for (final f in widget.config.fields) {
        if (f.kind == RefFieldKind.categoryImage) continue; // géré après la boucle (envoi de la photo)
        final raw = f.kind == RefFieldKind.number || f.kind == RefFieldKind.text || f.kind == RefFieldKind.hex ? _controllerFor(f).text.trim() : _values[f.key];
        values[f.key] = f.kind == RefFieldKind.number ? (raw.toString().isEmpty ? null : parseAmount(raw.toString())) : raw;
      }
      // Image de catégorie : la nouvelle photo est envoyée avant l'enregistrement ; l'ancien fichier n'est
      // supprimé qu'une fois la ligne enregistrée (et la photo envoyée est retirée si l'enregistrement échoue).
      final hasImageField = widget.config.fields.any((f) => f.kind == RefFieldKind.categoryImage);
      final site = SiteService(Get.find<SupabaseClient>(), Get.find<ShopController>().shopId);
      final previousPath = widget.row?['image_url'] as String?;
      String? uploaded;
      if (hasImageField) {
        if (_image.newImage != null) uploaded = await site.uploadAsset(_image.newImage!, 'categories');
        values['image_url'] = uploaded ?? _image.imagePath;
        values['icone'] = _image.iconKey;
      }
      final Map<String, dynamic> saved;
      try {
        saved = await widget.controller.save(values, id: widget.row?['id'] as String?);
      } catch (_) {
        await site.removeAsset(uploaded);
        rethrow;
      }
      if (hasImageField && previousPath != null && previousPath != values['image_url']) await site.removeAsset(previousPath);
      widget.onSaved?.call(saved);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(friendlyError(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = widget.config;
    final categories = config.table == 'categories' ? widget.controller.rows.where((r) => r['id'] != widget.row?['id'] && r['parent_id'] == null).toList() : const <Map<String, dynamic>>[];
    final arabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            BilingualNameFields(arabic: _ar, french: _fr),
            for (final f in config.fields) ...[
              const SizedBox(height: 12),
              switch (f.kind) {
                RefFieldKind.text => TextFormField(controller: _controllerFor(f), decoration: InputDecoration(labelText: config.fieldLabel(f)(l10n))),
                RefFieldKind.number => NumberField(controller: _controllerFor(f), label: config.fieldLabel(f)(l10n), required: false, min: 0),
                RefFieldKind.hex => ColorHexField(controller: _controllerFor(f), label: config.fieldLabel(f)(l10n)),
                RefFieldKind.choice => DropdownButtonFormField<String>(
                    initialValue: _values[f.key] as String?,
                    decoration: InputDecoration(labelText: config.fieldLabel(f)(l10n)),
                    items: [for (final c in f.choices) DropdownMenuItem(value: c, child: Text(config.choiceLabel(l10n, c)))],
                    onChanged: (v) => _values[f.key] = v,
                  ),
                RefFieldKind.toggle => SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(config.fieldLabel(f)(l10n)), value: _values[f.key] == true, onChanged: (v) => setState(() => _values[f.key] = v)),
                RefFieldKind.categoryImage => CategoryImageField(value: _image, onChanged: (v) => setState(() => _image = v)),
                RefFieldKind.categoryParent => DropdownButtonFormField<String?>(
                    initialValue: _values[f.key] as String?,
                    decoration: InputDecoration(labelText: config.fieldLabel(f)(l10n)),
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text(l10n.none)),
                      for (final c in categories) DropdownMenuItem<String?>(value: c['id'] as String, child: Text(localName(c['nom_ar'] as String?, c['nom_fr'] as String?, arabic: arabic))),
                    ],
                    onChanged: (v) => _values[f.key] = v,
                  ),
              },
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _saving ? null : _submit, child: Text(l10n.save)),
          ]),
        ),
      ),
    );
  }
}

/// Couleur d'un référentiel : sélecteur visuel (carré + teinte + pastilles), le code `#RRGGBB` est écrit dans [controller].
class ColorHexField extends StatefulWidget {
  const ColorHexField({super.key, required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  State<ColorHexField> createState() => _ColorHexFieldState();
}

class _ColorHexFieldState extends State<ColorHexField> {
  late Color _color = colorFromHex(widget.controller.text) ?? Colors.black;

  @override
  void initState() {
    super.initState();
    widget.controller.text = colorToHex(_color);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(widget.label, style: Theme.of(context).textTheme.titleSmall)),
      ColorPicker(
        color: _color,
        onChanged: (c) => setState(() {
          _color = c;
          widget.controller.text = colorToHex(c);
        }),
      ),
    ]);
  }
}
