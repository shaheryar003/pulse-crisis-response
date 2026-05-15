import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// Subtle Sindhi-tile inspired background motif painted at low opacity.
/// Used sparingly: empty states, sign-in footer, loading shimmer.
class SindhTile extends StatelessWidget {
  final double opacity;
  final double tileSize;
  const SindhTile({super.key, this.opacity = 0.04, this.tileSize = 28});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(painter: _SindhTilePainter(tileSize), size: Size.infinite),
      ),
    );
  }
}

class _SindhTilePainter extends CustomPainter {
  final double tile;
  _SindhTilePainter(this.tile);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PulseColors.signal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (double y = 0; y < size.height; y += tile) {
      for (double x = 0; x < size.width; x += tile) {
        // 8-point star + center diamond pattern, scaled to tile size.
        final cx = x + tile / 2;
        final cy = y + tile / 2;
        final r = tile / 2 - 2;
        final path = Path();
        for (int i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final rr = i.isEven ? r : r * 0.45;
          final px = cx + math.cos(a) * rr;
          final py = cy + math.sin(a) * rr;
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SindhTilePainter old) => old.tile != tile;
}
