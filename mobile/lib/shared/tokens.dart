/// Pulse design tokens.
///
/// Hand-picked semantic palette. No seed-color generator. Crisis-context dark
/// aesthetic with editorial gravitas. Tokens here are the single source of
/// truth — everything else references them.
library;

import 'package:flutter/material.dart';

class PulseColors {
  PulseColors._();

  // Surfaces — almost-black blue-grays, never pure black.
  static const ink900 = Color(0xFF0B0F14);
  static const ink800 = Color(0xFF131922);
  static const ink700 = Color(0xFF1A2230);
  static const ink600 = Color(0xFF232E3F);

  // Borders / hairlines.
  static const hairline = Color(0xFF1F2937);
  static const hairlineStrong = Color(0xFF2A3441);

  // Text.
  static const pearl = Color(0xFFE8ECF1);
  static const stone = Color(0xFFB6BFCF);
  static const mist = Color(0xFF8B95A7);
  static const dim = Color(0xFF5A6478);
  static const ash = Color(0xFF3A4252);

  // Semantic signals.
  static const signal = Color(0xFF4FD1C5); // info / primary action
  static const amber = Color(0xFFF5A524); // caution / pending
  static const crimson = Color(0xFFF31260); // urgent / critical
  static const lime = Color(0xFFB5E853); // acknowledged / success
  static const saffron = Color(0xFFE0A458); // cultural accent

  // Severity 1–5.
  static const sev1 = dim;
  static const sev2 = signal;
  static const sev3 = amber;
  static const sev4 = crimson;
  static const sev5 = Color(0xFFB30038);

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

class PulseRadii {
  PulseRadii._();
  static const sharp = 0.0;
  static const xs = 1.0;
  static const sm = 2.0;
  static const md = 4.0;
  static const lg = 8.0;
  static const xl = 12.0;
  static const xxl = 16.0;
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
