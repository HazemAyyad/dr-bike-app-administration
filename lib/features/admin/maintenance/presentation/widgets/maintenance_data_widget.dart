import 'package:cached_network_image/cached_network_image.dart';
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
    required bool readOnly,
  }) {
    final displayName = (item.sellerName != null && item.sellerName!.isNotEmpty)
        ? item.sellerName!
        : item.customerName;
    final isDark = ThemeService.isDark.value;
    final bulk = controller.maintenanceBulkMode.value &&
        controller.maintenanceViewFilter.value ==
            MaintenanceController.maintenanceFilterReady;
    final selected = controller.selectedMaintenanceIds.contains(item.id);

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: readOnly
            ? null
            : () async {
                if (bulk) {
                  controller.toggleMaintenanceSelection(item.id, !selected);
                  return;
                }
                await controller.getMaintenancesDetails(
                  maintenanceId: item.id.toString(),
                );
                if (context.mounted) {
                  Get.toNamed(AppRoutes.NEWMAINTENANCESCREEN);
                }
              },
        onLongPress: readOnly
            ? null
            : () {
                if (item.status == 'ready') {
                  controller.toggleMaintenanceBulkMode(true);
                  controller.toggleMaintenanceSelection(item.id, true);
                  return;
                }
                _showMaintenanceActions(context, item);
              },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (bulk)
                    Checkbox(
                      value: selected,
                      onChanged: (value) => controller
                          .toggleMaintenanceSelection(item.id, value == true),
                    ),
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
                                  height: 1.15,
                                  color: isDark
                                      ? AppColors.whiteColor
                                      : AppColors.operationalNavy,
                                ),
                              ),
                            ),
                            if (!readOnly) ...[
                              if (item.status == 'ready')
                                _compactActionButton(
                                  tooltip: 'تسليم الطلب',
                                  icon: Icons.delivery_dining_outlined,
                                  color: AppColors.customGreen1,
                                  onTap: () => controller.deliverFromList(
                                    context,
                                    maintenanceId: item.id.toString(),
                                  ),
                                ),
                              SizedBox(width: 6.w),
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
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          [
                            '${'total'.tr}: ${_money(item.invoiceTotal)}',
                            if (item.invoiceTotal > 0)
                              '${'paidAmount'.tr}: ${_money(item.paidAmount)}',
                            if (item.remainingAmount > 0)
                              '${'remainingAmount'.tr}: ${_money(item.remainingAmount)}',
                          ].join(' | '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final phone = _resolvePhone(item);
    return _SwipeMaintenanceCard(
      enabled: !readOnly && !bulk,
      onCall: phone == null || phone.isEmpty
          ? null
          : () => launchDialer(phoneNumber: phone),
      onOptions: () => _showMaintenanceActions(context, item),
      child: card,
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

class _SwipeMaintenanceCard extends StatefulWidget {
  const _SwipeMaintenanceCard({
    required this.child,
    required this.enabled,
    required this.onCall,
    required this.onOptions,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback? onCall;
  final VoidCallback onOptions;

  @override
  State<_SwipeMaintenanceCard> createState() => _SwipeMaintenanceCardState();
}

class _SwipeMaintenanceCardState extends State<_SwipeMaintenanceCard> {
  double offset = 0;
  static const double revealWidth = 146;

  @override
  void didUpdateWidget(covariant _SwipeMaintenanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled && offset != 0) offset = 0;
  }

  void _update(DragUpdateDetails details) {
    if (!widget.enabled) return;
    setState(() => offset = (offset + details.delta.dx).clamp(0, revealWidth));
  }

  void _finish(DragEndDetails details) {
    if (!widget.enabled) return;
    final shouldOpen =
        offset > revealWidth * .34 || (details.primaryVelocity ?? 0) > 350;
    setState(() => offset = shouldOpen ? revealWidth : 0);
  }

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (widget.enabled)
            Positioned(
              left: 12.w,
              child: Row(
                children: [
                  _MaintenanceSwipeAction(
                    icon: Icons.phone_outlined,
                    label: 'اتصال',
                    color: const Color(0xFF0F766E),
                    onTap: widget.onCall == null
                        ? null
                        : () {
                            setState(() => offset = 0);
                            widget.onCall!();
                          },
                  ),
                  SizedBox(width: 5.w),
                  _MaintenanceSwipeAction(
                    icon: Icons.more_horiz_rounded,
                    label: 'الخيارات',
                    color: AppColors.primaryColor,
                    onTap: () {
                      setState(() => offset = 0);
                      widget.onOptions();
                    },
                  ),
                ],
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(offset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: widget.enabled ? _update : null,
              onHorizontalDragEnd: widget.enabled ? _finish : null,
              child: widget.child,
            ),
          ),
        ],
      );
}

class _MaintenanceSwipeAction extends StatelessWidget {
  const _MaintenanceSwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: onTap == null ? Colors.grey : color,
        borderRadius: BorderRadius.circular(11.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11.r),
          child: SizedBox(
            width: 66.w,
            height: 66.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20.sp),
                SizedBox(height: 3.h),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
      width: 40.w,
      height: 40.w,
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
              size: 20.sp,
              color: AppColors.customGreyColor5,
            ),
          ),
        ),
      ),
    );
  }
}
