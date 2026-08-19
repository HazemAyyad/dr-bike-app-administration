import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/app_settings_service.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../routes/app_routes.dart';
import '../../../stock/presentation/controllers/stock_controller.dart';

/// Inventory-related settings hub under General Settings.
class StockInventorySettingsScreen extends StatelessWidget {
  const StockInventorySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF3F4F6);
    const cardColor = Colors.white;
    const borderColor = Color(0xFFE5E7EB);
    const titleColor = Color(0xFF111827);
    const descColor = Color(0xFF6B7280);
    final stock = Get.isRegistered<StockController>()
        ? Get.find<StockController>()
        : null;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: const CustomAppBar(
        title: 'stockInventorySettings',
        action: false,
        backgroundColor: pageBg,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        children: [
          FutureBuilder<void>(
            future: AppSettingsService.instance.ensureLoaded(),
            builder: (context, _) => Obx(
              () => _SettingsTile(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF0F766E),
                title: 'طريقة تكلفة المخزون',
                description: AppSettingsService
                            .instance.inventoryCostingMethod.value ==
                        'moving_average'
                    ? 'المتوسط المرجح: يُعاد حساب متوسط تكلفة المخزون عند دخول كميات جديدة. يطبق على الحركات القادمة فقط.'
                    : 'FIFO: الأقدم في المخزون يُصرف أولاً حسب تكلفة الدفعة القديمة. يطبق على الحركات القادمة فقط.',
                trailing: Text(
                  AppSettingsService.instance.inventoryCostingMethod.value ==
                          'moving_average'
                      ? 'متوسط'
                      : 'FIFO',
                  style: TextStyle(
                    color: const Color(0xFF0F766E),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () => _showCostingMethodSheet(context),
                cardColor: cardColor,
                borderColor: borderColor,
                titleColor: titleColor,
                descColor: descColor,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          if (canManageStockInventorySettings && stock != null) ...[
            Obx(
              () => _SettingsTile(
                icon: Icons.file_download_outlined,
                iconColor: const Color(0xFF059669),
                title: 'exportProducts'.tr,
                description: 'exportProductsSettingDesc'.tr,
                trailing: stock.isProductsCsvBusy.value
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: stock.isProductsCsvBusy.value
                    ? null
                    : stock.exportProductsCsv,
                cardColor: cardColor,
                borderColor: borderColor,
                titleColor: titleColor,
                descColor: descColor,
              ),
            ),
            SizedBox(height: 10.h),
            Obx(
              () => _SettingsTile(
                icon: Icons.file_upload_outlined,
                iconColor: const Color(0xFF7C3AED),
                title: 'importProducts'.tr,
                description: 'importProductsSettingDesc'.tr,
                trailing: stock.isProductsCsvBusy.value
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: stock.isProductsCsvBusy.value
                    ? null
                    : stock.importProductsCsv,
                cardColor: cardColor,
                borderColor: borderColor,
                titleColor: titleColor,
                descColor: descColor,
              ),
            ),
            SizedBox(height: 10.h),
          ],
          _SettingsTile(
            icon: Icons.place_outlined,
            iconColor: const Color(0xFF0369A1),
            title: 'storeSectionsSetting'.tr,
            description: 'storeSectionsSettingDesc'.tr,
            onTap: () async {
              await Get.toNamed(AppRoutes.STORESECTIONSSETTINGSSCREEN);
              if ((userType == 'admin' ||
                      employeePermissions.contains(stockPermissionId)) &&
                  Get.isRegistered<StockController>()) {
                await Get.find<StockController>()
                    .refreshAfterStoreSectionsChanged();
              }
            },
            cardColor: cardColor,
            borderColor: borderColor,
            titleColor: titleColor,
            descColor: descColor,
          ),
          SizedBox(height: 10.h),
          _SettingsTile(
            icon: Icons.straighten,
            iconColor: const Color(0xFF2563EB),
            title: 'productSizeOptionsSetting'.tr,
            description: 'productSizeOptionsSettingDesc'.tr,
            onTap: () =>
                Get.toNamed(AppRoutes.PRODUCTSIZEOPTIONSSETTINGSSCREEN),
            cardColor: cardColor,
            borderColor: borderColor,
            titleColor: titleColor,
            descColor: descColor,
          ),
        ],
      ),
    );
  }

  void _showCostingMethodSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
          child: Obx(
            () {
              final method =
                  AppSettingsService.instance.inventoryCostingMethod.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'طريقة تكلفة المخزون',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'تغيير الطريقة يؤثر على حركات المخزون الجديدة فقط ولا يعيد حساب مبيعات أو صيانة قديمة.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF6B7280),
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _CostingOptionTile(
                    selected: method == 'fifo',
                    title: 'FIFO',
                    description:
                        'الأقدم في المخزون يُصرف أولاً حسب تكلفة الدفعة القديمة.',
                    onTap: () async {
                      await AppSettingsService.instance
                          .updateInventoryCostingMethod('fifo');
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                  SizedBox(height: 8.h),
                  _CostingOptionTile(
                    selected: method == 'moving_average',
                    title: 'Moving Weighted Average',
                    description:
                        'يُعاد حساب متوسط تكلفة المخزون عند دخول كميات جديدة.',
                    onTap: () async {
                      await AppSettingsService.instance
                          .updateInventoryCostingMethod('moving_average');
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CostingOptionTile extends StatelessWidget {
  const _CostingOptionTile({
    required this.selected,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF0F766E) : const Color(0xFF6B7280);
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected ? const Color(0xFF0F766E) : const Color(0xFFE5E7EB),
          ),
          color: selected
              ? const Color(0xFF0F766E).withValues(alpha: 0.08)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: color,
              size: 22.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF6B7280),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
    required this.cardColor,
    required this.borderColor,
    required this.titleColor,
    required this.descColor,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final Color cardColor;
  final Color borderColor;
  final Color titleColor;
  final Color descColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: descColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(Icons.chevron_left, color: descColor, size: 22.sp),
            ],
          ),
        ),
      ),
    );
  }
}
