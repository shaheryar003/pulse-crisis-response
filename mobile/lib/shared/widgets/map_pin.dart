import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Round map pin with severity color + monospace numeral + pulsing halo for sev 4+.
class MapPin extends StatefulWidget {
  final int severity;
  final bool active;
  final String? zone;
  const MapPin({super.key, required this.severity, this.active = true, this.zone});
  @override
  State<MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<MapPin> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    if (widget.severity >= 4 && widget.active) _ctl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = PulseColors.severity(widget.severity);
    final sevLabel = PulseColors.severityLabel(widget.severity);
    final zoneStr = widget.zone != null ? ' in ${widget.zone}' : '';
    final stateStr = widget.active ? 'active' : 'inactive';
    return Semantics(
      label: 'Severity ${widget.severity} $sevLabel incident$zoneStr, $stateStr',
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (_, __) {
          final haloOpacity = 0.04 + 0.12 * _ctl.value;
          
          List<BoxShadow> glow = [];
          if (widget.active) {
            if (widget.severity == 5) {
              glow = [
                BoxShadow(color: color.withValues(alpha: 0.60 + 0.20 * _ctl.value), blurRadius: 32 + 16 * _ctl.value),
              ];
            } else if (widget.severity == 4) {
              glow = [
                BoxShadow(color: color.withValues(alpha: 0.35 + 0.15 * _ctl.value), blurRadius: 24 + 8 * _ctl.value),
              ];
            } else if (widget.severity >= 2) {
              glow = PulseGlow.severity(widget.severity);
            }
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.severity >= 4 && widget.active)
                Container(
                  width: 56 + 16 * _ctl.value,
                  height: 56 + 16 * _ctl.value,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: haloOpacity),
                    shape: BoxShape.circle,
                  ),
                ),
              Transform.translate(
                offset: const Offset(0, -12),
                child: Transform.rotate(
                  angle: 3.14159 / 4, // 45 degrees
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(2),
                      ),
                      boxShadow: glow,
                      border: Border.all(color: PulseColors.ink900.withValues(alpha: 0.6), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Transform.rotate(
                      angle: -3.14159 / 4, // Un-rotate text
                      child: Text(
                        '${widget.severity}',
                        style: PulseTheme.data(
                            size: 15, color: PulseColors.ink900, weight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
