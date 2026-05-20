import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Trace event card — the showpiece for the Command Center.
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
    duration: const Duration(milliseconds: 400),
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

  @override
  Widget build(BuildContext context) {
    final accent = PulseColors.tier(widget.tier);
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, child) {
        // Flash border for 200ms when new
        final double flashProgress = _ctl.value < 0.5 ? _ctl.value * 2 : (1.0 - _ctl.value) * 2;
        final borderColor = widget.isNew
            ? Color.lerp(PulseColors.hairlineStrong, accent, flashProgress)!
            : PulseColors.hairlineStrong;
        
        final content = Container(
          margin: const EdgeInsets.only(bottom: PulseSpace.x3),
          decoration: BoxDecoration(
            color: PulseColors.ink800,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(PulseRadii.xxl),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: child,
        );

        if (widget.isNew) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _ctl,
              curve: Curves.easeOutQuart,
            )),
            child: FadeTransition(
              opacity: _ctl,
              child: content,
            ),
          );
        }
        
        return content;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(PulseSpace.x3, PulseSpace.x3, PulseSpace.x3, PulseSpace.x2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x2, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    border: Border.all(color: accent, width: 1),
                    borderRadius: BorderRadius.circular(PulseRadii.sm),
                  ),
                  child: Text(
                    'T${widget.tier}',
                    style: PulseTheme.dataXs(color: accent),
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
                  Text('▸', style: PulseTheme.data(size: 12, color: accent)),
                  const SizedBox(width: PulseSpace.x2),
                  Expanded(
                    child: Text(widget.decision, style: PulseTheme.data(size: 12, color: PulseColors.stone), overflow: TextOverflow.ellipsis),
                  ),
                  if (widget.confidence != null) ...[
                    const SizedBox(width: PulseSpace.x2),
                    Text('conf', style: PulseTheme.label()),
                    const SizedBox(width: PulseSpace.x1),
                    Text(widget.confidence!.toStringAsFixed(2),
                        style: PulseTheme.data(size: 11, color: PulseColors.pearl, weight: FontWeight.w600)),
                  ],
                ]),
                if (widget.details != null && widget.details!.isNotEmpty) ...[
                  const SizedBox(height: PulseSpace.x3),
                  Container(
                    padding: const EdgeInsets.all(PulseSpace.x3),
                    decoration: BoxDecoration(
                      border: Border.all(color: PulseColors.hairline),
                      color: PulseColors.ink900.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(PulseRadii.xl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.hypothesis != null) ...[
                          Text(widget.hypothesis!.toUpperCase(),
                              style: PulseTheme.data(size: 11, color: accent, weight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Container(height: 1, color: PulseColors.hairline),
                          const SizedBox(height: 6),
                        ],
                        for (final entry in widget.details!.entries)
                          Padding(
                            padding: const EdgeInsets.only(top: PulseSpace.x1),
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
