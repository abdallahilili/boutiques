import 'dart:typed_data';

/// Impression thermique par image (raster) : le reçu est dessiné en bitmap puis envoyé en commandes ESC/POS.
/// Aucune page de codes de l'imprimante n'est utilisée, donc l'arabe et le français s'impriment sur n'importe
/// quel modèle (58 mm = 384 points, 80 mm = 576 points).

/// Largeur en points d'un papier thermique : 58 mm → 384, 80 mm → 576.
int dotsForPaper(int millimeters) => millimeters >= 80 ? 576 : 384;

/// Convertit une image RGBA en bitmap 1 bit (8 points par octet, bit de poids fort à gauche, 1 = noir).
/// Les pixels transparents sont blancs ; [threshold] sépare noir et blanc sur la luminance.
Uint8List rgbaToMonochrome(Uint8List rgba, int width, int height, {int threshold = 160}) {
  if (rgba.length < width * height * 4) throw ArgumentError('Image RGBA trop courte pour ${width}x$height');
  final stride = (width + 7) ~/ 8;
  final out = Uint8List(stride * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final alpha = rgba[i + 3] / 255;
      // Composition sur fond blanc puis luminance perceptuelle.
      final r = rgba[i] * alpha + 255 * (1 - alpha);
      final g = rgba[i + 1] * alpha + 255 * (1 - alpha);
      final b = rgba[i + 2] * alpha + 255 * (1 - alpha);
      final luminance = 0.299 * r + 0.587 * g + 0.114 * b;
      if (luminance < threshold) out[y * stride + (x >> 3)] |= 0x80 >> (x & 7);
    }
  }
  return out;
}

/// Commandes ESC/POS d'un travail d'impression raster : initialisation, image par bandes (certaines
/// imprimantes plafonnent la hauteur d'un bloc), avance papier puis coupe partielle facultative.
Uint8List escPosRasterJob(Uint8List monochrome, int width, int height, {int feedLines = 4, bool cut = true, int bandHeight = 128}) {
  final stride = (width + 7) ~/ 8;
  if (monochrome.length != stride * height) throw ArgumentError('Bitmap de taille inattendue');
  final bytes = BytesBuilder();
  bytes.add([0x1B, 0x40]); // ESC @ : initialisation
  for (var top = 0; top < height; top += bandHeight) {
    final rows = (top + bandHeight > height) ? height - top : bandHeight;
    bytes.add([0x1D, 0x76, 0x30, 0x00, stride & 0xFF, stride >> 8, rows & 0xFF, rows >> 8]); // GS v 0 : image raster
    bytes.add(monochrome.sublist(top * stride, (top + rows) * stride));
  }
  if (feedLines > 0) bytes.add([0x1B, 0x64, feedLines]); // ESC d n : avance de n lignes
  if (cut) bytes.add([0x1D, 0x56, 0x42, 0x00]); // GS V B 0 : coupe partielle après avance
  return bytes.toBytes();
}
