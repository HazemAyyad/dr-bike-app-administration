import 'package:flutter/material.dart';

/// Neutral backgrounds for admin product screens (light mode avoids tinted
/// [ColorScheme.surface] that reads purple/lilac with some themes).
class AdminUiColors {
  AdminUiColors._();

  static const Color lightScaffold = Color(0xFFF7F7FA);

  static Color scaffoldBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).scaffoldBackgroundColor
        : lightScaffold;
  }

  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surface
        : Colors.white;
  }

  /// Outlined inputs on admin forms (matches cards in light mode).
  static Color inputFill(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surface
        : Colors.white;
  }

  /// Chips, icon mats, add-tile backgrounds — neutral in light mode.
  static Color subtleOverlay(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surfaceContainerHigh
        : Colors.grey.shade200;
  }

  /// “Add media” tile: avoid [primaryContainer] lilac in light mode.
  static Color mediaAddTileBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.primaryContainer
        : Colors.grey.shade100;
  }
}
