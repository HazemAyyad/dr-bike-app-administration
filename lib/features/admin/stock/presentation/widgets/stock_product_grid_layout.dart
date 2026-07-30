import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/desktop_layout.dart';

/// Shared product grid layout for stock screens.
class StockProductGridLayout {
  StockProductGridLayout._();

  static const double minCardHeight = 132;

  static double aspectRatioForTab(int tab, {BuildContext? context}) {
    final desktop = context != null && DesktopLayout.isDesktop(context);
    if (desktop) {
      if (tab == 0) return 0.86;
      if (tab == 1) return 0.78;
      return 0.82;
    }
    if (tab == 0) return 0.78;
    if (tab == 1) return 0.68;
    return 0.74;
  }

  static int columnsForContext(BuildContext context) {
    final desktop = DesktopLayout.isDesktop(context);
    return DesktopLayout.gridColumns(
      context,
      horizontalPadding: 48.w,
      minTileWidth: desktop ? 175 : 105,
      min: desktop ? 4 : 3,
      max: desktop ? 8 : 3,
      gap: 8.w,
    );
  }

  static SliverGridDelegateWithFixedCrossAxisCount delegate({
    BuildContext? context,
    required double aspectRatio,
  }) {
    final columns = context == null ? 3 : columnsForContext(context);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: 8.w,
      mainAxisSpacing: 4.h,
      childAspectRatio: aspectRatio,
    );
  }
}
