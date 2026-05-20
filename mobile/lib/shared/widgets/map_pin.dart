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
          final haloOpacity = 0.04 + 0.08 * _ctl.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.severity >= 4 && widget.active)
                Container(
                  width: 56,
                  height: 56,
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
                      color: color.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        )
                      ],
                      border: Border.all(color: PulseColors.pearl.withValues(alpha: 0.8), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Transform.rotate(
                      angle: -3.14159 / 4, // Un-rotate text
                      child: Text(
                        '${widget.severity}',
                        style: PulseTheme.data(
                            size: 14, color: PulseColors.ink900, weight: FontWeight.w800),
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
