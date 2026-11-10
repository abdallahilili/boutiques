import 'dart:convert';
import 'dart:typed_data';

import 'package:app_commercante/core/db/app_database.dart';
import 'package:app_commercante/core/session/shop_controller.dart';
import 'package:app_commercante/core/sync/sync_service.dart';
import 'package:app_commercante/features/catalog/presentation/product_form_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeConnectivity implements Connectivity {
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => const Stream.empty();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];
}

class _TestShop extends ShopController {
  _TestShop(super.client, super.db);

  @override
  String get shopId => 'shop-1';

  @override
  String get userId => 'user-1';
}

class _TestSync extends SyncService {
  _TestSync(super.client, super.db, super.shop) : super(connectivity: _FakeConnectivity());

  @override
  Future<void> syncAll() async {}
}

/// Réponses HTTP simulées de Supabase ; l'envoi de photo échoue tant que [storageFails] est vrai.
class _Backend {
  bool storageFails = true;
  final requests = <String>[];

  int count(String method, String pathPart) => requests.where((r) => r.startsWith('$method ') && r.contains(pathPart)).length;

  Future<http.Response> handle(http.Request request) async {
    requests.add('${request.method} ${request.url.path}');
    final path = request.url.path;
    const json = {'content-type': 'application/json'};
    if (path.startsWith('/storage/v1/object/')) {
      return storageFails
          ? http.Response(jsonEncode({'statusCode': '400', 'error': 'Bad Request', 'message': 'mime type not supported'}), 400, headers: json, request: request)
          : http.Response(jsonEncode({'Key': 'product-images/shop-1/p/photo.jpg'}), 200, headers: json, request: request);
    }
    if (path == '/rest/v1/images_produit') {
      return http.Response(jsonEncode({'id': 'img-${requests.length}', 'url': 'shop-1/p/photo.jpg', 'principale': true, 'ordre': 0}), 201, headers: json, request: request);
    }
    if (request.method == 'GET') return http.Response('[]', 200, headers: json, request: request);
    return http.Response('', request.method == 'POST' ? 201 : 204, request: request);
  }
}

void main() {
  late AppDatabase db;
  late _Backend backend;
  late ProductFormController controller;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    backend = _Backend();
    final client = SupabaseClient('http://localhost:54321', 'cle-publique-de-test', httpClient: MockClient(backend.handle));
    final shop = _TestShop(client, db);
    controller = ProductFormController(client, shop, _TestSync(client, db, shop), null);
    controller.nameFr.text = 'Sac';
    controller.variants.add(VariantDraft(id: 'v1', price: 1000));
    controller.newImages.add(PickedImage('photo.jpg', Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3])));
  });
  tearDown(() => db.close());

  test('échec de la photo puis nouvel essai : le produit n\'est pas réinséré (plus de « produits_pkey »)', () async {
    await expectLater(controller.save(), throwsA(isA<ProductImageException>()));
    expect(backend.count('POST', '/rest/v1/produits'), 1);
    expect(backend.count('POST', '/rest/v1/variantes_produit'), 1);
    expect(controller.newImages, hasLength(1), reason: 'la photo en échec reste en attente');

    backend.storageFails = false;
    await controller.save();

    expect(backend.count('POST', '/rest/v1/produits'), 1, reason: 'aucune seconde insertion du produit');
    expect(backend.count('PATCH', '/rest/v1/produits'), 1, reason: 'le second enregistrement met à jour');
    expect(backend.count('POST', '/rest/v1/variantes_produit'), 1, reason: 'la variante déjà créée n\'est pas renvoyée');
    expect(backend.count('POST', '/rest/v1/images_produit'), 1);
    expect(controller.newImages, isEmpty);
    expect(controller.existingImages, hasLength(1));
  });

  test('sans photo en échec, l\'enregistrement insère le produit une seule fois', () async {
    backend.storageFails = false;
    await controller.save();
    expect(backend.count('POST', '/rest/v1/produits'), 1);
    expect(controller.variants.single.isNew, isFalse);
  });

  test('le format de la photo est déterminé par son contenu, pas par son nom', () {
    expect(PickedImage('x.heic', Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0])).format.mime, 'image/png');
    expect(PickedImage('x.png', Uint8List.fromList([0xFF, 0xD8, 0xFF, 0])).format.mime, 'image/jpeg');
    expect(PickedImage('x', Uint8List.fromList([0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50])).format.extension, 'webp');
  });
}
