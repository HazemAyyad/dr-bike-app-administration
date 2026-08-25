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
          IconButton(
            tooltip: 'صناديق الصيانة اليومية',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Get.toNamed(
              AppRoutes.DAILYBOXESSCREEN,
              arguments: {'filter': 'maintenance'},
            ),
          ),
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
          SliverToBoxAdapter(child: SizedBox(height: 8.h)),
          const SliverToBoxAdapter(child: _MaintenanceDailyBoxStatus()),
          const MaintenanceDataWidget(),
          SliverToBoxAdapter(child: SizedBox(height: 60.h)),
        ],
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          controller.clearControllers();
          Get.toNamed(AppRoutes.NEWMAINTENANCESCREEN);
        },
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

class _MaintenanceDailyBoxStatus extends GetView<MaintenanceController> {
  const _MaintenanceDailyBoxStatus();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOpen = controller.isMaintenanceDailyBoxOpen;
      final isClosingRequested =
          controller.isMaintenanceDailyBoxClosingRequested;
      final isLoading = controller.isDailyBoxLoading.value;
      final canOpen = controller.canRequestMaintenanceDailyOpen;
      final canClose = controller.canRequestMaintenanceDailyClosing;
      final canReview =
          isClosingRequested && controller.canFinalizeMaintenanceDailyClosing;
      final color = isOpen
          ? AppColors.customGreen1
          : isClosingRequested
              ? Colors.orange
              : controller.isMaintenanceDailyBlockedByOther
                  ? AppColors.primaryColor
                  : Colors.blueGrey;
      final label = isOpen
          ? 'صندوق الصيانة اليومي مفتوح'
          : isClosingRequested
              ? 'طلب إغلاق صندوق الصيانة معلق'
              : controller.isMaintenanceDailyBlockedByOther
                  ? 'صندوق صيانة مفتوح'
                  : 'صندوق الصيانة اليومي غير مفتوح';

      return GestureDetector(
        onTap: () => Get.toNamed(
          AppRoutes.DAILYBOXESSCREEN,
          arguments: {'filter': 'maintenance'},
        ),
        child: Container(
          margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 8.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: color,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (isClosingRequested)
                      Text(
                        'بانتظار مراجعة طلب الإغلاق',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade700,
                        ),
                      )
                    else if (controller.isMaintenanceDailyBlockedByOther)
                      Text(
                        'الموظف: ${controller.maintenanceDailyBlockedByEmployeeName ?? '-'}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade700,
                        ),
                      )
                    else if (controller.dailyBoxSession != null)
                      Text(
                        'تاريخ اليوم: ${controller.dailyBoxSession?['business_date'] ?? ''}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    Text(
                      'رصيد النظام: ${_money(controller.maintenanceDailyExpectedClosingBalance)} شيكل',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    Text(
                      'رصيد اليوم: ${_money(controller.maintenanceDailyCashTotal)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (canOpen)
                TextButton(
                  onPressed: isLoading ? null : () => _showOpenDialog(context),
                  child: isLoading
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('فتح الصندوق'),
                ),
              if (canClose)
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          await Get.toNamed(
                            AppRoutes.MAINTENANCEDAILYCLOSESCREEN,
                            arguments: userType == 'admin'
                                ? {
                                    'mode': 'direct',
                                    'session': Map<String, dynamic>.from(
                                      controller.dailyBoxPayload,
                                    ),
                                  }
                                : null,
                          );
                          await controller.loadMaintenanceDailySession();
                        },
                  child: isLoading
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إغلاق اليوم'),
                ),
              if (canReview)
                TextButton(
                  onPressed: controller.isDailyClosingReviewLoading.value
                      ? null
                      : () async {
                          await Get.toNamed(
                            AppRoutes.MAINTENANCEDAILYADMINSCREEN,
                          );
                          await controller.loadMaintenanceDailySession();
                        },
                  child: const Text('مراجعة الإغلاق'),
                ),
              Icon(Icons.chevron_left, color: color, size: 20.sp),
            ],
          ),
        ),
      );
    });
  }

  String _money(double value) => value.toStringAsFixed(2);

  Future<void> _showOpenDialog(BuildContext context) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _MaintenanceOpenBoxDialog(
        initialAmount: controller.maintenanceDailyOpeningBalance,
      ),
    );
    if (amount == null) return;
    await controller.openMaintenanceDailySession(openingBalance: amount);
  }
}

class _MaintenanceOpenBoxDialog extends StatefulWidget {
  const _MaintenanceOpenBoxDialog({required this.initialAmount});

  final double initialAmount;

  @override
  State<_MaintenanceOpenBoxDialog> createState() =>
      _MaintenanceOpenBoxDialogState();
}

class _MaintenanceOpenBoxDialogState extends State<_MaintenanceOpenBoxDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount > 0
          ? widget.initialAmount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('فتح صندوق الصيانة'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'الفكة المستلمة',
          hintText: '0.00',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            double.tryParse(_controller.text.trim()) ?? 0,
          ),
          child: Text('confirm'.tr),
        ),
      ],
    );
  }
}
