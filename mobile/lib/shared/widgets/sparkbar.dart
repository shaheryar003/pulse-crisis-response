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
    this.emptyColor = PulseColors.hairlineStrong,
    this.cells = 10,
    this.cellWidth = 6,
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
          padding: EdgeInsets.only(right: i == cells - 1 ? 0 : 2),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200 + (i * 24)),
            width: cellWidth,
            height: height,
            decoration: BoxDecoration(
              color: isFilled ? filledColor : emptyColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(PulseRadii.xs),
              boxShadow: isFilled && filledColor == PulseColors.crimson
                  ? [BoxShadow(color: PulseColors.crimson.withValues(alpha: 0.5), blurRadius: 4)]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
