import 'package:flutter/material.dart';

import '../tokens.dart';

/// 10-cell sparkbar — fills cells proportional to value (0.0-1.0).
class Sparkbar extends StatelessWidget {
  final double value;
  final Color filledColor;
  final Color emptyColor;
  final int cells;
  final double cellWidth;
  final double height;
  const Sparkbar({
    super.key,
    required this.value,
    this.filledColor = PulseColors.signal,
    this.emptyColor = PulseColors.ash,
    this.cells = 10,
    this.cellWidth = 5,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final filled = (v * cells).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(cells, (i) {
        final isFilled = i < filled;
        return Padding(
          padding: EdgeInsets.only(right: i == cells - 1 ? 0 : 1),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200 + (i * 24)),
            width: cellWidth,
            height: height,
            decoration: BoxDecoration(
              color: isFilled ? filledColor : emptyColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
        );
      }),
    );
  }
}
