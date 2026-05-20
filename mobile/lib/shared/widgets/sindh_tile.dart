import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../tokens.dart';

/// Subtle Sindhi-tile inspired background motif painted at low opacity.
/// Tactical Humanitarian redesign: A single massive star motif.
class SindhTile extends StatelessWidget {
  final double opacity;
  final double size;
  const SindhTile({super.key, this.opacity = 0.03, this.size = 800});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _SindhTilePainter(size)),
        ),
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
      ..strokeWidth = 2.0;
      
    // 8-point star, single large motif spanning the area
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2 - 4;
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
    
    // Draw an inner diamond
    final path2 = Path();
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final px = cx + math.cos(a) * (r * 0.3);
      final py = cy + math.sin(a) * (r * 0.3);
      if (i == 0) {
        path2.moveTo(px, py);
      } else {
        path2.lineTo(px, py);
      }
    }
    path2.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(_SindhTilePainter old) => old.tile != tile;
}
