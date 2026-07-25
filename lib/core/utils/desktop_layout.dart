import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DesktopLayout {
  const DesktopLayout._();

  static const double desktopMinWidth = 1100;
  static const double wideDesktopMinWidth = 1800;

  static bool get isDesktopPlatform {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return true;
      default:
        return false;
    }
  }

  static bool isDesktopWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopMinWidth;
  }

  static bool isDesktop(BuildContext context) {
    return isDesktopPlatform || isDesktopWidth(context);
  }

  static int gridColumnsForWidth(
    double width, {
    double minTileWidth = 178,
    int min = 2,
    int max = 10,
    double gap = 8,
  }) {
    if (width <= 0) return min;
    final columns = ((width + gap) / (minTileWidth + gap)).floor();
    return columns.clamp(min, max);
  }

  static int gridColumns(
    BuildContext context, {
    double horizontalPadding = 0,
    double minTileWidth = 178,
    int min = 2,
    int max = 10,
    double gap = 8,
  }) {
    final width = math.max(
      0.0,
      MediaQuery.sizeOf(context).width - horizontalPadding,
    );
    return gridColumnsForWidth(
      width,
      minTileWidth: minTileWidth,
      min: min,
      max: max,
      gap: gap,
    );
  }

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 2500) return 2360;
    if (width >= wideDesktopMinWidth) return 1760;
    return double.infinity;
  }
}
