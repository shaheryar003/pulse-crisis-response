import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import '../tokens.dart';

/// Three-row p10 / p50 / p90 uncertainty band for Tier-4 forecast data.
/// Renders a proportional bar showing the Monte Carlo spread.
class ForecastBands extends StatelessWidget {
  final int p10;
  final int p50;
  final int p90;
  final String locale;
  const ForecastBands({
    super.key,
    required this.p10,
    required this.p50,
    required this.p90,
    this.locale = PulseStrings.en,
  });

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final max = p90.clamp(1, 1 << 30).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PulseSpace.x3,
        vertical: PulseSpace.x2,
      ),
      decoration: BoxDecoration(
        color: PulseColors.ink900.withValues(alpha: 0.6),
        border: Border.all(color: PulseColors.hairline),
        borderRadius: BorderRadius.circular(PulseRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            PulseStrings.get('forecast.population', locale).toUpperCase(),
            style: PulseTheme.label(),
          ),
          const SizedBox(height: PulseSpace.x2),
          _BandRow(
            label: PulseStrings.get('forecast.p10', locale),
            value: p10,
            fraction: p10 / max,
            color: PulseColors.mist,
            formatted: _fmt(p10),
          ),
          const SizedBox(height: PulseSpace.x1),
          _BandRow(
            label: PulseStrings.get('forecast.p50', locale),
            value: p50,
            fraction: p50 / max,
            color: PulseColors.signal,
            formatted: _fmt(p50),
          ),
          const SizedBox(height: PulseSpace.x1),
          _BandRow(
            label: PulseStrings.get('forecast.p90', locale),
            value: p90,
            fraction: 1.0,
            color: PulseColors.amber,
            formatted: _fmt(p90),
          ),
        ],
      ),
    );
  }
}

class _BandRow extends StatelessWidget {
  final String label;
  final int value;
  final double fraction;
  final Color color;
  final String formatted;
  const _BandRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
    required this.formatted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(label, style: PulseTheme.dataXs(color: color)),
        ),
        const SizedBox(width: PulseSpace.x2),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(PulseRadii.xs),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (fraction * 100).round().clamp(1, 100),
                    child: Container(color: color.withValues(alpha: 0.6)),
                  ),
                  if (fraction < 1.0)
                    Expanded(
                      flex: ((1.0 - fraction) * 100).round().clamp(0, 99),
                      child:
                          Container(color: PulseColors.ash.withValues(alpha: 0.3)),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: PulseSpace.x2),
        SizedBox(
          width: 40,
          child: Text(
            formatted,
            style: PulseTheme.data(size: 11, color: color),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
