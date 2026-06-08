import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared product grid layout for stock screens.
class StockProductGridLayout {
  StockProductGridLayout._();

  static const double minCardHeight = 112;

  static double aspectRatioForTab(int tab) {
    if (tab == 0) return 0.92;
    if (tab == 1) return 0.72;
    return 0.84;
  }

  static SliverGridDelegateWithFixedCrossAxisCount delegate({
    required double aspectRatio,
  }) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 8.w,
      mainAxisSpacing: 4.h,
      childAspectRatio: aspectRatio,
    );
  }
}
