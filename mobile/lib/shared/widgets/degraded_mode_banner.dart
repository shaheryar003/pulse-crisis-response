import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import '../tokens.dart';
import 'status_pill.dart';

/// Sticky amber banner that surfaces degraded-mode signals from Tier-1.
///
/// Appears when stale_minutes > 0 (weather cache) or a sensor:silent artifact
/// arrives via the /trace WebSocket. Scenario D is the canonical test case.
class DegradedSignal {
  final String source;
  final int? staleMinutes;
  final bool sensorSilent;
  final String? sensorId;

  const DegradedSignal({
    required this.source,
    this.staleMinutes,
    this.sensorSilent = false,
    this.sensorId,
  });
}

class DegradedModeBanner extends StatelessWidget {
  final List<DegradedSignal> signals;
  final ValueChanged<DegradedSignal> onDismiss;
  final String locale;

  const DegradedModeBanner({
    super.key,
    required this.signals,
    required this.onDismiss,
    this.locale = PulseStrings.en,
  });

  @override
  Widget build(BuildContext context) {
    if (signals.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: signals.map((s) => _BannerRow(
        signal: s,
        onDismiss: () => onDismiss(s),
        locale: locale,
      )).toList(),
    );
  }
}

class _BannerRow extends StatelessWidget {
  final DegradedSignal signal;
  final VoidCallback onDismiss;
  final String locale;
  const _BannerRow({
    required this.signal,
    required this.onDismiss,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final label = signal.sensorSilent
        ? PulseStrings.get('degraded.banner.sensor_silent', locale)
        : PulseStrings.get('degraded.banner.title', locale);

    final detail = signal.sensorSilent
        ? (signal.sensorId ?? signal.source)
        : signal.staleMinutes != null
            ? '${signal.source} · ${signal.staleMinutes} ${PulseStrings.get('degraded.banner.minutes', locale)} ${PulseStrings.get('degraded.banner.stale', locale)}'
            : signal.source;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          PulseSpace.x4, PulseSpace.x2, PulseSpace.x2, PulseSpace.x2),
      decoration: const BoxDecoration(
        color: PulseColors.ink900,
        border: Border(
          left: BorderSide(color: PulseColors.amber, width: 3),
          bottom: BorderSide(color: PulseColors.hairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          StatusPill(label: label, color: PulseColors.amber, dense: true),
          const SizedBox(width: PulseSpace.x3),
          Expanded(
            child: Text(detail, style: PulseTheme.dataXs()),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(PulseRadii.sm),
            child: Padding(
              padding: const EdgeInsets.all(PulseSpace.x2),
              child: Text(
                '×',
                style: PulseTheme.data(
                    size: 14, color: PulseColors.mist, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
