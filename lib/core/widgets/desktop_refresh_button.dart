import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/desktop_layout.dart';

class DesktopRefreshButton extends StatelessWidget {
  const DesktopRefreshButton({Key? key, required this.indicatorKey})
      : super(key: key);

  final GlobalKey<RefreshIndicatorState> indicatorKey;

  @override
  Widget build(BuildContext context) {
    if (!DesktopLayout.isDesktopPlatform) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'refresh'.tr,
      onPressed: () => indicatorKey.currentState?.show(),
      icon: const Icon(Icons.refresh_rounded),
    );
  }
}
