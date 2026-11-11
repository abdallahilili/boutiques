import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/util/category_icons.dart';
import '../../core/util/storage_urls.dart';
import '../../l10n/app_localizations.dart';

/// Vignette d'une catégorie : image si elle existe, sinon l'icône choisie, sinon une icône neutre.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, this.imagePath, this.imageBytes, this.iconKey, this.radius = 22});

  /// Chemin de l'image dans le stockage public (`shop-assets`) ou URL absolue.
  final String? imagePath;

  /// Photo choisie mais pas encore envoyée (aperçu local).
  final Uint8List? imageBytes;
  final String? iconKey;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = categoryIconFor(iconKey) ?? Icons.category_outlined;
    final fallback = Icon(icon, size: radius, color: scheme.onPrimaryContainer);
    Widget? photo;
    if (imageBytes != null) {
      photo = Image.memory(imageBytes!, width: radius * 2, height: radius * 2, fit: BoxFit.cover);
    } else if (imagePath != null && imagePath!.isNotEmpty) {
      photo = Image.network(shopAssetUrl(imagePath!), width: radius * 2, height: radius * 2, fit: BoxFit.cover, cacheWidth: (radius * 4).round(), errorBuilder: (_, _, _) => fallback);
    }
    return CircleAvatar(radius: radius, backgroundColor: scheme.primaryContainer, child: photo == null ? fallback : ClipOval(child: photo));
  }
}

/// Valeur du champ : l'image existante (chemin), une nouvelle photo à envoyer, ou une icône de la liste.
class CategoryImageValue {
  const CategoryImageValue({this.imagePath, this.newImage, this.iconKey});

  final String? imagePath;
  final Uint8List? newImage;
  final String? iconKey;

  bool get hasImage => newImage != null || (imagePath != null && imagePath!.isNotEmpty);
}

/// Image de la catégorie : une photo de la galerie ou, à défaut, une icône choisie dans la liste.
/// La photo et l'icône s'excluent : choisir l'une retire l'autre.
class CategoryImageField extends StatelessWidget {
  const CategoryImageField({super.key, required this.value, required this.onChanged});

  final CategoryImageValue value;
  final ValueChanged<CategoryImageValue> onChanged;

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (file == null) return;
    onChanged(CategoryImageValue(newImage: await file.readAsBytes()));
  }

  Future<void> _pickIcon(BuildContext context) async {
    final key = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _IconGrid(selected: value.iconKey),
    );
    if (key != null) onChanged(CategoryImageValue(iconKey: key));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.categoryImage, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Row(children: [
        CategoryAvatar(imagePath: value.imagePath, imageBytes: value.newImage, iconKey: value.iconKey, radius: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(spacing: 8, runSpacing: 4, children: [
            OutlinedButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.photo_outlined), label: Text(l10n.choosePhoto)),
            OutlinedButton.icon(onPressed: () => _pickIcon(context), icon: const Icon(Icons.grid_view_outlined), label: Text(l10n.chooseIcon)),
            if (value.hasImage || value.iconKey != null) TextButton.icon(onPressed: () => onChanged(const CategoryImageValue()), icon: const Icon(Icons.close), label: Text(l10n.removeImage)),
          ]),
        ),
      ]),
      if (!value.hasImage && value.iconKey == null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(l10n.noImageHint, style: Theme.of(context).textTheme.bodySmall)),
    ]);
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.chooseIcon, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Flexible(
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final entry in categoryIcons.entries)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context, entry.key),
                    child: Container(
                      decoration: BoxDecoration(
                        color: entry.key == selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: entry.key == selected ? Border.all(color: scheme.primary, width: 2) : null,
                      ),
                      child: Icon(entry.value, size: 30, color: entry.key == selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
