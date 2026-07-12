import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/daily_session_model.dart';
import '../controllers/sales_controller.dart';
import 'sales_skeleton_widgets.dart';

class SalesDailyStatusBar extends GetView<SalesController> {
  const SalesDailyStatusBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isDailySessionLoading.value) {
        return const SalesDailyStatusBarSkeleton();
      }

      final payload = controller.dailySessionPayload.value;
      if (payload == null) {
        return const SizedBox.shrink();
      }

      final session = payload.session;
      final status = session?.status ?? 'none';
      final color = _statusColor(status, payload);
      final label = _statusLabel(status, payload);

      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.SALESDAILYHISTORYSCREEN),
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
              Icon(Icons.account_balance_wallet_outlined,
                  color: color, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (payload.shouldWarnPreviousDaySale)
                      Text(
                        'salesDailyPreviousDayOpenDetails'.trParams({
                          'date': payload.previousDayBusinessDate ?? '',
                          'employee': payload.previousDayOwnerName ?? '',
                        }),
                        style: TextStyle(
                            fontSize: 11.sp, color: Colors.grey.shade700),
                      )
                    else if (payload.blockedByOtherSession)
                      Text(
                        'salesDailySharedDrawerOpen'.trParams({
                          'employee': payload.blockedByEmployeeName ?? '',
                        }),
                        style: TextStyle(
                            fontSize: 11.sp, color: Colors.grey.shade700),
                      )
                    else if (session != null)
                      Text(
                        '${'salesDailyBusinessDate'.tr}: ${session.businessDate}',
                        style: TextStyle(
                            fontSize: 11.sp, color: Colors.grey.shade700),
                      ),
                    _shekelSummary(payload),
                  ],
                ),
              ),
              if (payload.canManageOtherSession &&
                  payload.manageableSessionId != null)
                TextButton(
                  onPressed: () => Get.toNamed(
                    AppRoutes.SALESDAILYCLOSESCREEN,
                    arguments: payload.manageableSessionId,
                  ),
                  child: Text('salesDailyCloseDay'.tr),
                ),
              if (payload.canRequestOpen)
                TextButton(
                  onPressed: () => _openDrawer(context),
                  child: Text('salesDailyOpenDrawer'.tr),
                ),
              if (payload.canRequestClosing)
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.SALESDAILYCLOSESCREEN),
                  child: Text('salesDailyCloseDay'.tr),
                ),
              if (payload.canRequestReopen)
                TextButton(
                  onPressed: () => _showReopenDialog(context),
                  child: Text('salesDailyRequestReopen'.tr),
                ),
              Icon(Icons.chevron_left, color: color, size: 20.sp),
            ],
          ),
        ),
      );
    });
  }

  Widget _shekelSummary(DailySessionPayload payload) {
    final row = payload.rowForCurrency('شيكل');
    if (row == null) return const SizedBox.shrink();
    return Text(
      '${'salesDailySystemBalance'.tr}: ${row.systemBalance.toStringAsFixed(0)} ${row.currency}',
      style: TextStyle(fontSize: 11.sp),
    );
  }

  Color _statusColor(String status, DailySessionPayload payload) {
    if (payload.isBlockingPreviousDay) return Colors.red;
    if (payload.blockedByOtherSession) return AppColors.primaryColor;
    if (payload.needsManualOpen) return Colors.blueGrey;
    if (status == 'closing_requested') return Colors.orange;
    if (status == 'closed') return Colors.grey;
    return AppColors.primaryColor;
  }

  String _statusLabel(String status, DailySessionPayload payload) {
    if (payload.isBlockingPreviousDay) {
      return 'salesDailyPreviousDayOpen'.tr;
    }
    if (payload.blockedByOtherSession) {
      return 'salesDailyDayOpen'.tr;
    }
    if (payload.needsManualOpen) {
      return 'salesDailyDrawerNotOpen'.tr;
    }
    if (payload.isReopenPending) {
      return 'salesDailyReopenPending'.tr;
    }
    switch (status) {
      case 'closing_requested':
        return 'salesDailyClosingPending'.tr;
      case 'closed':
        return 'salesDailyDayClosed'.tr;
      default:
        return 'salesDailyDayOpen'.tr;
    }
  }

  Future<void> _openDrawer(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('salesDailyOpenDrawer'.tr),
        content: Text('salesDailyOpenDrawerConfirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('salesDailyOpenDrawer'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.requestDailyOpen();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> _showReopenDialog(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('salesDailyRequestReopen'.tr),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'salesDailyReopenReasonHint'.tr,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('salesDailySubmitReopen'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) {
      Get.snackbar('error'.tr, 'salesDailyReopenReasonRequired'.tr);
      return;
    }
    try {
      await controller.requestDailyReopen(reason: reason);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      reasonCtrl.dispose();
    }
  }
}
