import 'package:flutter/material.dart';

/// Spacing, Padding, and Radius tokens adhering to DESIGN.md
class AppSpacing {
  AppSpacing._();

  // Spacing Scale
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xxl = 24.0;
  static const double section = 32.0;

  // Corner Radii
  static const double radiusSm   = 6.0;
  static const double radiusMd   = 10.0;
  static const double radiusLg   = 14.0; // Standard card rounded-xl (from DESIGN.md)
  static const double radiusPill = 999.0; // Badges & chips

  static const BorderRadius borderSm   = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderMd   = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderLg   = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(radiusPill));

  // Touch Ergonomics (Mobile UX Guidelines)
  static const double minTouchTarget = 48.0; // Minimum interactive target height/width
  static const double primaryButtonHeight = 52.0; // Prominent thumb-zone decision button

  // Standard EdgeInsets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets cardPadding   = EdgeInsets.all(14.0);
  static const EdgeInsets dialogPadding = EdgeInsets.all(20.0);
}

