import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/maintenance_controller.dart';
import '../widgets/maintenance_data_widget.dart';
import 'maintenance_qr_scanner_screen.dart';

class MaintenanceScreen extends GetView<MaintenanceController> {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'maintenance',
        action: false,
        actions: [
          IconButton(
            tooltip: 'مسح فاتورة صيانة',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () async {
              final qrData = await Get.to<String>(
                () => const MaintenanceQrScannerScreen(),
              );
              if (qrData == null || !context.mounted) return;

              final maintenanceId = MaintenanceQrPayload.maintenanceId(qrData);
              if (maintenanceId == null) {
                Get.snackbar(
                  'رمز غير صالح',
                  'هذا الرمز لا يخص فاتورة أو طلب صيانة',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              await controller.openMaintenanceInvoice(
                context: context,
                maintenanceId: maintenanceId.toString(),
              );
            },
          ),
          if (canManageMaintenanceServicesSettings)
            IconButton(
              tooltip: 'إعدادات قسم الصيانة',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Get.toNamed(
                AppRoutes.MAINTENANCESERVICESSETTINGSSCREEN,
              ),
            ),
          _MaintenanceDailyBoxButton(controller: controller),
          if (userType == 'admin')
            IconButton(
              tooltip: 'إدارة إغلاق صناديق الصيانة اليومية',
              icon: const Icon(Icons.pending_actions_outlined),
              onPressed: () async {
                await Get.toNamed(AppRoutes.MAINTENANCEDAILYADMINSCREEN);
                await controller.loadMaintenanceDailySession();
              },
            ),
          Obx(
            () => IconButton(
              tooltip: 'search'.tr,
              onPressed: controller.toggleSearch,
              icon: Icon(
                controller.isSearchVisible.value
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
            ),
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          GetBuilder<MaintenanceController>(
            id: 'maintenanceSearchBar',
            builder: (_) => SliverToBoxAdapter(
              child: Obx(
                () => controller.isSearchVisible.value
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 6.h,
                        ),
                        child: SearchBar(
                          controller: controller.searchController,
                          shadowColor:
                              WidgetStateProperty.all(Colors.transparent),
                          leading: const Icon(Icons.search),
                          trailing: [
                            IconButton(
                              tooltip: 'cancel'.tr,
                              onPressed: controller.closeSearch,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                          hintText: 'maintenance'.tr,
                          backgroundColor: WidgetStateProperty.all(
                            ThemeService.isDark.value
                                ? AppColors.customGreyColor
                                : AppColors.customGreyColor7,
                          ),
                          onChanged: (_) => controller.filterMaintenances(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 8.h)),
          const SliverToBoxAdapter(child: _MaintenanceQuickFilters()),
          SliverToBoxAdapter(child: SizedBox(height: 8.h)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: GetBuilder<MaintenanceController>(
                builder: (c) => Text(
                  '${'total'.tr}: ${c.visibleFilteredCount}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ThemeService.isDark.value
                            ? Colors.white
                            : AppColors.secondaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: GetBuilder<MaintenanceController>(
              builder: (c) {
                if (c.maintenanceViewFilter.value !=
                    MaintenanceController.maintenanceFilterReady) {
                  return const SizedBox.shrink();
                }
                final bulk = c.maintenanceBulkMode.value;
                return Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 2.h),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => c.toggleMaintenanceBulkMode(),
                        icon: Icon(
                          bulk ? Icons.close : Icons.checklist_rounded,
                          size: 18.sp,
                        ),
                        label: Text(bulk ? 'إلغاء التحديد' : 'تحديد عدة طلبات'),
                      ),
                      if (bulk) ...[
                        SizedBox(width: 7.w),
                        TextButton(
                          onPressed: c.selectAllReadyMaintenances,
                          child: const Text('تحديد الكل'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: c.selectedMaintenanceIds.isEmpty
                              ? null
                              : () => c.deliverSelectedMaintenances(context),
                          icon: const Icon(Icons.delivery_dining_outlined),
                          label: Text(
                            'تسليم (${c.selectedMaintenanceIds.length})',
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const MaintenanceDataWidget(),
          SliverToBoxAdapter(child: SizedBox(height: 60.h)),
        ],
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () => controller.startNewMaintenanceFlow(context),
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

class _MaintenanceQuickFilters extends GetView<MaintenanceController> {
  const _MaintenanceQuickFilters();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MaintenanceController>(
      builder: (controller) {
        final filters = [
          _MaintenanceFilterData(
            value: MaintenanceController.maintenanceFilterAll,
            label: 'all'.tr,
            icon: Icons.dashboard_customize_outlined,
            color: AppColors.operationalPurple,
            count: controller.totalFilteredCount,
          ),
          _MaintenanceFilterData(
            value: MaintenanceController.maintenanceFilterNew,
            label: 'newRequest'.tr,
            icon: Icons.fiber_new_rounded,
            color: Colors.blueAccent,
            count: controller.newCount,
          ),
          _MaintenanceFilterData(
            value: MaintenanceController.maintenanceFilterOngoing,
            label: 'inProgress'.tr,
            icon: Icons.build_circle_outlined,
            color: Colors.orange,
            count: controller.ongoingCount,
          ),
          _MaintenanceFilterData(
            value: MaintenanceController.maintenanceFilterReady,
            label: 'readyToDeliver'.tr,
            icon: Icons.verified_outlined,
            color: AppColors.customGreen1,
            count: controller.readyCount,
          ),
          _MaintenanceFilterData(
            value: MaintenanceController.maintenanceFilterDelivered,
            label: 'delivered'.tr,
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.customGreen1,
            count: controller.deliveredCount,
          ),
          _MaintenanceFilterData(
            value: MaintenanceController.maintenanceFilterArchived,
            label: 'archive'.tr,
            icon: Icons.archive_outlined,
            color: AppColors.customGreyColor5,
            count: controller.archivedCount,
          ),
        ];

        return SizedBox(
          height: 48.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final selected =
                  controller.maintenanceViewFilter.value == filter.value;
              return _MaintenanceFilterChip(
                data: filter,
                selected: selected,
                onTap: () => controller.setMaintenanceViewFilter(filter.value),
              );
            },
          ),
        );
      },
    );
  }
}

class _MaintenanceFilterData {
  const _MaintenanceFilterData({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final int count;
}

class _MaintenanceFilterChip extends StatelessWidget {
  const _MaintenanceFilterChip({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _MaintenanceFilterData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final foreground =
        selected ? Colors.white : (isDark ? Colors.white : data.color);
    final background = selected
        ? data.color
        : data.color.withValues(alpha: isDark ? 0.18 : 0.09);

    return Tooltip(
      message: data.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? data.color : data.color.withValues(alpha: 0.22),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(data.icon, size: 20.sp, color: foreground),
              if (data.count > 0)
                PositionedDirectional(
                  top: -5.h,
                  end: -5.w,
                  child: Container(
                    constraints:
                        BoxConstraints(minWidth: 17.w, minHeight: 17.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      data.count > 99 ? '99+' : '${data.count}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenanceDailyBoxButton extends StatelessWidget {
  const _MaintenanceDailyBoxButton({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOpen = controller.isMaintenanceDailyBoxOpen;
      final isClosingRequested =
          controller.isMaintenanceDailyBoxClosingRequested;
      final isLoading = controller.isDailyBoxLoading.value;
      final color = isLoading
          ? Colors.grey
          : isClosingRequested
              ? Colors.orange
              : isOpen
                  ? Colors.green
                  : Colors.redAccent;
      final status = isLoading
          ? 'جارٍ تحميل حالة الصندوق'
          : isClosingRequested
              ? 'بانتظار إغلاق الصندوق'
              : isOpen
                  ? 'الصندوق اليومي مفتوح'
                  : 'الصندوق اليومي مغلق';
      final balance = controller.maintenanceDailyExpectedClosingBalance;

      return Tooltip(
        message:
            'صندوق الصيانة اليومي — $status — ${balance.toStringAsFixed(0)} ₪',
        child: IconButton(
          constraints: BoxConstraints.tightFor(width: 38.w, height: 40.h),
          padding: EdgeInsets.all(2.w),
          visualDensity: VisualDensity.compact,
          onPressed: () async {
            await Get.toNamed(AppRoutes.MAINTENANCEDAILYHISTORYSCREEN);
            await controller.loadMaintenanceDailySession();
          },
          icon: Badge(
            isLabelVisible: isClosingRequested,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                Icons.build_circle_outlined,
                color: color,
                size: 17.sp,
              ),
            ),
          ),
        ),
      );
    });
  }
}
