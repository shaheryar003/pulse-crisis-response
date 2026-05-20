import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import '../tokens.dart';

/// Pulsing amber badge for alerts with requires_human_approval = true.
/// Mandated by privacy.md: "The mobile app shows requires_human_approval
/// badges on staged alerts."
class ApprovalGateBadge extends StatefulWidget {
  final String locale;
  const ApprovalGateBadge({super.key, this.locale = PulseStrings.en});

  @override
  State<ApprovalGateBadge> createState() => _ApprovalGateBadgeState();
}

class _ApprovalGateBadgeState extends State<ApprovalGateBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: PulseColors.amber
                    .withValues(alpha: 0.5 + 0.5 * _ctl.value),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: PulseColors.amber
                        .withValues(alpha: 0.3 * _ctl.value),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: PulseSpace.x2),
            Container(
              decoration: BoxDecoration(
                color: PulseColors.amber.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(PulseRadii.sm),
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 3, color: PulseColors.amber),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PulseSpace.x2,
                        vertical: 3,
                      ),
                      child: Text(
                        PulseStrings.get(
                            'citizen.alerts.approval_required', widget.locale),
                        style: PulseTheme.label(color: PulseColors.amber)
                            .copyWith(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
