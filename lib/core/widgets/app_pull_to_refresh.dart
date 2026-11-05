import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Scroll physics that allow pull-to-refresh even on short or empty lists.
const ScrollPhysics kRefreshableScrollPhysics = AlwaysScrollableScrollPhysics(
  parent: BouncingScrollPhysics(),
);

/// Standard pull-to-refresh wrapper used across list screens.
class AppPullToRefresh extends StatelessWidget {
  const AppPullToRefresh({
    Key? key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.indicatorKey,
  }) : super(key: key);

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final GlobalKey<RefreshIndicatorState>? indicatorKey;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: indicatorKey,
      onRefresh: onRefresh,
      color: color ?? AppColors.primaryColor,
      child: child,
    );
  }
}
