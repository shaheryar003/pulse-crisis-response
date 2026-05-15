import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Label · · · · · value. The dot leader between is a CustomPaint of mono dots.
class DotLeader extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;
  const DotLeader({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(label.toUpperCase(), style: PulseTheme.label()),
          const SizedBox(width: PulseSpace.x2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: CustomPaint(
                size: const Size(double.infinity, 1),
                painter: _DotLeaderPainter(),
              ),
            ),
          ),
          const SizedBox(width: PulseSpace.x2),
          Text(value, style: valueStyle ?? PulseTheme.data(size: 12, color: valueColor ?? PulseColors.pearl)),
        ],
      ),
    );
  }
}

class _DotLeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = PulseColors.ash;
    const dotR = 0.7;
    const spacing = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawCircle(Offset(x, size.height / 2), dotR, paint);
      x += spacing;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
