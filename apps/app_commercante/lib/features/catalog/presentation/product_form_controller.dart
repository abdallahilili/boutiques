import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart' hide Value;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/session/shop_controller.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/types/database_types.dart';
import '../../../core/util/format.dart';
import '../../../core/util/image_format.dart';
import '../domain/variant_combinations.dart';

/// Variante en cours d'édition (existante ou à créer).
class VariantDraft {
  VariantDraft({
    required this.id,
    this.modelId,
    this.colorId,
    this.sizeId,
    this.sku = '',
    this.barcode = '',
    this.price = 0,
    this.promoPrice,
    this.promoStart,
    this.promoEnd,
    this.minStock = 0,
    this.active = true,
    this.isNew = true,
  });

  final String id;
  String? modelId;
  String? colorId;
  String? sizeId;
  String sku;
  String barcode;
  double price;
  double? promoPrice;
  DateTime? promoStart;
  DateTime? promoEnd;
  double minStock;
  bool active;
  bool isNew;
  bool dirty = false;

  VariantCombo get combo => VariantCombo(modelId, colorId, sizeId);

  factory VariantDraft.fromJson(Map<String, dynamic> json) => VariantDraft(
        id: json['id'] as String,
        modelId: json['modele_id'] as String?,
        colorId: json['couleur_id'] as String?,
        sizeId: json['taille_id'] as String?,
        sku: (json['sku'] as String?) ?? '',
        barcode: (json['code_barres'] as String?) ?? '',
        price: asDouble(json['prix_vente']),
        promoPrice: json['prix_promo'] == null ? null : asDouble(json['prix_promo']),
        promoStart: json['promo_debut'] == null ? null : DateTime.parse(json['promo_debut'] as String),
        promoEnd: json['promo_fin'] == null ? null : DateTime.parse(json['promo_fin'] as String),
        minStock: asDouble(json['stock_minimum']),
        active: json['actif'] as bool,
        isNew: false,
      );

  Map<String, dynamic> toJson(String shopId, String productId, {String? userId}) => {
        'id': id,
        'boutique_id': shopId,
        'produit_id': productId,
        'modele_id': modelId,
        'couleur_id': colorId,
        'taille_id': sizeId,
        'sku': sku.trim().isEmpty ? null : sku.trim(),
        'code_barres': barcode.trim().isEmpty ? null : barcode.trim(),
        'prix_vente': price,
        'prix_promo': promoPrice,
        'promo_debut': promoStart?.toUtc().toIso8601String(),
        'promo_fin': promoEnd?.toUtc().toIso8601String(),
        'stock_minimum': minStock,
        'actif': active,
        if (isNew && userId != null) 'cree_par': userId,
      };
}

class PickedImage {
  PickedImage(this.name, this.bytes);
  final String name;
  final Uint8List bytes;

  ImageFormat get format => sniffImageFormat(bytes);
}

/// Le produit est enregistré mais l'envoi d'une photo a échoué : on peut réessayer sans rien dupliquer.
class ProductImageException implements Exception {
  ProductImageException(this.cause);
  final Object cause;

  String get message => cause is StorageException ? (cause as StorageException).message : '$cause';

  @override
  String toString() => message;
}

/// Création / modification d'un produit et de ses variantes (connexion requise).
class ProductFormController extends GetxController {
  ProductFormController(this._client, this._shop, this._sync, this.productId);

  final SupabaseClient _client;
  final ShopController _shop;
  final SyncService _sync;
  final String? productId;

  late final String id = productId ?? const Uuid().v4();
  bool get isNew => productId == null;

  /// Vrai dès que la ligne produit existe en base : une nouvelle tentative d'enregistrement
  /// (après un échec sur les variantes ou les photos) met à jour au lieu de réinsérer.
  late bool _productSaved = productId != null;

  final nameAr = TextEditingController();
  final nameFr = TextEditingController();
  final descriptionAr = TextEditingController();
  final descriptionFr = TextEditingController();
  final tags = TextEditingController();
  final categoryId = RxnString();
  final brandId = RxnString();
  final unitId = RxnString();
  final visibleOnline = true.obs;
  final active = true.obs;

  final variants = <VariantDraft>[].obs;
  final existingImages = <Map<String, dynamic>>[].obs;
  final newImages = <PickedImage>[].obs;

  final categories = <Map<String, dynamic>>[].obs;
  final brands = <Map<String, dynamic>>[].obs;
  final units = <Map<String, dynamic>>[].obs;
  final models = <Map<String, dynamic>>[].obs;
  final colors = <Map<String, dynamic>>[].obs;
  final sizes = <Map<String, dynamic>>[].obs;

  final loading = true.obs;
  final saving = false.obs;
  final error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    for (final c in [nameAr, nameFr, descriptionAr, descriptionFr, tags]) {
      c.dispose();
    }
    super.onClose();
  }

  Future<List<Map<String, dynamic>>> _list(String table, {bool onlyActive = true, String order = 'nom_fr'}) async {
    var q = _client.from(table).select().eq('boutique_id', _shop.shopId);
    if (onlyActive) q = q.eq('actif', true);
    return q.order(order);
  }

  Future<void> loadReferentials() async {
    final results = await Future.wait([
      _list(Tables.categories, order: 'ordre'),
      _list(Tables.marques),
      _list(Tables.unites),
      _list(Tables.modeles),
      _list(Tables.couleurs, order: 'ordre'),
      _list(Tables.tailles, order: 'ordre'),
    ]);
    categories.assignAll(results[0]);
    brands.assignAll(results[1]);
    units.assignAll(results[2]);
    models.assignAll(results[3]);
    colors.assignAll(results[4]);
    sizes.assignAll(results[5]);
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      await loadReferentials();
      if (!isNew) {
        final p = await _client.from(Tables.produits).select().eq('id', id).single();
        nameAr.text = (p['nom_ar'] as String?) ?? '';
        nameFr.text = (p['nom_fr'] as String?) ?? '';
        descriptionAr.text = (p['description_ar'] as String?) ?? '';
        descriptionFr.text = (p['description_fr'] as String?) ?? '';
        tags.text = ((p['etiquettes'] as List?) ?? const []).join(', ');
        categoryId.value = p['categorie_id'] as String?;
        brandId.value = p['marque_id'] as String?;
        unitId.value = p['unite_id'] as String?;
        visibleOnline.value = p['visible_en_ligne'] as bool;
        active.value = p['statut'] == 'actif';
        final vs = await _client.from(Tables.variantesProduit).select().eq('produit_id', id).isFilter('supprime_le', null).order('cree_le');
        variants.assignAll(vs.map(VariantDraft.fromJson));
        existingImages.assignAll(await _client.from(Tables.imagesProduit).select().eq('produit_id', id).order('principale', ascending: false).order('ordre'));
      }
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> pickImages() async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 80, maxWidth: 1600);
    for (final f in files) {
      newImages.add(PickedImage(f.name, await f.readAsBytes()));
    }
  }

  /// Variantes manquantes pour les dimensions choisies (modèles × couleurs × tailles) au prix donné.
  List<VariantCombo> previewCombinations(Set<String> modelIds, Set<String> colorIds, Set<String> sizeIds) =>
      missingCombinations(generateCombinations(models: modelIds, colors: colorIds, sizes: sizeIds), variants.map((v) => v.combo));

  void generateVariants(Set<String> modelIds, Set<String> colorIds, Set<String> sizeIds, double price) {
    for (final combo in previewCombinations(modelIds, colorIds, sizeIds)) {
      variants.add(VariantDraft(id: const Uuid().v4(), modelId: combo.modelId, colorId: combo.colorId, sizeId: combo.sizeId, price: price));
    }
  }

  bool comboExists(VariantCombo combo, {String? exceptId}) => variants.any((v) => v.id != exceptId && v.combo == combo);

  Future<void> save() async {
    saving.value = true;
    try {
      final etiquettes = tags.text.split(RegExp('[,،]')).map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      final values = {
        'nom_ar': nameAr.text.trim().isEmpty ? null : nameAr.text.trim(),
        'nom_fr': nameFr.text.trim().isEmpty ? null : nameFr.text.trim(),
        'description_ar': descriptionAr.text.trim().isEmpty ? null : descriptionAr.text.trim(),
        'description_fr': descriptionFr.text.trim().isEmpty ? null : descriptionFr.text.trim(),
        'categorie_id': categoryId.value,
        'marque_id': brandId.value,
        'unite_id': unitId.value,
        'visible_en_ligne': visibleOnline.value,
        'statut': active.value ? 'actif' : 'inactif',
        'etiquettes': etiquettes,
      };
      if (_productSaved) {
        await _client.from(Tables.produits).update(values).eq('id', id);
      } else {
        await _client.from(Tables.produits).insert({...values, 'id': id, 'boutique_id': _shop.shopId, 'cree_par': _shop.userId});
        _productSaved = true;
      }

      final created = variants.where((v) => v.isNew).toList();
      if (created.isNotEmpty) {
        await _client.from(Tables.variantesProduit).insert([for (final v in created) v.toJson(_shop.shopId, id, userId: _shop.userId)]);
        for (final v in created) {
          v
            ..isNew = false
            ..dirty = false;
        }
      }
      for (final v in variants.where((v) => !v.isNew && v.dirty)) {
        final json = v.toJson(_shop.shopId, id)..remove('id')..remove('boutique_id')..remove('produit_id');
        await _client.from(Tables.variantesProduit).update(json).eq('id', v.id);
        v.dirty = false;
      }

      await _uploadNewImages();
      await _sync.syncAll();
    } finally {
      saving.value = false;
    }
  }

  /// Envoie les photos une à une : chaque photo réussie est retirée de la file, une photo en échec reste en attente.
  Future<void> _uploadNewImages() async {
    for (final image in List<PickedImage>.of(newImages)) {
      try {
        final format = image.format;
        final path = '${_shop.shopId}/$id/${const Uuid().v4()}.${format.extension}';
        await _client.storage.from('product-images').uploadBinary(path, image.bytes, fileOptions: FileOptions(contentType: format.mime));
        final row = await _client.from(Tables.imagesProduit).insert({
          'boutique_id': _shop.shopId,
          'produit_id': id,
          'url': path,
          'principale': existingImages.isEmpty,
          'ordre': existingImages.length,
        }).select().single();
        existingImages.add(row);
        newImages.remove(image);
      } catch (e) {
        throw ProductImageException(e);
      }
    }
  }

  Future<void> archive() async {
    await _client.from(Tables.produits).update({'supprime_le': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
    await _sync.syncAll();
  }

  Future<void> deactivateVariant(VariantDraft variant) async {
    variant
      ..active = false
      ..dirty = true;
    variants.refresh();
  }

  Future<void> removeImage(Map<String, dynamic> image) async {
    await _client.from(Tables.imagesProduit).delete().eq('id', image['id'] as String);
    existingImages.remove(image);
    final path = image['url'] as String;
    if (!path.startsWith('http')) {
      try {
        await _client.storage.from('product-images').remove([path]);
      } catch (_) {
        // Fichier orphelin sans conséquence : la ligne d'image est déjà supprimée.
      }
    }
  }
}
