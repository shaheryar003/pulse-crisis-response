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
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return c.withValues(alpha: 0.20);
          if (states.contains(WidgetState.hovered)) return c.withValues(alpha: 0.15);
          return c.withValues(alpha: 0.10);
        }),
        foregroundColor: WidgetStateProperty.all(c),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
            return BorderSide(color: c, width: 1.5);
          }
          return BorderSide(color: c.withValues(alpha: 0.5), width: 1);
        }),
        shape: WidgetStateProperty.all(const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(PulseRadii.xl)),
        )),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: PulseSpace.x5, vertical: PulseSpace.x4)),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return 8.0;
          return 0.0;
        }),
        shadowColor: WidgetStateProperty.all(c.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
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
