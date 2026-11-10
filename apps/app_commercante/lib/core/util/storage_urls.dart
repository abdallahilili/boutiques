import '../config/env.dart';

/// URL publique d'un fichier des buckets publics (`product-images`, `shop-assets`).
/// Fichier servi tel quel, sans transformation d'image : fonctionne sur tous les plans Supabase
/// (les images sont réduites à l'envoi, avant d'être stockées).
String _publicUrl(String bucket, String path) => path.startsWith('http') ? path : '${Env.supabaseUrl}/storage/v1/object/public/$bucket/$path';

String productImageUrl(String path) => _publicUrl('product-images', path);

String shopAssetUrl(String path) => _publicUrl('shop-assets', path);
