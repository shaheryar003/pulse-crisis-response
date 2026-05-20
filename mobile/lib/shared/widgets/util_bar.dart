import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth.dart';
import '../theme.dart';
import '../tokens.dart';

/// Fixed top utility bar. Wordmark + role + tab cluster + right-side actions.
class UtilBar extends StatelessWidget implements PreferredSizeWidget {
  final List<UtilTab> tabs;
  final int activeIndex;
  final ValueChanged<int>? onTab;
  final List<Widget> actions;
  const UtilBar({
    super.key,
    this.tabs = const [],
    this.activeIndex = 0,
    this.onTab,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: PulseColors.ink900,
        border: Border(bottom: BorderSide(color: PulseColors.hairline, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x4),
      child: Row(
        children: [
          Text(
            'PULSE',
            style: GoogleFonts.fraunces(
              color: PulseColors.pearl,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: PulseSpace.x4),
          Container(width: 1, height: 20, color: PulseColors.hairline),
          const SizedBox(width: PulseSpace.x4),
          _RoleIndicator(role: session.role),
          if (tabs.isNotEmpty) ...[
            const SizedBox(width: PulseSpace.x6),
            Container(width: 1, height: 20, color: PulseColors.hairline),
            const SizedBox(width: PulseSpace.x4),
            ...List.generate(tabs.length, (i) {
              final t = tabs[i];
              final active = i == activeIndex;
              return Semantics(
                button: true,
                selected: active,
                label: t.label,
                child: Padding(
                  padding: const EdgeInsets.only(right: PulseSpace.x5),
                  // 48dp minimum tap target via SizedBox height + centered content
                  child: SizedBox(
                    height: 48,
                    child: InkWell(
                      onTap: onTab == null ? null : () => onTab!(i),
                      borderRadius: BorderRadius.circular(2),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.only(top: 2, bottom: 4),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: active
                                    ? PulseColors.pearl
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            t.label.toUpperCase(),
                            style: GoogleFonts.dmSans(
                              color: active
                                  ? PulseColors.pearl
                                  : PulseColors.mist,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

class UtilTab {
  final String label;
  final IconData? icon;
  const UtilTab(this.label, {this.icon});
}

class _RoleIndicator extends StatelessWidget {
  final String role;
  const _RoleIndicator({required this.role});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: PulseColors.lime,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(color: PulseColors.lime.withValues(alpha: 0.4), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: PulseSpace.x2),
        Text(role.toUpperCase(), style: PulseTheme.label(color: PulseColors.pearl)),
      ],
    );
  }
}

/// Round, hairline-only icon button for utility bar actions.
/// Minimum effective tap target: 48dp via invisible padding in SizedBox.
class UtilIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  const UtilIconButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Semantics(
      button: true,
      label: tooltip,
      child: SizedBox(
        width: 40,
        height: 40,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(PulseRadii.sm),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: PulseColors.hairline),
                borderRadius: BorderRadius.circular(PulseRadii.sm),
              ),
              child: Icon(icon, size: 14, color: PulseColors.stone),
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}
