import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Trace event card — the showpiece for the Command Center.
/// Header shows tier badge + agent + millisecond timestamp.
class TraceEventCard extends StatefulWidget {
  final int tier;
  final String agent;
  final String decision;
  final double? confidence;
  final String? timestamp;
  final Map<String, String>? details;
  final String? hypothesis;
  final bool isNew;
  const TraceEventCard({
    super.key,
    required this.tier,
    required this.agent,
    required this.decision,
    this.confidence,
    this.timestamp,
    this.details,
    this.hypothesis,
    this.isNew = false,
  });

  @override
  State<TraceEventCard> createState() => _TraceEventCardState();
}

class _TraceEventCardState extends State<TraceEventCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isNew) _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Color _tierAccent() {
    return switch (widget.tier) {
      1 => PulseColors.signal,
      2 => PulseColors.amber,
      3 => PulseColors.lime,
      4 => PulseColors.saffron,
      5 => PulseColors.crimson,
      6 => PulseColors.signal,
      7 => PulseColors.mist,
      _ => PulseColors.dim,
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = _tierAccent();
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, child) {
        final borderColor = widget.isNew
            ? Color.lerp(accent, PulseColors.hairline, _ctl.value)!
            : PulseColors.hairline;
        return Container(
          margin: const EdgeInsets.only(bottom: PulseSpace.x3),
          decoration: BoxDecoration(
            color: PulseColors.ink800,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(PulseRadii.md),
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header with tier badge inset into top border style
          Container(
            padding: const EdgeInsets.fromLTRB(PulseSpace.x3, PulseSpace.x3, PulseSpace.x3, PulseSpace.x2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: _tierAccent(), width: 1),
                    borderRadius: BorderRadius.circular(PulseRadii.sm),
                  ),
                  child: Text(
                    'T${widget.tier}',
                    style: PulseTheme.dataXs(color: _tierAccent()),
                  ),
                ),
                const SizedBox(width: PulseSpace.x2),
                Text(widget.agent, style: PulseTheme.data(size: 12, color: PulseColors.pearl, weight: FontWeight.w600)),
                const Spacer(),
                Text(widget.timestamp ?? '', style: PulseTheme.dataXs()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(PulseSpace.x3, 0, PulseSpace.x3, PulseSpace.x3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('▸', style: PulseTheme.data(size: 12, color: _tierAccent())),
                  const SizedBox(width: PulseSpace.x2),
                  Text(widget.decision, style: PulseTheme.data(size: 12, color: PulseColors.stone)),
                  if (widget.confidence != null) ...[
                    const Spacer(),
                    Text('conf', style: PulseTheme.label()),
                    const SizedBox(width: PulseSpace.x1),
                    Text(widget.confidence!.toStringAsFixed(2),
                        style: PulseTheme.data(size: 11, color: PulseColors.pearl, weight: FontWeight.w600)),
                  ],
                ]),
                if (widget.details != null && widget.details!.isNotEmpty) ...[
                  const SizedBox(height: PulseSpace.x2),
                  Container(
                    padding: const EdgeInsets.all(PulseSpace.x2),
                    decoration: BoxDecoration(
                      border: Border.all(color: PulseColors.hairline),
                      color: PulseColors.ink900,
                      borderRadius: BorderRadius.circular(PulseRadii.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.hypothesis != null) ...[
                          Text(widget.hypothesis!.toUpperCase(),
                              style: PulseTheme.data(size: 12, color: _tierAccent(), weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(height: 1, color: PulseColors.hairline),
                          const SizedBox(height: 4),
                        ],
                        for (final entry in widget.details!.entries)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                SizedBox(
                                  width: 78,
                                  child: Text(entry.key.toLowerCase(), style: PulseTheme.dataXs()),
                                ),
                                Expanded(
                                  child: Text(entry.value,
                                      style: PulseTheme.data(size: 11, color: PulseColors.pearl)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
