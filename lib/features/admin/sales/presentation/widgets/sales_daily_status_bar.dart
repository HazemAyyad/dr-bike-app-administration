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

  double _parseOpeningAmount(String? value) {
    const eastern = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };
    var text = DailyCashCountRow.cleanRequestAmount(value ?? '');
    eastern.forEach((from, to) {
      text = text.replaceAll(from, to);
    });
    return double.tryParse(text) ?? 0;
  }

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
      final showClosingApproval =
          payload.isClosingRequested && payload.canFinalizeClosing;
      final showManagedClose = !showClosingApproval &&
          payload.canManageOtherSession &&
          payload.manageableSessionId != null;
      final showDirectClose = payload.canRequestClosing &&
          !showManagedClose &&
          !showClosingApproval;

      return GestureDetector(
        onTap: () => _openStatusTarget(showClosingApproval),
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
                    if (payload.isClosingRequested)
                      Text(
                        'salesDailyClosingPendingHint'.tr,
                        style: TextStyle(
                            fontSize: 11.sp, color: Colors.grey.shade700),
                      )
                    else if (payload.shouldWarnPreviousDaySale)
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
              if (showManagedClose)
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
              if (showDirectClose)
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.SALESDAILYCLOSESCREEN),
                  child: Text('salesDailyCloseDay'.tr),
                ),
              if (showClosingApproval)
                TextButton(
                  onPressed: _openClosingRequests,
                  child: Text('salesDailyReviewClosingRequest'.tr),
                ),
              Icon(Icons.chevron_left, color: color, size: 20.sp),
            ],
          ),
        ),
      );
    });
  }

  void _openStatusTarget(bool showClosingApproval) {
    if (showClosingApproval) {
      _openClosingRequests();
      return;
    }
    Get.toNamed(AppRoutes.SALESDAILYHISTORYSCREEN);
  }

  void _openClosingRequests() {
    Get.toNamed(
      AppRoutes.SALESDAILYADMINSCREEN,
      arguments: {'initialTab': 1},
    );
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
    if (status == 'closing_requested') return Colors.orange;
    if (payload.isBlockingPreviousDay) return Colors.red;
    if (payload.blockedByOtherSession) return AppColors.primaryColor;
    if (payload.needsManualOpen) return Colors.blueGrey;
    if (status == 'closed') return Colors.grey;
    return AppColors.primaryColor;
  }

  String _statusLabel(String status, DailySessionPayload payload) {
    if (status == 'closing_requested') {
      return 'salesDailyClosingPending'.tr;
    }
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
      case 'closed':
        return 'salesDailyDayClosed'.tr;
      default:
        return 'salesDailyDayOpen'.tr;
    }
  }

  Future<void> _openDrawer(BuildContext context) async {
    final payload = controller.dailySessionPayload.value;
    const dialogBg = Colors.white;
    const dialogTitleColor = Color(0xFF111827);
    const dialogTextColor = Color(0xFF374151);
    const dialogMutedColor = Color(0xFF6B7280);
    final dialogButtonStyle = TextButton.styleFrom(
      foregroundColor: AppColors.primaryColor,
    );
    final expectedRows = payload?.expectedOpeningCounts.isNotEmpty == true
        ? payload!.expectedOpeningCounts
        : const [DailyExpectedOpeningCount(currency: 'شيكل')];
    final controllers = {
      for (final row in expectedRows)
        row.currency: TextEditingController(
          text: row.expectedAmount == 0
              ? ''
              : row.expectedAmount.toStringAsFixed(0),
        ),
    };

    try {
      final counts = await showDialog<List<Map<String, dynamic>>>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: dialogTitleColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
          ),
          contentTextStyle: TextStyle(
            color: dialogTextColor,
            fontSize: 13.sp,
          ),
          title: Text('salesDailyOpeningCountTitle'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'salesDailyOpeningCountHint'.tr,
                  style: TextStyle(color: dialogTextColor),
                ),
                SizedBox(height: 12.h),
                ...expectedRows.map((row) {
                  final previous = row.previousEmployeeName?.trim();
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.currency,
                          style: TextStyle(
                            color: dialogTitleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'salesDailyExpectedOpening'.trParams({
                            'amount': row.expectedAmount.toStringAsFixed(0),
                            'currency': row.currency,
                            'employee':
                                previous?.isNotEmpty == true ? previous! : '—',
                            'date': row.previousBusinessDate ?? '—',
                          }),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: dialogMutedColor,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        TextField(
                          controller: controllers[row.currency],
                          style: TextStyle(color: dialogTitleColor),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'salesDailyCountedOpening'.tr,
                            labelStyle: TextStyle(color: dialogMutedColor),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: dialogButtonStyle,
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.tr),
            ),
            TextButton(
              style: dialogButtonStyle,
              onPressed: () {
                final counts = expectedRows
                    .map<Map<String, dynamic>>(
                      (row) => {
                        'currency': row.currency,
                        'physical_count': _parseOpeningAmount(
                          controllers[row.currency]?.text,
                        ),
                      },
                    )
                    .toList();
                Navigator.pop(ctx, counts);
              },
              child: Text('salesDailyOpenDrawer'.tr),
            ),
          ],
        ),
      );
      if (counts == null) return;
      debugPrint(
        '[SalesDailyOpenDebug][Dialog] counts=$counts expected=${expectedRows.map((row) => {
              'currency': row.currency,
              'expected': row.expectedAmount,
              'previous_employee': row.previousEmployeeName,
              'previous_date': row.previousBusinessDate,
            }).toList()}',
      );

      final varianceRows = expectedRows.where((row) {
        final input = counts.firstWhere(
          (item) => item['currency'] == row.currency,
          orElse: () => <String, dynamic>{'physical_count': 0},
        );
        final counted = (input['physical_count'] as num).toDouble();
        return (counted - row.expectedAmount).abs() > 0.0001;
      }).toList();

      var confirmVariance = false;
      if (varianceRows.isNotEmpty) {
        if (!context.mounted) return;
        final row = varianceRows.first;
        final input = counts.firstWhere(
          (item) => item['currency'] == row.currency,
          orElse: () => <String, dynamic>{'physical_count': 0},
        );
        final counted = (input['physical_count'] as num).toDouble();
        debugPrint(
          '[SalesDailyOpenDebug][Dialog] variance currency=${row.currency} expected=${row.expectedAmount} counted=$counted',
        );
        confirmVariance = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: dialogBg,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: dialogTitleColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                ),
                contentTextStyle: TextStyle(
                  color: dialogTextColor,
                  fontSize: 13.sp,
                ),
                title: Text('salesDailyOpeningVarianceTitle'.tr),
                content: Text(
                  'salesDailyOpeningVarianceBody'.trParams({
                    'expected': row.expectedAmount.toStringAsFixed(0),
                    'counted': counted.toStringAsFixed(0),
                    'currency': row.currency,
                    'employee': row.previousEmployeeName ?? '—',
                    'date': row.previousBusinessDate ?? '—',
                  }),
                ),
                actions: [
                  TextButton(
                    style: dialogButtonStyle,
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('cancel'.tr),
                  ),
                  TextButton(
                    style: dialogButtonStyle,
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('continue'.tr),
                  ),
                ],
              ),
            ) ==
            true;
        debugPrint(
          '[SalesDailyOpenDebug][Dialog] confirmOpeningVariance=$confirmVariance',
        );
        if (!confirmVariance) return;
      }

      debugPrint(
        '[SalesDailyOpenDebug][Dialog] submit openingCounts=$counts confirmOpeningVariance=$confirmVariance',
      );
      await controller.requestDailyOpen(
        openingCounts: counts,
        confirmOpeningVariance: confirmVariance,
      );
    } catch (e) {
      debugPrint('[SalesDailyOpenDebug][Dialog] error=$e');
      Get.snackbar('error'.tr, e.toString());
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      for (final ctrl in controllers.values) {
        ctrl.dispose();
      }
    }
  }
}
