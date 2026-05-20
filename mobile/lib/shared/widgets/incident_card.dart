import 'package:flutter/material.dart';

import '../../models/incident.dart';
import '../strings.dart';
import '../theme.dart';
import '../tokens.dart';
import 'dot_leader.dart';
import 'forecast_bands.dart';
import 'severity_pill.dart';
import 'sparkbar.dart';
import 'status_pill.dart';

class IncidentCard extends StatelessWidget {
  final Incident incident;
  final String? timestamp;
  final bool dense;
  final VoidCallback? onTap;
  final bool selected;
  final String locale;
  const IncidentCard({
    super.key,
    required this.incident,
    this.timestamp,
    this.dense = false,
    this.onTap,
    this.selected = false,
    this.locale = PulseStrings.en,
  });

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k';
    return '$n';
  }

  String _statusFooter(Incident i) {
    if (i.status == 'retracted') return 'retracted · audit logged';
    return 'tracking · responders dispatched';
  }

  @override
  Widget build(BuildContext context) {
    final retracted = incident.status == 'retracted';
    final color = retracted ? PulseColors.dim : PulseColors.severity(incident.severity);
    final typeLabel = incident.type.replaceAll('_', ' ').toUpperCase();
    final idShort = incident.id.length > 10 ? incident.id.substring(0, 10) : incident.id;

    final inner = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: PulseSpace.x2),
      decoration: BoxDecoration(
        color: PulseColors.ink800,
        borderRadius: BorderRadius.circular(PulseRadii.xxl),
        border: Border(
          left: BorderSide(color: selected ? color : PulseColors.hairlineStrong, width: selected ? 4 : 1),
          top: BorderSide(color: selected ? color.withValues(alpha: 0.5) : PulseColors.hairlineStrong, width: 1),
          right: BorderSide(color: selected ? color.withValues(alpha: 0.5) : PulseColors.hairlineStrong, width: 1),
          bottom: BorderSide(color: selected ? color.withValues(alpha: 0.5) : PulseColors.hairlineStrong, width: 1),
        ),
        boxShadow: selected
            ? PulseGlow.severity(incident.severity)
            : const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(PulseSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SeverityPill(severity: incident.severity, withLabel: false, pulse: !retracted && selected),
              const SizedBox(width: PulseSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: PulseTheme.label(color: PulseColors.pearl).copyWith(
                        fontSize: 12,
                        decoration: retracted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(children: [
                      Text(incident.zone, style: PulseTheme.dataSm(color: PulseColors.stone)),
                      const SizedBox(width: PulseSpace.x2),
                      Text('·', style: PulseTheme.dataXs()),
                      const SizedBox(width: PulseSpace.x2),
                      Text(idShort, style: PulseTheme.dataXs()),
                      if (incident.spreadRisk != null) ...[
                        const SizedBox(width: PulseSpace.x2),
                        Text('·', style: PulseTheme.dataXs()),
                        const SizedBox(width: PulseSpace.x2),
                        Text(
                          'spread ${incident.spreadRisk}',
                          style: PulseTheme.dataXs(
                            color: incident.spreadRisk == 'high'
                                ? PulseColors.crimson
                                : incident.spreadRisk == 'medium'
                                    ? PulseColors.amber
                                    : PulseColors.mist,
                          ),
                        ),
                      ],
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: PulseSpace.x2),
              if (timestamp != null)
                Text(timestamp!, style: PulseTheme.dataXs())
              else
                Text(incident.status.toUpperCase(), style: PulseTheme.label(color: color)),
            ],
          ),
          if (!dense) ...[
            const SizedBox(height: PulseSpace.x3),
            Container(height: 1, color: PulseColors.hairline),
            const SizedBox(height: PulseSpace.x3),
            if (incident.hasBands)
              ForecastBands(
                p10: incident.popP10!,
                p50: incident.popP50 ?? incident.popP10!,
                p90: incident.popP90!,
                locale: locale,
              )
            else if (incident.popP50 != null)
              DotLeader(
                  label: PulseStrings.get('forecast.population', locale),
                  value: _formatNumber(incident.popP50!)),
            if (incident.radiusKmP50 != null)
              DotLeader(label: 'radius', value: '${incident.radiusKmP50!.toStringAsFixed(1)} km'),
            if (incident.durationMinP50 != null)
              DotLeader(
                label: 'duration p50',
                value: '${incident.durationMinP50! ~/ 60}h ${incident.durationMinP50! % 60}m',
              ),
            const SizedBox(height: PulseSpace.x2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('CONFIDENCE', style: PulseTheme.label()),
                const SizedBox(width: PulseSpace.x3),
                Sparkbar(value: incident.confidence, filledColor: color),
                const SizedBox(width: PulseSpace.x2),
                Text(
                  incident.confidence.toStringAsFixed(2),
                  style: PulseTheme.data(size: 12, color: color, weight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: PulseSpace.x3),
            Container(height: 1, color: PulseColors.hairline),
            const SizedBox(height: PulseSpace.x2),
            Row(children: [
              StatusPill(label: incident.status.toUpperCase(), color: color, dense: true),
              const SizedBox(width: PulseSpace.x3),
              Text(
                _statusFooter(incident),
                style: PulseTheme.dataSm(color: PulseColors.mist),
              ),
            ]),
          ] else ...[
            const SizedBox(height: PulseSpace.x2),
            Row(children: [
              if (incident.popP50 != null) ...[
                Text('pop ${_formatNumber(incident.popP50!)}', style: PulseTheme.dataSm()),
                const SizedBox(width: PulseSpace.x3),
              ],
              Text('conf ${incident.confidence.toStringAsFixed(2)}', style: PulseTheme.dataSm()),
            ]),
          ],
        ],
      ),
    );

    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, child: inner));
  }
}
