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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: haloOpacity),
                    shape: BoxShape.circle,
                  ),
                ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.severity}',
                  style: PulseTheme.data(
                      size: 13, color: PulseColors.pearl, weight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
