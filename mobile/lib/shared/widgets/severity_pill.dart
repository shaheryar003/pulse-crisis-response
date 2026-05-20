import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Severity 1-5 pill. Square 24x24 box with mono numeral + adjacent label.
/// Tactical Humanitarian redesign: sharp corners, intense glows for sev 4/5.
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
    duration: const Duration(milliseconds: 1500),
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
        final double pulseVal = shouldPulse ? _ctl.value : 0.0;
        final double fillAlpha = shouldPulse ? 0.15 + 0.15 * pulseVal : 0.15;
        
        // Dynamic glow based on severity and pulse
        List<BoxShadow> glow = [];
        if (widget.severity == 5) {
          glow = [
            BoxShadow(color: color.withOpacity(0.40 + 0.30 * pulseVal), blurRadius: 24 + 8 * pulseVal, offset: Offset.zero),
            BoxShadow(color: color.withOpacity(0.20 + 0.20 * pulseVal), blurRadius: 12, spreadRadius: 2 + 2 * pulseVal, offset: Offset.zero),
          ];
        } else if (widget.severity == 4) {
          glow = [
            BoxShadow(color: color.withOpacity(0.25 + 0.20 * pulseVal), blurRadius: 16 + 8 * pulseVal, offset: Offset.zero),
          ];
        } else if (widget.severity >= 2) {
          glow = PulseGlow.severity(widget.severity);
        }

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: color.withOpacity(fillAlpha),
            border: Border.all(color: color.withOpacity(0.8 + 0.2 * pulseVal), width: 1.5),
            borderRadius: BorderRadius.circular(PulseRadii.sm),
            boxShadow: glow,
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
      label: 'Severity ${widget.severity} — ${PulseColors.severityLabel(widget.severity)}',
      child: labeled,
    );
  }
}
