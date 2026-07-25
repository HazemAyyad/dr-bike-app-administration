import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/desktop_window_service.dart';

class OpenDesktopWindowButton extends StatelessWidget {
  const OpenDesktopWindowButton({
    Key? key,
    required this.route,
    this.title,
    this.tooltip,
  }) : super(key: key);

  final String route;
  final String? title;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    if (!DesktopWindowService.isSupported) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: tooltip ?? 'openInNewWindow'.tr,
      icon: const Icon(Icons.open_in_new_rounded),
      onPressed: () async {
        final ok = await DesktopWindowService.openRoute(
          route: route,
          title: title?.tr,
        );
        if (!ok) {
          Get.snackbar('error'.tr, 'openInNewWindowFailed'.tr);
        }
      },
    );
  }
}
