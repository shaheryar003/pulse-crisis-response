import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Single section label row with a leading em-dash.
class SectionLabel extends StatelessWidget {
  final String text;
  final String? subtitle;
  final Widget? trailing;
  const SectionLabel({super.key, required this.text, this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PulseSpace.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(text.toUpperCase(), style: PulseTheme.label()),
          const SizedBox(width: PulseSpace.x2),
          Expanded(child: Container(height: 1, color: PulseColors.hairline)),
          if (subtitle != null) ...[
            const SizedBox(width: PulseSpace.x2),
            Text(subtitle!, style: PulseTheme.dataXs()),
          ],
          if (trailing != null) ...[const SizedBox(width: PulseSpace.x2), trailing!],
        ],
      ),
    );
  }
}

class EmDashLeader extends StatelessWidget {
  final String text;
  final Color? color;
  const EmDashLeader(this.text, {super.key, this.color});
  @override
  Widget build(BuildContext context) {
    return Text(
      '╴ $text',
      style: PulseTheme.dataSm(color: color ?? PulseColors.mist),
    );
  }
}
