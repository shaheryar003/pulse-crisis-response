import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// CTA button used for primary actions across the app — leading ▸ marker,
/// signal-color outline, semi-transparent fill, full width by default.
class CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final Color? color;
  const CtaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.fullWidth = true,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    final c = color ?? PulseColors.signal;
    final btn = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: c.withValues(alpha: 0.10),
        foregroundColor: c,
        side: BorderSide(color: c, width: 1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(PulseRadii.md)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x5, vertical: PulseSpace.x4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: c),
            )
          else
            Text('▸', style: PulseTheme.data(size: 14, color: c, weight: FontWeight.w700)),
          const SizedBox(width: PulseSpace.x3),
          Text(label.toUpperCase(), style: PulseTheme.label(color: c).copyWith(fontSize: 11)),
        ],
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
