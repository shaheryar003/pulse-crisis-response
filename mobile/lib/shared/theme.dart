import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

class PulseTheme {
  PulseTheme._();

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: PulseColors.signal,
      onPrimary: PulseColors.ink900,
      secondary: PulseColors.amber,
      onSecondary: PulseColors.ink900,
      error: PulseColors.crimson,
      onError: PulseColors.pearl,
      surface: PulseColors.ink800,
      onSurface: PulseColors.pearl,
      surfaceContainerHighest: PulseColors.ink700,
      surfaceContainer: PulseColors.ink800,
      surfaceContainerHigh: PulseColors.ink700,
      surfaceContainerLow: PulseColors.ink900,
      outline: PulseColors.hairlineStrong,
      outlineVariant: PulseColors.hairline,
    );

    final textTheme = _textTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: PulseColors.ink900,
      canvasColor: PulseColors.ink900,
      textTheme: textTheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      dividerColor: PulseColors.hairline,
      dividerTheme: const DividerThemeData(
        color: PulseColors.hairline,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: PulseColors.stone, size: 18),
      cardTheme: const CardThemeData(
        elevation: 8,
        shadowColor: Color(0x66000000),
        margin: EdgeInsets.zero,
        color: PulseColors.ink800,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: PulseColors.hairline, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(PulseRadii.xxl)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PulseColors.ink800,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PulseSpace.x4,
          vertical: PulseSpace.x3,
        ),
        labelStyle: textTheme.labelMedium,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: textTheme.bodyMedium?.copyWith(color: PulseColors.dim),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(PulseRadii.xxl)),
          borderSide: BorderSide(color: PulseColors.hairline, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(PulseRadii.xxl)),
          borderSide: BorderSide(color: PulseColors.hairline, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(PulseRadii.xxl)),
          borderSide: BorderSide(color: PulseColors.signal, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: PulseColors.signal.withValues(alpha: 0.10),
          foregroundColor: PulseColors.signal,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(PulseRadii.xl)),
            side: BorderSide(color: PulseColors.signal, width: 1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: PulseSpace.x5,
            vertical: PulseSpace.x4,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PulseColors.pearl,
          side: const BorderSide(color: PulseColors.hairlineStrong, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(PulseRadii.xl)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: PulseSpace.x4,
            vertical: PulseSpace.x3,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PulseColors.stone,
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: PulseColors.ink800,
        side: const BorderSide(color: PulseColors.hairline, width: 1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(PulseRadii.lg)),
        ),
        labelStyle: GoogleFonts.inter(
            color: PulseColors.stone,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
        ),
        padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x3, vertical: PulseSpace.x2),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: GoogleFonts.jetBrainsMono(color: PulseColors.pearl, fontSize: 11),
        decoration: BoxDecoration(
          color: PulseColors.ink700,
          border: Border.all(color: PulseColors.hairlineStrong, width: 1),
          borderRadius: BorderRadius.circular(PulseRadii.sm),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PulseColors.ink700,
        contentTextStyle: GoogleFonts.inter(color: PulseColors.pearl, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulseRadii.sm),
          side: const BorderSide(color: PulseColors.hairlineStrong, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _textTheme() {
    final body = GoogleFonts.interTextTheme(const TextTheme()).apply(
      bodyColor: PulseColors.pearl,
      displayColor: PulseColors.pearl,
    );

    final display = GoogleFonts.outfit(
      color: PulseColors.pearl,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    );

    return body.copyWith(
      displayLarge: display.copyWith(fontSize: 40, height: 1.05),
      displayMedium: display.copyWith(fontSize: 32, height: 1.1),
      displaySmall: display.copyWith(fontSize: 26, height: 1.15),
      headlineLarge: display.copyWith(fontSize: 22, height: 1.2),
      headlineMedium: display.copyWith(fontSize: 18, height: 1.25),
      titleLarge: GoogleFonts.inter(
        color: PulseColors.pearl,
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        color: PulseColors.pearl,
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.inter(
        color: PulseColors.stone,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      bodyLarge: GoogleFonts.inter(color: PulseColors.pearl, fontSize: 14, height: 1.45),
      bodyMedium: GoogleFonts.inter(color: PulseColors.stone, fontSize: 13, height: 1.45),
      bodySmall: GoogleFonts.inter(color: PulseColors.mist, fontSize: 12, height: 1.4),
      labelLarge: GoogleFonts.inter(
        color: PulseColors.mist,
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
      labelMedium: GoogleFonts.inter(
        color: PulseColors.mist,
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
      labelSmall: GoogleFonts.inter(
        color: PulseColors.dim,
        fontSize: 9,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  static TextStyle data({double size = 13, Color color = PulseColors.pearl, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.jetBrainsMono(color: color, fontSize: size, fontWeight: weight, height: 1.3);

  static TextStyle dataSm({Color color = PulseColors.stone}) =>
      GoogleFonts.jetBrainsMono(color: color, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.2);

  static TextStyle dataXs({Color color = PulseColors.mist}) =>
      GoogleFonts.jetBrainsMono(color: color, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4);

  static TextStyle display({double size = 26, Color color = PulseColors.pearl}) => GoogleFonts.outfit(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle label({Color color = PulseColors.mist}) => GoogleFonts.inter(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      );

  static TextStyle urdu({double size = 15, Color color = PulseColors.pearl}) =>
      GoogleFonts.notoNastaliqUrdu(color: color, fontSize: size, height: 1.6);
      
  static TextStyle wordmark({double size = 24, Color color = PulseColors.pearl}) =>
      GoogleFonts.fraunces(color: color, fontSize: size, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic);
}

class SeverityPalette {
  static Color color(int severity, ColorScheme _) => PulseColors.severity(severity);
  static String label(int severity) => PulseColors.severityLabel(severity);
}
