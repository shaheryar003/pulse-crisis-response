/// Pulse design tokens.
///
/// Tactical Humanitarian redesign. Deep-sea dark mode with phosphorescent
/// accents and targeted glowing severity levels.
library;

import 'package:flutter/material.dart';

class PulseColors {
  PulseColors._();

  // Surfaces — Deep true-navy void.
  static const ink900 = Color(0xFF080C11);
  static const ink800 = Color(0xFF10151C);
  static const ink700 = Color(0xFF181F29);
  static const ink600 = Color(0xFF202A36);

  // Borders / hairlines.
  static const hairline = Color(0xFF1A232E);
  static const hairlineStrong = Color(0xFF263242);

  // Text.
  static const pearl = Color(0xFFE8ECF1);
  static const stone = Color(0xFFB6BFCF);
  static const mist = Color(0xFF8B95A7);
  static const dim = Color(0xFF5A6478);
  static const ash = Color(0xFF3A4252);

  // Semantic signals.
  static const signal = Color(0xFF38E0D2); // info / primary action (Teal)
  static const amber = Color(0xFFFFB800); // caution / pending (Amber)
  static const crimson = Color(0xFFFF2A5F); // urgent / critical (Crimson)
  static const lime = Color(0xFFA5FF33); // acknowledged / success (Lime)
  static const saffron = Color(0xFFF4A261); // cultural accent (Saffron)

  // Tier Colors for Trace Events
  static const t1 = stone;
  static const t2 = amber;
  static const t3 = signal;
  static const t4 = saffron;
  static const t5 = crimson;
  static const t6 = lime;
  static const t7 = mist;

  static Color tier(int t) => switch (t) {
        1 => t1,
        2 => t2,
        3 => t3,
        4 => t4,
        5 => t5,
        6 => t6,
        7 => t7,
        _ => dim,
      };

  // Severity 1–5.
  static const sev1 = dim;
  static const sev2 = signal;
  static const sev3 = amber;
  static const sev4 = crimson;
  static const sev5 = Color(0xFFFF003C); // Catastrophic deep neon crimson

  static Color severity(int s) => switch (s) {
        5 => sev5,
        4 => sev4,
        3 => sev3,
        2 => sev2,
        _ => sev1,
      };

  static String severityLabel(int s) => switch (s) {
        5 => 'CATASTROPHIC',
        4 => 'SEVERE',
        3 => 'MAJOR',
        2 => 'MINOR',
        _ => 'INFO',
      };
}

class PulseGlow {
  PulseGlow._();

  static List<BoxShadow> signal({double opacity = 0.25, double blur = 16}) => [
        BoxShadow(color: PulseColors.signal.withOpacity(opacity), blurRadius: blur, offset: Offset.zero),
      ];
      
  static List<BoxShadow> amber({double opacity = 0.25, double blur = 16}) => [
        BoxShadow(color: PulseColors.amber.withOpacity(opacity), blurRadius: blur, offset: Offset.zero),
      ];
      
  static List<BoxShadow> crimson({double opacity = 0.35, double blur = 24}) => [
        BoxShadow(color: PulseColors.crimson.withOpacity(opacity), blurRadius: blur, offset: Offset.zero),
      ];
      
  static List<BoxShadow> lime({double opacity = 0.20, double blur = 12}) => [
        BoxShadow(color: PulseColors.lime.withOpacity(opacity), blurRadius: blur, offset: Offset.zero),
      ];

  static List<BoxShadow> severity(int s) => switch (s) {
        5 => [
            BoxShadow(color: PulseColors.sev5.withOpacity(0.50), blurRadius: 32, offset: Offset.zero),
            BoxShadow(color: PulseColors.sev5.withOpacity(0.20), blurRadius: 16, spreadRadius: 4, offset: Offset.zero),
          ],
        4 => crimson(),
        3 => amber(),
        2 => signal(),
        _ => const [],
      };
}

class PulseRadii {
  PulseRadii._();
  static const sharp = 0.0;
  static const xs = 1.0;
  static const sm = 2.0;   // Status pills, badges
  static const md = 4.0;
  static const lg = 8.0;
  static const xl = 12.0;  // Buttons
  static const xxl = 16.0; // Cards
}

class PulseSpace {
  PulseSpace._();
  static const x0_5 = 2.0;
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x12 = 48.0;
  static const x16 = 64.0;
  static const x24 = 96.0;
}
