import 'package:flutter/material.dart';
import 'colors.dart';

/// Typography hierarchy adhering to DESIGN.md and mobile readability rules.
class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'Inter';
  static const String monospaceFont = 'Courier';

  // Display & Screen Headings
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.8,
    height: 1.15,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.25,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.0,
    height: 1.3,
  );

  // Body Text (Minimum 12pt for high readability)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.35,
  );

  // Micro-Labels & Eyebrows (Caps)
  static const TextStyle labelUppercase = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
    height: 1.2,
  );

  static const TextStyle labelBadge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.1,
  );

  // Technical & Monospace Metadata (Versions, Hashes, Currency)
  static const TextStyle codeMedium = TextStyle(
    fontFamily: monospaceFont,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    height: 1.3,
  );

  static const TextStyle codeHash = TextStyle(
    fontFamily: monospaceFont,
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
    color: AppColors.darkMutedText,
    height: 1.2,
  );
}

