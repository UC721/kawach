import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// An immersive, slowly-drifting aurora background rendered with a custom
/// painter and a subtle breathing animation. Use as the bottom layer of any
/// Scaffold body Stack to add depth and a "living" feel.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    super.key,
    this.colors = const [
      Color(0xFFFF8A80),
      Color(0xFFB39DDB),
      Color(0xFF80DEEA),
      Color(0xFFFFF176),
    ],
    this.child,
    this.dark = false,
  });

  /// Palette used for the glowing orbs. Transparent radial falloff is applied
  /// automatically, so you can pass vivid, opaque colours.
  final List<Color> colors;

  /// Optional content placed on top of the ambient field.
  final Widget? child;

  /// When true, orbs are dimmer and cooler (for overlay-friendly surfaces).
  final bool dark;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16000),
    )..repeat();
    _breath = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final orbit = math.pi * 2 * t;
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _AuroraPainter(
                colors: widget.colors,
                orbit: orbit,
                breath: _breath.value,
                dark: widget.dark,
              ),
            ),
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.colors,
    required this.orbit,
    required this.breath,
    required this.dark,
  });

  final List<Color> colors;
  final double orbit;
  final double breath;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Base wash so surfaces tint toward the palette.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dark ? const Color(0xFF14141F) : const Color(0xFFFFF6F6),
            dark ? const Color(0xFF0E0E16) : const Color(0xFFF6F0FF),
          ],
        ).createShader(rect),
    );

    final maxDim = math.max(size.width, size.height);
    // Three drifting, breathing orbs for parallax depth.
    for (var i = 0; i < 3; i++) {
      final color = colors[(i + 1) % colors.length];
      final cx = size.width *
          (0.25 +
              0.5 * (0.5 + 0.5 * math.sin(orbit * (1.0 + i * 0.21) + i * 2.1)));
      final cy = size.height *
          (0.25 +
              0.5 * (0.5 + 0.5 * math.cos(orbit * (0.8 + i * 0.17) + i * 1.7)));
      final r = maxDim * (0.35 + 0.14 * i) * (0.85 + 0.15 * breath);

      final alpha = dark ? 26 : 60;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha / 255),
              color.withValues(alpha: alpha / 600),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.orbit != orbit ||
      oldDelegate.breath != breath ||
      oldDelegate.colors != colors;
}

/// A frosted-glass panel: translucent surface, soft blur of whatever is
/// behind, a 1px highlight border and a gentle drop shadow. Drop it on top
/// of [AmbientBackground] (or any busy background) for a premium look.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
    this.color = const Color(0xE6FFFFFF),
    this.child,
    this.shadow,
  });

  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Widget? child;
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1,
            ),
            boxShadow: [
              shadow ??
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A card that tilts in 3D as you drag across it (perspective projection),
/// then springs back. Great for making "touchable" surfaces feel physical.
class TiltCard extends StatefulWidget {
  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 0.16,
    this.onTap,
    this.borderRadius = 24,
    this.elevation = 18,
  });

  final Widget child;
  final double maxTilt;
  final VoidCallback? onTap;
  final double borderRadius;
  final double elevation;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _rx = 0;
  double _ry = 0;

  void _onPanUpdate(DragUpdateDetails d) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final size = box.size;
    // Normalise pointer to [-1, 1] around centre.
    final dx = (d.localPosition.dx / size.width - 0.5) * 2;
    final dy = (d.localPosition.dy / size.height - 0.5) * 2;
    setState(() {
      _rx = (-dy * widget.maxTilt).clamp(-1.0, 1.0);
      _ry = (dx * widget.maxTilt).clamp(-1.0, 1.0);
    });
  }

  void _reset() {
    if (_rx == 0 && _ry == 0) return;
    setState(() {
      _rx = 0;
      _ry = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Perspective projection: divide by a focal length so the card recedes.
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0016)
      ..rotateX(_rx)
      ..rotateY(_ry);
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: (_) => _reset(),
      onTap: widget.onTap,
      child: Transform(
        alignment: Alignment.center,
        transform: matrix,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: widget.elevation,
                offset: Offset(0, widget.elevation * 0.45),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
