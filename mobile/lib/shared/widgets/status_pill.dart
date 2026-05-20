import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Tactical Humanitarian StatusPill.
/// Sharp corners (2px radius), left-side color bar indicator, ALL CAPS label.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool dense;
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.dense = false,
  });

  factory StatusPill.priority(String p) {
    final c = switch (p.toLowerCase()) {
      'urgent' => PulseColors.crimson,
      'high' => PulseColors.amber,
      'normal' => PulseColors.signal,
      _ => PulseColors.dim,
    };
    return StatusPill(label: p.toUpperCase(), color: c);
  }

  factory StatusPill.dispatchStatus(String s) {
    final c = switch (s.toLowerCase()) {
      'issued' => PulseColors.amber,
      'acked' => PulseColors.signal,
      'en_route' => PulseColors.signal,
      'on_scene' => PulseColors.lime,
      'clear' => PulseColors.lime,
      'recalled' => PulseColors.dim,
      _ => PulseColors.stone,
    };
    return StatusPill(label: s.replaceAll('_', ' ').toUpperCase(), color: c);
  }

  factory StatusPill.alertStatus(String s) {
    final c = switch (s.toLowerCase()) {
      'sent' => PulseColors.signal,
      'staged' => PulseColors.amber,
      'retracted' => PulseColors.dim,
      _ => PulseColors.stone,
    };
    return StatusPill(label: s.toUpperCase(), color: c);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(PulseRadii.sm),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
            width: 3,
            color: color,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? PulseSpace.x2 : 7.0,
              vertical: dense ? 2 : 4,
            ),
            child: Center(
              child: Text(
                label,
                style: PulseTheme.label(color: color).copyWith(
                  fontSize: dense ? 9 : 10,
                  letterSpacing: 0.09,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
