import 'dart:typed_data';

/// Format d'image reconnu d'après les premiers octets : le nom du fichier choisi dans la galerie n'est pas fiable,
/// et les buckets n'acceptent que JPEG, PNG et WebP.
typedef ImageFormat = ({String extension, String mime});

ImageFormat sniffImageFormat(Uint8List bytes) {
  final b = bytes;
  if (b.length > 3 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return (extension: 'png', mime: 'image/png');
  if (b.length > 11 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) return (extension: 'webp', mime: 'image/webp');
  return (extension: 'jpg', mime: 'image/jpeg');
}
