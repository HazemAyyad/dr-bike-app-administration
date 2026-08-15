import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../controllers/smart_home_controller.dart';

class SmartHomeDashboardScreen extends GetView<SmartHomeController> {
  const SmartHomeDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          'smartHome'.tr,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
              ),
        ),
        actions: [
          IconButton(
            tooltip: 'refresh'.tr,
            onPressed: controller.refreshData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.homes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
            children: [
              if (controller.errorMessage.value.isNotEmpty)
                _ErrorBanner(message: controller.errorMessage.value),
              _HomeSummaryCard(controller: controller),
              SizedBox(height: 16.h),
              _NativeStatusCard(controller: controller),
              SizedBox(height: 16.h),
              _SectionHeader(
                title: 'rooms'.tr,
                actionLabel: 'addRoom'.tr,
                onAction: () => _notReady('addRoom'.tr),
              ),
              SizedBox(height: 8.h),
              _RoomsStrip(controller: controller),
              SizedBox(height: 18.h),
              _SectionHeader(
                title: 'devices'.tr,
                actionLabel: 'addDevice'.tr,
                onAction: _showAddDeviceDialog,
              ),
              SizedBox(height: 8.h),
              _DevicesList(controller: controller),
            ],
          ),
        );
      }),
    );
  }

  void _notReady(String title) {
    Get.snackbar(title, 'smartHomeComingSoon'.tr);
  }

  Future<void> _showAddDeviceDialog() async {
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();
    try {
      await Get.dialog<void>(
        AlertDialog(
          title: Text('addDevice'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ssidController,
                decoration: InputDecoration(
                  labelText: 'smartHomeWifiName'.tr,
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'smartHomeWifiPassword'.tr,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'smartHomePairingHint'.tr,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppColors.customGreyColor5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(() {
                if (controller.errorMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: _ErrorBanner(message: controller.errorMessage.value),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: Text('close'.tr),
            ),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isPairingDevice.value
                    ? null
                    : () async {
                        controller.errorMessage('');
                        await controller.startDevicePairing(
                          ssid: ssidController.text,
                          password: passwordController.text,
                        );
                        if (!controller.isPairingDevice.value &&
                            controller.errorMessage.value.isEmpty) {
                          Get.back<void>();
                        }
                      },
                child: controller.isPairingDevice.value
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('startPairing'.tr),
              ),
            ),
          ],
        ),
      );
    } finally {
      ssidController.dispose();
      passwordController.dispose();
    }
  }
}

class _HomeSummaryCard extends StatelessWidget {
  const _HomeSummaryCard({required this.controller});

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    final home = controller.selectedHome;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            home?.name.isNotEmpty == true
                ? home!.name
                : 'smartHomeDefaultName'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'devices'.tr,
                  value: controller.devicesCount.toString(),
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'online'.tr,
                  value: controller.onlineDevicesCount.toString(),
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'offline'.tr,
                  value: controller.offlineDevicesCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
              ),
        ),
        SizedBox(height: 3.h),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.white.withOpacity(.85),
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _NativeStatusCard extends StatelessWidget {
  const _NativeStatusCard({required this.controller});

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.nativeStatus.value;
    final ok = status.initialized;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.info_rounded,
            color: ok ? Colors.green : AppColors.customOrange3,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'tuyaSdkReady'.tr : 'tuyaSdkNeedsSetup'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  controller.isLinkingTuyaUser.value
                      ? 'tuyaUserLinking'.tr
                      : controller.isTuyaUserLinked
                          ? 'tuyaUserLinked'.tr
                          : 'tuyaUserNeedsLink'.tr,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: controller.isTuyaUserLinked
                            ? Colors.green
                            : AppColors.customGreyColor5,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add_rounded),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _RoomsStrip extends StatelessWidget {
  const _RoomsStrip({required this.controller});

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.rooms.isEmpty) {
      return _EmptyState(text: 'noRoomsYet'.tr);
    }
    return SizedBox(
      height: 46.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.rooms.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final room = controller.rooms[index];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              room.name,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          );
        },
      ),
    );
  }
}

class _DevicesList extends StatelessWidget {
  const _DevicesList({required this.controller});

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.devices.isEmpty) {
      return _EmptyState(text: 'noDevicesYet'.tr);
    }
    return Column(
      children: controller.devices.map((device) {
        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: AppColors.primaryColor.withOpacity(.12),
                child: Icon(
                  _iconForCategory(device.category),
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      device.productName.isNotEmpty
                          ? device.productName
                          : (device.category.isNotEmpty
                              ? device.category
                              : 'smartDevice'.tr),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppColors.customGreyColor5,
                          ),
                    ),
                  ],
                ),
              ),
              _OnlinePill(online: device.online),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _iconForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('light') || value.contains('switch')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (value.contains('curtain') || value.contains('blind')) {
      return Icons.curtains_rounded;
    }
    if (value.contains('lock')) return Icons.lock_outline_rounded;
    if (value.contains('sensor')) return Icons.sensors_rounded;
    return Icons.devices_other_rounded;
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: (online ? Colors.green : AppColors.customGreyColor5)
            .withOpacity(.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        online ? 'online'.tr : 'offline'.tr,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: online ? Colors.green : AppColors.customGreyColor5,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppColors.customGreyColor5,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.redColor.withOpacity(.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.redColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
