import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../core/helpers/open_apps.dart';
import '../../../../../core/helpers/phone_format_helper.dart';
import '../../data/models/maintenances_model.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceDataWidget extends GetView<MaintenanceController> {
  const MaintenanceDataWidget({Key? key}) : super(key: key);

  String _money(double value) => value.toStringAsFixed(2);

  Widget _compactActionButton({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 28.w,
          height: 34.h,
          child: Center(
            child: Icon(
              icon,
              size: 18.sp,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MaintenanceDataModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('deleteMaintenance'.tr),
        content: Text('deleteMaintenanceConfirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteMaintenance(
        maintenanceId: item.id.toString(),
      );
    }
  }

  String? _resolvePhone(MaintenanceDataModel item) {
    final fromApi = item.contactPhone?.trim();
    if (fromApi != null && fromApi.isNotEmpty) {
      return PhoneFormatHelper.forDialer(fromApi);
    }
    if (item.sellerId != null) {
      for (final s in controller.allSellersList) {
        if (s.id == item.sellerId && s.phone.isNotEmpty) {
          return PhoneFormatHelper.forDialer(s.phone);
        }
      }
    }
    if (item.customerId != null) {
      for (final c in controller.allCustomersList) {
        if (c.id == item.customerId && c.phone.isNotEmpty) {
          return PhoneFormatHelper.forDialer(c.phone);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MaintenanceController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (controller.visibleFilteredCount == 0) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }

        final children = <Widget>[];
        if (controller.showNewMaintenanceSection) {
          children.addAll(
            _buildSection(
              context: context,
              title: 'newRequest'.tr,
              grouped: controller.maintenancesSearch,
              statusColor: Colors.blueAccent,
              statusLabel: 'newRequest'.tr,
            ),
          );
        }
        if (controller.showOngoingMaintenanceSection) {
          children.addAll(
            _buildSection(
              context: context,
              title: 'inProgress'.tr,
              grouped: controller.ongoingMaintenancesSearch,
              statusColor: Colors.orange,
              statusLabel: 'inProgress'.tr,
            ),
          );
        }
        if (controller.showReadyMaintenanceSection) {
          children.addAll(
            _buildSection(
              context: context,
              title: 'readyToDeliver'.tr,
              grouped: controller.readyMaintenancesSearch,
              statusColor: AppColors.customGreen1,
              statusLabel: 'readyToDeliver'.tr,
            ),
          );
        }
        if (controller.showDeliveredMaintenanceSection) {
          children.addAll(
            _buildSection(
              context: context,
              title: 'delivered'.tr,
              grouped: controller.deliveredMaintenancesSearch,
              statusColor: AppColors.customGreen1,
              statusLabel: 'delivered'.tr,
            ),
          );
        }
        if (controller.showArchivedMaintenanceSection) {
          children.addAll(
            _buildSection(
              context: context,
              title: 'archive'.tr,
              grouped: controller.archiveMaintenancesSearch,
              statusColor: AppColors.customGreyColor5,
              statusLabel: 'archive'.tr,
              readOnly: true,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildListDelegate(children),
        );
      },
    );
  }

  List<Widget> _buildSection({
    required BuildContext context,
    required String title,
    required Map<String, List<MaintenanceDataModel>> grouped,
    required Color statusColor,
    required String statusLabel,
    bool readOnly = false,
  }) {
    final itemsCount = grouped.values.fold<int>(0, (sum, e) => sum + e.length);
    final children = <Widget>[
      _MaintenanceSectionHeader(
        title: title,
        count: itemsCount,
        color: statusColor,
      ),
    ];

    if (itemsCount == 0) {
      children.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 8.h),
          child: Text(
            'noData'.tr,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor3
                  : AppColors.customGreyColor5,
            ),
          ),
        ),
      );
      return children;
    }

    final keys = grouped.keys.toList().reversed.toList();
    for (final key in keys) {
      children.add(_MaintenanceDateHeader(title: key));
      final items = grouped[key]!.reversed.toList();
      children.addAll(
        items.map(
          (item) => _buildMaintenanceCard(
            context: context,
            item: item,
            statusColor: statusColor,
            statusLabel: statusLabel,
            readOnly: readOnly,
          ),
        ),
      );
    }
    children.add(SizedBox(height: 10.h));
    return children;
  }

  Widget _buildMaintenanceCard({
    required BuildContext context,
    required MaintenanceDataModel item,
    required Color statusColor,
    required String statusLabel,
    required bool readOnly,
  }) {
    final displayName = (item.sellerName != null && item.sellerName!.isNotEmpty)
        ? item.sellerName!
        : item.customerName;
    final isDark = ThemeService.isDark.value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: readOnly
            ? null
            : () {
                controller.getMaintenancesDetails(
                  maintenanceId: item.id.toString(),
                );
                Get.toNamed(AppRoutes.NEWMAINTENANCESCREEN);
              },
        onLongPress:
            readOnly ? null : () => _showMaintenanceActions(context, item),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 3.h),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.customGreyColor : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.operationalCardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.operationalNavy.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _MaintenanceThumb(imageUrl: item.mediaFiles),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  color: isDark
                                      ? AppColors.whiteColor
                                      : AppColors.operationalNavy,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            _MaintenanceStatusPill(
                              label: statusLabel,
                              color: statusColor,
                            ),
                          ],
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          showData(item.receiptDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark
                                ? AppColors.customGreyColor3
                                : AppColors.customGreyColor5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.invoiceTotal > 0) ...[
                SizedBox(height: 7.h),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkColor.withValues(alpha: 0.45)
                        : AppColors.customGreyColor7.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.operationalCardBorder
                          .withValues(alpha: 0.75),
                    ),
                  ),
                  child: Text(
                    [
                      '${'total'.tr}: ${_money(item.invoiceTotal)}',
                      '${'paidAmount'.tr}: ${_money(item.paidAmount)}',
                      if (item.remainingAmount > 0)
                        '${'remainingAmount'.tr}: ${_money(item.remainingAmount)}',
                    ].join(' | '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
              if (!readOnly) ...[
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _compactActionButton(
                      tooltip: 'maintenanceInvoice'.tr,
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.primaryColor,
                      onTap: () => controller.openMaintenanceInvoice(
                        context: context,
                        maintenanceId: item.id.toString(),
                      ),
                    ),
                    _compactActionButton(
                      tooltip: 'maintenanceActivityLog'.tr,
                      icon: Icons.history,
                      color: AppColors.customGreyColor,
                      onTap: () => controller.openActivityLog(
                        context: context,
                        maintenanceId: item.id.toString(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMaintenanceActions(
    BuildContext context,
    MaintenanceDataModel item,
  ) async {
    controller.getAllCustomersAndSellers();
    final phone = _resolvePhone(item);
    final canDelete = item.status == 'new' || item.status == 'ongoing';
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phone != null && phone.isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text('callCustomer'.tr),
                subtitle: Text(phone),
                onTap: () async {
                  Navigator.pop(ctx);
                  await launchDialer(phoneNumber: phone);
                },
              ),
              ListTile(
                leading: Image.asset(
                  AssetsManager.whatsapp,
                  width: 24.w,
                  height: 24.w,
                ),
                title: Text('whatsappCall'.tr),
                subtitle: Text(phone),
                onTap: () async {
                  Navigator.pop(ctx);
                  await launchWhatsApp(phoneNumber: phone);
                },
              ),
            ],
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'deleteMaintenance'.tr,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _confirmDelete(context, item);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceSectionHeader extends StatelessWidget {
  const _MaintenanceSectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(28.w, 14.h, 28.w, 6.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: ThemeService.isDark.value
                    ? AppColors.whiteColor
                    : AppColors.secondaryColor,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceDateHeader extends StatelessWidget {
  const _MaintenanceDateHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(28.w, 6.h, 28.w, 5.h),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 12.sp,
        ),
      ),
    );
  }
}

class _MaintenanceThumb extends StatelessWidget {
  const _MaintenanceThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44.w,
      height: 44.w,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: CachedNetworkImage(
          cacheManager: CacheManager(
            Config(
              'imagesCache',
              stalePeriod: const Duration(days: 7),
              maxNrOfCacheObjects: 100,
            ),
          ),
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.customGreyColor7,
            child: Icon(
              Icons.construction_outlined,
              size: 22.sp,
              color: AppColors.customGreyColor5,
            ),
          ),
        ),
      ),
    );
  }
}

class _MaintenanceStatusPill extends StatelessWidget {
  const _MaintenanceStatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 92.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
