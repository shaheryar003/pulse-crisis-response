import 'package:flutter/material.dart';

import '../../models/incident.dart';
import '../theme.dart';
import '../tokens.dart';
import 'dot_leader.dart';
import 'severity_pill.dart';
import 'sparkbar.dart';
import 'status_pill.dart';

class IncidentCard extends StatelessWidget {
  final Incident incident;
  final String? timestamp;
  final bool dense;
  final VoidCallback? onTap;
  final bool selected;
  const IncidentCard({
    super.key,
    required this.incident,
    this.timestamp,
    this.dense = false,
    this.onTap,
    this.selected = false,
  });

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final retracted = incident.status == 'retracted';
    final color = retracted ? PulseColors.dim : PulseColors.severity(incident.severity);
    final typeLabel = incident.type.replaceAll('_', ' ').toUpperCase();
    final idShort = incident.id.length > 10 ? incident.id.substring(0, 10) : incident.id;

    final inner = Container(
      decoration: BoxDecoration(
        color: PulseColors.ink800,
        border: Border(
          left: BorderSide(color: selected ? PulseColors.signal : Colors.transparent, width: 2),
          bottom: const BorderSide(color: PulseColors.hairline, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(PulseSpace.x4, PulseSpace.x4, PulseSpace.x4, PulseSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SeverityPill(severity: incident.severity, withLabel: false, pulse: !retracted),
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
            if (incident.popP50 != null) DotLeader(label: 'population', value: _formatNumber(incident.popP50!)),
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
                retracted ? 'retracted · audit logged' : 'tracking · responders dispatched',
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
