import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Severity 1-5 pill. Square 24x24 box with mono numeral + adjacent label.
class SeverityPill extends StatefulWidget {
  final int severity;
  final bool withLabel;
  final bool pulse;
  final double size;
  const SeverityPill({
    super.key,
    required this.severity,
    this.withLabel = true,
    this.pulse = false,
    this.size = 24,
  });

  @override
  State<SeverityPill> createState() => _SeverityPillState();
}

class _SeverityPillState extends State<SeverityPill> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = PulseColors.severity(widget.severity);
    final shouldPulse = widget.pulse && widget.severity >= 4;
    final box = AnimatedBuilder(
      animation: _ctl,
      builder: (_, __) {
        final fillAlpha = shouldPulse ? 0.12 + 0.10 * _ctl.value : 0.12;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: fillAlpha),
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(PulseRadii.sm),
          ),
          alignment: Alignment.center,
          child: Text(
            '${widget.severity}',
            style: PulseTheme.data(size: 13, color: color, weight: FontWeight.w700),
          ),
        );
      },
    );
    final labeled = widget.withLabel
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              box,
              const SizedBox(width: PulseSpace.x2),
              Text(
                PulseColors.severityLabel(widget.severity),
                style: PulseTheme.label(color: color),
              ),
            ],
          )
        : box;
    return Semantics(
      label:
          'Severity ${widget.severity} — ${PulseColors.severityLabel(widget.severity)}',
      child: labeled,
    );
  }
}
