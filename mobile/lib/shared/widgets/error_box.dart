import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import '../tokens.dart';

/// Reusable error state box with a retry button.
/// Used consistently across all three role surfaces.
class ErrorBox extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final String locale;
  const ErrorBox({
    super.key,
    required this.error,
    required this.onRetry,
    this.locale = PulseStrings.en,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PulseSpace.x6),
      child: Container(
        padding: const EdgeInsets.all(PulseSpace.x4),
        decoration: BoxDecoration(
          color: PulseColors.crimson.withValues(alpha: 0.06),
          border: Border.all(color: PulseColors.crimson, width: 1),
          borderRadius: BorderRadius.circular(PulseRadii.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              PulseStrings.get('common.network_error', locale),
              style: PulseTheme.label(color: PulseColors.crimson),
            ),
            const SizedBox(height: PulseSpace.x2),
            Text(error, style: PulseTheme.dataSm(color: PulseColors.crimson)),
            const SizedBox(height: PulseSpace.x3),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(PulseStrings.get('common.retry', locale)),
            ),
          ],
        ),
      ),
    );
  }
}
