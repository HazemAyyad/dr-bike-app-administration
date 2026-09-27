import 'package:flutter/material.dart';

class DashboardDesignTokens {
  const DashboardDesignTokens._();

  static const background = Color(0xFFF7F9FC);
  static const darkBackground = Color(0xFF171822);
  static const surface = Colors.white;
  static const darkSurface = Color(0xFF242532);

  static const primary = Color(0xFF6558E8);
  static const success = Color(0xFF0FAF78);
  static const danger = Color(0xFFEE3657);
  static const warning = Color(0xFFF28C18);
  static const info = Color(0xFF168BE4);
  static const reports = Color(0xFFD82A91);

  static const textPrimary = Color(0xFF111B35);
  static const textSecondary = Color(0xFF71809C);
  static const darkTextPrimary = Color(0xFFF5F6FB);
  static const darkTextSecondary = Color(0xFFADB5C7);
  static const border = Color(0xFFE8ECF3);
  static const darkBorder = Color(0xFF3B3D4C);

  static const double cardRadius = 16;
  static const double iconRadius = 12;
  static const double sectionSpacing = 22;
  static const double cardSpacing = 10;

  static Color backgroundFor(bool dark) => dark ? darkBackground : background;

  static Color surfaceFor(bool dark) => dark ? darkSurface : surface;

  static Color textPrimaryFor(bool dark) =>
      dark ? darkTextPrimary : textPrimary;

  static Color textSecondaryFor(bool dark) =>
      dark ? darkTextSecondary : textSecondary;

  static Color borderFor(bool dark) => dark ? darkBorder : border;

  static List<BoxShadow> shadowFor(bool dark, {bool quiet = false}) => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: dark ? .18 : (quiet ? .025 : .045),
          ),
          blurRadius: quiet ? 7 : 13,
          offset: const Offset(0, 4),
        ),
      ];
}
