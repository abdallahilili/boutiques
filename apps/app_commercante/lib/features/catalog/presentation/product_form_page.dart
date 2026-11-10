import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/session/shop_controller.dart';
import '../../../core/util/errors.dart';
import '../../../core/util/format.dart';
import '../../../core/util/storage_urls.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../../referentials/referential_config.dart';
import '../../referentials/referential_controller.dart';
import '../../referentials/referential_pages.dart';
import '../domain/variant_combinations.dart';
import 'product_form_controller.dart';


class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final ProductFormController _c = Get.put(ProductFormController(Get.find(), Get.find(), Get.find(), Get.arguments as String?));
  final _shop = Get.find<ShopController>();

  @override
  void dispose() {
    Get.delete<ProductFormController>();
    super.dispose();
  }

  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';

  String _name(List<Map<String, dynamic>> list, String? id) {
    final row = list.firstWhereOrNull((r) => r['id'] == id);
    return row == null ? '' : localName(row['nom_ar'] as String?, row['nom_fr'] as String?, arabic: _arabic);
  }

  String _variantLabel(VariantDraft v) {
    final parts = [_name(_c.models, v.modelId), _name(_c.colors, v.colorId), _name(_c.sizes, v.sizeId)].where((s) => s.isNotEmpty);
    return parts.isEmpty ? AppLocalizations.of(context).productNew : parts.join(' · ');
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      await _c.save();
      showMessage(l10n.saved);
      Get.back<void>();
    } on ProductImageException catch (e) {
      showMessage(l10n.productImageFailed(e.message), error: true);
    } catch (e) {
      showMessage(friendlyError(l10n, e), error: true);
    }
  }

  Future<void> _archive() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirmDialog(context, title: l10n.archiveProduct, message: l10n.archiveConfirm)) return;
    await _c.archive();
    Get.back<void>();
  }

  /// Création « à la volée » d'un élément de référentiel pendant la saisie du produit.
  Future<void> _quickCreate(RefConfig config, RxnString target, RxList<Map<String, dynamic>> list) async {
    final controller = Get.put(ReferentialController(config, Get.find(), _shop, Get.find()), tag: 'quick-${config.table}');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RefForm(
        config: config,
        controller: controller,
        onSaved: (saved) {
          list.add(saved);
          target.value = saved['id'] as String;
        },
      ),
    );
    Get.delete<ReferentialController>(tag: 'quick-${config.table}');
  }

  Widget _refDropdown(String label, RxnString value, RxList<Map<String, dynamic>> list, RefConfig config) {
    final l10n = AppLocalizations.of(context);
    return Obx(() => DropdownButtonFormField<String?>(
          key: ValueKey('${config.table}-${value.value}-${list.length}'),
          initialValue: value.value,
          decoration: InputDecoration(labelText: label),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(l10n.none)),
            for (final r in list) DropdownMenuItem<String?>(value: r['id'] as String, child: Text(localName(r['nom_ar'] as String?, r['nom_fr'] as String?, arabic: _arabic))),
            DropdownMenuItem<String?>(value: '__new__', child: Text(l10n.addOnTheFly, style: TextStyle(color: Theme.of(context).colorScheme.primary))),
          ],
          onChanged: (v) => v == '__new__' ? _quickCreate(config, value, list) : value.value = v,
        ));
  }

  Future<void> _editVariant(VariantDraft variant) async {
    final changed = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => _VariantSheet(controller: _c, variant: variant, shop: _shop));
    if (changed == true) _c.variants.refresh();
  }

  Future<void> _addVariant() async {
    final variant = VariantDraft(id: const Uuid().v4(), price: _c.variants.isEmpty ? 0 : _c.variants.last.price);
    final changed = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => _VariantSheet(controller: _c, variant: variant, shop: _shop));
    if (changed == true) _c.variants.add(variant);
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context);
    final models = <String>{};
    final colors = <String>{};
    final sizes = <String>{};
    final price = TextEditingController(text: _c.variants.isEmpty ? '' : formatQuantity(_c.variants.last.price));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        Widget group(String title, List<Map<String, dynamic>> rows, Set<String> selected) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 12, bottom: 4), child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final r in rows)
                  FilterChip(
                    label: Text(localName(r['nom_ar'] as String?, r['nom_fr'] as String?, arabic: _arabic)),
                    avatar: r['code_hex'] is String ? CircleAvatar(backgroundColor: Color(0xFF000000 | int.parse((r['code_hex'] as String).substring(1), radix: 16))) : null,
                    selected: selected.contains(r['id']),
                    onSelected: (v) => setState(() => v ? selected.add(r['id'] as String) : selected.remove(r['id'])),
                  ),
              ]),
            ]);
        final count = _c.previewCombinations(models, colors, sizes).length;
        return AlertDialog(
          title: Text(l10n.variantsGenerate),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.variantsGenerateHint, style: Theme.of(context).textTheme.bodySmall),
              group(l10n.model, _c.models, models),
              group(l10n.color, _c.colors, colors),
              group(l10n.size, _c.sizes, sizes),
              const SizedBox(height: 12),
              TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.basePrice)),
              const SizedBox(height: 8),
              Text(l10n.variantsToCreate(count), style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.create))],
        );
      }),
    );
    if (ok == true) _c.generateVariants(models, colors, sizes, parseAmount(price.text) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_c.isNew ? l10n.productNew : l10n.productEdit),
        actions: [if (!_c.isNew) IconButton(tooltip: l10n.archiveProduct, icon: const Icon(Icons.archive_outlined), onPressed: _archive)],
      ),
      body: Obx(() {
        if (_c.loading.value) return const Center(child: CircularProgressIndicator());
        if (_c.error.value != null) return ErrorView(message: friendlyError(l10n, _c.error.value!), onRetry: _c.load);
        return Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            BilingualNameFields(arabic: _c.nameAr, french: _c.nameFr),
            const SizedBox(height: 12),
            TextFormField(controller: _c.descriptionAr, maxLines: 2, textDirection: TextDirection.rtl, decoration: InputDecoration(labelText: l10n.descriptionAr)),
            const SizedBox(height: 12),
            TextFormField(controller: _c.descriptionFr, maxLines: 2, decoration: InputDecoration(labelText: l10n.descriptionFr)),
            const SizedBox(height: 12),
            _refDropdown(l10n.category, _c.categoryId, _c.categories, RefConfigs.categories),
            const SizedBox(height: 12),
            _refDropdown(l10n.brand, _c.brandId, _c.brands, RefConfigs.brands),
            const SizedBox(height: 12),
            _refDropdown(l10n.unit, _c.unitId, _c.units, RefConfigs.units),
            const SizedBox(height: 12),
            TextFormField(controller: _c.tags, decoration: InputDecoration(labelText: l10n.tags)),
            Obx(() => SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.visibleOnline), value: _c.visibleOnline.value, onChanged: (v) => _c.visibleOnline.value = v)),
            Obx(() => SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.productActive), value: _c.active.value, onChanged: (v) => _c.active.value = v)),
            const Divider(),
            Text(l10n.photos, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 88,
              child: Obx(() => ListView(scrollDirection: Axis.horizontal, children: [
                    for (final image in _c.existingImages)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Stack(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(productImageUrl(image['url'] as String), width: 88, height: 88, fit: BoxFit.cover, cacheWidth: 264, errorBuilder: (_, _, _) => const SizedBox(width: 88, height: 88, child: Icon(Icons.broken_image_outlined)))),
                          PositionedDirectional(top: 0, end: 0, child: InkWell(onTap: () => _c.removeImage(image), child: const CircleAvatar(radius: 11, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)))),
                          if (image['principale'] == true) PositionedDirectional(bottom: 0, start: 0, end: 0, child: Container(color: Colors.black54, child: Text(l10n.photoMain, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11)))),
                        ]),
                      ),
                    for (final image in _c.newImages)
                      Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(image.bytes, width: 88, height: 88, fit: BoxFit.cover))),
                    InkWell(
                      onTap: _c.pickImages,
                      child: Container(width: 88, height: 88, decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_a_photo_outlined)),
                    ),
                  ])),
            ),
            const Divider(height: 32),
            Row(children: [
              Expanded(child: Text(l10n.variants, style: Theme.of(context).textTheme.titleMedium)),
              IconButton(tooltip: l10n.variantsGenerate, icon: const Icon(Icons.auto_awesome_motion_outlined), onPressed: _generate),
              IconButton(tooltip: l10n.variantAdd, icon: const Icon(Icons.add_circle_outline), onPressed: _addVariant),
            ]),
            Obx(() => Column(children: [
                  for (final v in _c.variants)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: v.colorId == null ? const Icon(Icons.label_outline) : CircleAvatar(radius: 14, backgroundColor: _hexColor(_c.colors.firstWhereOrNull((c) => c['id'] == v.colorId)?['code_hex'] as String?)),
                      title: Text(_variantLabel(v), style: v.active ? null : const TextStyle(decoration: TextDecoration.lineThrough)),
                      subtitle: Text('${formatMoney(v.price, currency: _shop.currency, decimals: _shop.decimals)}${v.barcode.isEmpty ? '' : ' · ${v.barcode}'}${v.active ? '' : ' · ${l10n.variantInactive}'}'),
                      trailing: const Icon(Icons.edit_outlined, size: 18),
                      onTap: () => _editVariant(v),
                    ),
                ])),
            const SizedBox(height: 24),
            Obx(() => FilledButton(onPressed: _c.saving.value ? null : _save, child: Text(l10n.save))),
          ]),
        );
      }),
    );
  }
}

Color _hexColor(String? hex) => hex == null ? Colors.grey : Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

/// Édition d'une variante : combinaison, prix, promotion, codes et seuil d'alerte.
class _VariantSheet extends StatefulWidget {
  const _VariantSheet({required this.controller, required this.variant, required this.shop});

  final ProductFormController controller;
  final VariantDraft variant;
  final ShopController shop;

  @override
  State<_VariantSheet> createState() => _VariantSheetState();
}

class _VariantSheetState extends State<_VariantSheet> {
  final _key = GlobalKey<FormState>();
  late final _price = TextEditingController(text: widget.variant.price == 0 ? '' : formatQuantity(widget.variant.price));
  late final _promo = TextEditingController(text: widget.variant.promoPrice == null ? '' : formatQuantity(widget.variant.promoPrice!));
  late final _sku = TextEditingController(text: widget.variant.sku);
  late final _barcode = TextEditingController(text: widget.variant.barcode);
  late final _min = TextEditingController(text: widget.variant.minStock == 0 ? '' : formatQuantity(widget.variant.minStock));
  late String? _model = widget.variant.modelId;
  late String? _color = widget.variant.colorId;
  late String? _size = widget.variant.sizeId;
  late DateTime? _promoStart = widget.variant.promoStart;
  late DateTime? _promoEnd = widget.variant.promoEnd;
  late bool _active = widget.variant.active;

  Widget _dimension(String label, List<Map<String, dynamic>> rows, String? value, ValueChanged<String?> onChanged) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(AppLocalizations.of(context).none)),
        for (final r in rows) DropdownMenuItem<String?>(value: r['id'] as String, child: Text(localName(r['nom_ar'] as String?, r['nom_fr'] as String?, arabic: arabic))),
      ],
      onChanged: onChanged,
    );
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: (start ? _promoStart : _promoEnd) ?? now, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 5));
    if (picked != null) setState(() => start ? _promoStart = picked : _promoEnd = picked);
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    if (!(_key.currentState?.validate() ?? false)) return;
    final combo = VariantCombo(_model, _color, _size);
    if (widget.controller.comboExists(combo, exceptId: widget.variant.id)) {
      showMessage(l10n.variantExists, error: true);
      return;
    }
    widget.variant
      ..modelId = _model
      ..colorId = _color
      ..sizeId = _size
      ..price = parseAmount(_price.text) ?? 0
      ..promoPrice = _promo.text.trim().isEmpty ? null : parseAmount(_promo.text)
      ..promoStart = _promoStart
      ..promoEnd = _promoEnd
      ..sku = _sku.text
      ..barcode = _barcode.text
      ..minStock = parseAmount(_min.text) ?? 0
      ..active = _active
      ..dirty = true;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = widget.controller;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.variant.isNew ? l10n.variantAdd : l10n.variantEdit, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _dimension(l10n.model, c.models, _model, (v) => _model = v),
            const SizedBox(height: 8),
            _dimension(l10n.color, c.colors, _color, (v) => _color = v),
            const SizedBox(height: 8),
            _dimension(l10n.size, c.sizes, _size, (v) => _size = v),
            const SizedBox(height: 8),
            NumberField(controller: _price, label: l10n.basePrice, min: 0, suffix: widget.shop.currency),
            const SizedBox(height: 8),
            NumberField(controller: _promo, label: l10n.promoPrice, required: false, min: 0, suffix: widget.shop.currency),
            Row(children: [
              Expanded(child: TextButton(onPressed: () => _pickDate(true), child: Text('${l10n.promoStart}: ${_promoStart == null ? '—' : formatDate(_promoStart!, Localizations.localeOf(context))}'))),
              Expanded(child: TextButton(onPressed: () => _pickDate(false), child: Text('${l10n.promoEnd}: ${_promoEnd == null ? '—' : formatDate(_promoEnd!, Localizations.localeOf(context))}'))),
            ]),
            TextFormField(controller: _sku, decoration: InputDecoration(labelText: l10n.sku)),
            const SizedBox(height: 8),
            TextFormField(controller: _barcode, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l10n.barcode, helperText: l10n.barcodeAutoHint)),
            const SizedBox(height: 8),
            NumberField(controller: _min, label: l10n.stockMinimum, required: false, min: 0),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.active), value: _active, onChanged: (v) => setState(() => _active = v)),
            const SizedBox(height: 8),
            FilledButton(onPressed: _submit, child: Text(l10n.save)),
          ]),
        ),
      ),
    );
  }
}
