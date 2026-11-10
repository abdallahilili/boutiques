import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Code hexadécimal `#RRGGBB` d'une couleur (majuscules).
String colorToHex(Color color) => '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Couleur depuis un code `#RRGGBB`, ou null si le code est invalide.
Color? colorFromHex(String hex) {
  final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex.trim());
  return match == null ? null : Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
}

/// Sélecteur de couleur visuel : carré saturation / luminosité, barre de teinte, pastilles rapides.
/// Aucun code à saisir : on glisse le doigt. [onChanged] est appelé pendant le geste,
/// [onChangeEnd] quand le doigt se relève ou qu'une pastille est choisie.
class ColorPicker extends StatefulWidget {
  const ColorPicker({super.key, required this.color, required this.onChanged, this.onChangeEnd, this.presets = defaultPresets});

  final Color color;
  final ValueChanged<Color> onChanged;
  final ValueChanged<Color>? onChangeEnd;
  final List<Color> presets;

  static const defaultPresets = <Color>[
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF5E35B1),
    Color(0xFF1E88E5),
    Color(0xFF00ACC1),
    Color(0xFF43A047),
    Color(0xFF7CB342),
    Color(0xFFFDD835),
    Color(0xFFFB8C00),
    Color(0xFF6D4C41),
    Color(0xFFD7C4A3),
    Color(0xFF9E9E9E),
    Color(0xFFD4AF37),
  ];

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late HSVColor _hsv = HSVColor.fromColor(widget.color);

  @override
  void didUpdateWidget(ColorPicker old) {
    super.didUpdateWidget(old);
    // Changement venu de l'extérieur : on garde la teinte courante pour les gris (teinte indéfinie).
    if (widget.color.toARGB32() != _hsv.toColor().toARGB32()) _hsv = HSVColor.fromColor(widget.color);
  }

  void _update(HSVColor next, {bool end = false}) {
    setState(() => _hsv = next);
    widget.onChanged(next.toColor());
    if (end) widget.onChangeEnd?.call(next.toColor());
  }

  void _endGesture() => widget.onChangeEnd?.call(_hsv.toColor());

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = _hsv.toColor();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: current, shape: BoxShape.circle, border: Border.all(color: scheme.outline))),
        const SizedBox(width: 12),
        Text(colorToHex(current), textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.titleMedium),
      ]),
      const SizedBox(height: 12),
      // Les gestes se lisent en coordonnées physiques : on fige la direction pour que l'arabe (RTL) ne les inverse pas.
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(children: [
          _Surface(
            height: 180,
            onPick: (x, y) => _update(_hsv.withSaturation(x).withValue(1 - y)),
            onEnd: _endGesture,
            painter: _SaturationValuePainter(_hsv.hue),
            thumbAt: (size) => Offset(_hsv.saturation * size.width, (1 - _hsv.value) * size.height),
            thumbColor: current,
          ),
          const SizedBox(height: 14),
          _Surface(
            height: 28,
            onPick: (x, _) => _update(_hsv.withHue((x * 360).clamp(0, 359.999))),
            onEnd: _endGesture,
            painter: const _HuePainter(),
            thumbAt: (size) => Offset(_hsv.hue / 360 * size.width, size.height / 2),
            thumbColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final preset in widget.presets)
          GestureDetector(
            onTap: () => _update(HSVColor.fromColor(preset), end: true),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: preset,
                shape: BoxShape.circle,
                border: Border.all(color: preset.toARGB32() == current.toARGB32() ? scheme.primary : Colors.black26, width: preset.toARGB32() == current.toARGB32() ? 3 : 1),
              ),
            ),
          ),
      ]),
    ]);
  }
}

/// Zone tactile (carré ou barre) : le doigt choisit une position normalisée (0..1, 0..1).
/// Le geste est capté immédiatement pour ne pas faire défiler la feuille qui contient le sélecteur.
class _Surface extends StatelessWidget {
  const _Surface({required this.height, required this.onPick, required this.onEnd, required this.painter, required this.thumbAt, required this.thumbColor});

  final double height;
  final void Function(double x, double y) onPick;
  final VoidCallback onEnd;
  final CustomPainter painter;
  final Offset Function(Size size) thumbAt;
  final Color thumbColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, height);
      void pick(Offset local) => onPick((local.dx / size.width).clamp(0.0, 1.0), (local.dy / size.height).clamp(0.0, 1.0));
      return RawGestureDetector(
        gestures: {EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(EagerGestureRecognizer.new, (_) {})},
        child: Listener(
          onPointerDown: (e) => pick(e.localPosition),
          onPointerMove: (e) => pick(e.localPosition),
          onPointerUp: (_) => onEnd(),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CustomPaint(painter: painter))),
              Positioned(
                left: thumbAt(size).dx - 13,
                top: thumbAt(size).dy - 13,
                child: IgnorePointer(child: Container(width: 26, height: 26, decoration: BoxDecoration(color: thumbColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black45)]))),
              ),
            ]),
          ),
        ),
      );
    });
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter(this.hue);

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = LinearGradient(colors: [Colors.white, HSVColor.fromAHSV(1, hue, 1, 1).toColor()]).createShader(rect));
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Colors.black]).createShader(rect));
  }

  @override
  bool shouldRepaint(_SaturationValuePainter old) => old.hue != hue;
}

class _HuePainter extends CustomPainter {
  const _HuePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = [for (var h = 0; h <= 360; h += 60) HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor()];
    canvas.drawRect(rect, Paint()..shader = LinearGradient(colors: colors).createShader(rect));
  }

  @override
  bool shouldRepaint(_HuePainter old) => false;
}
