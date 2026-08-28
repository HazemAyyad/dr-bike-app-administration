import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/daily_session_model.dart';
import '../controllers/sales_controller.dart';
import 'sales_skeleton_widgets.dart';

class SalesDailyStatusBar extends GetView<SalesController> {
  const SalesDailyStatusBar({
    this.salesOrders = false,
    Key? key,
  }) : super(key: key);

  final bool salesOrders;

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
      final statusLabel = _statusLabel(status, payload);
      final label = salesOrders
          ? 'صندوق الطلبيات اليومي — $statusLabel'
          : 'صندوق المبيعات اليومي — $statusLabel';
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
    final ordersIndex = payload.salesOrdersCurrencies
        .indexWhere((item) => item.currency == 'شيكل');
    final ordersRow =
        ordersIndex >= 0 ? payload.salesOrdersCurrencies[ordersIndex] : null;
    if (row == null && ordersRow == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!salesOrders && row != null)
          Text(
            'الرصيد: ${row.systemBalance.toStringAsFixed(0)} ${row.currency}',
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
          ),
        if (salesOrders && ordersRow != null)
          Text(
            'الرصيد: ${ordersRow.systemBalance.toStringAsFixed(0)} ${ordersRow.currency}',
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
          ),
      ],
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
    final ordersExpectedRows =
        payload?.expectedSalesOrdersOpeningCounts.isNotEmpty == true
            ? payload!.expectedSalesOrdersOpeningCounts
            : const [DailyExpectedOpeningCount(currency: 'شيكل')];
    final ordersControllers = {
      for (final row in ordersExpectedRows)
        row.currency: TextEditingController(
          text: row.expectedAmount == 0
              ? ''
              : row.expectedAmount.toStringAsFixed(0),
        ),
    };

    try {
      final result = await showDialog<Map<String, List<Map<String, dynamic>>>>(
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
          title: Text(
            salesOrders
                ? 'فتح صندوق الطلبيات اليومي'
                : 'فتح صندوق المبيعات اليومي',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!salesOrders) ...[
                  Text(
                    'salesDailyOpeningCountHint'.tr,
                    style: const TextStyle(color: dialogTextColor),
                  ),
                  SizedBox(height: 12.h),
                ],
                if (!salesOrders)
                  ...expectedRows.map((row) {
                    final previous = row.previousEmployeeName?.trim();
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.currency,
                            style: const TextStyle(
                              color: dialogTitleColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'salesDailyExpectedOpening'.trParams({
                              'amount': row.expectedAmount.toStringAsFixed(0),
                              'currency': row.currency,
                              'employee': previous?.isNotEmpty == true
                                  ? previous!
                                  : '—',
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
                            style: const TextStyle(color: dialogTitleColor),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'salesDailyCountedOpening'.tr,
                              labelStyle:
                                  const TextStyle(color: dialogMutedColor),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                if (salesOrders) ...[
                  const Text(
                    'أدخل رصيد افتتاح صندوق الطلبيات فقط.',
                    style: TextStyle(color: dialogTextColor),
                  ),
                  SizedBox(height: 12.h),
                  ...ordersExpectedRows.map((row) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: TextField(
                          controller: ordersControllers[row.currency],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'رصيد الافتتاح — ${row.currency}',
                            helperText:
                                'المتوقع: ${row.expectedAmount.toStringAsFixed(0)} ${row.currency}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      )),
                ],
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
                final ordersCounts = ordersExpectedRows
                    .map<Map<String, dynamic>>(
                      (row) => {
                        'currency': row.currency,
                        'physical_count': _parseOpeningAmount(
                          ordersControllers[row.currency]?.text,
                        ),
                      },
                    )
                    .toList();
                Navigator.pop(ctx, {
                  'instant_sales': counts,
                  'sales_orders': ordersCounts,
                });
              },
              child: Text('salesDailyOpenDrawer'.tr),
            ),
          ],
        ),
      );
      if (result == null) return;
      final counts = result['instant_sales'] ?? const [];
      final ordersCounts = result['sales_orders'] ?? const [];
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
      final ordersVarianceRows = ordersExpectedRows.where((row) {
        final input = ordersCounts.firstWhere(
          (item) => item['currency'] == row.currency,
          orElse: () => <String, dynamic>{'physical_count': 0},
        );
        final counted = (input['physical_count'] as num).toDouble();
        return (counted - row.expectedAmount).abs() > 0.0001;
      }).toList();

      var confirmVariance = false;
      if (varianceRows.isNotEmpty || ordersVarianceRows.isNotEmpty) {
        if (!context.mounted) return;
        final isOrdersVariance = varianceRows.isEmpty;
        final row =
            isOrdersVariance ? ordersVarianceRows.first : varianceRows.first;
        final sourceCounts = isOrdersVariance ? ordersCounts : counts;
        final input = sourceCounts.firstWhere(
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
                  (isOrdersVariance ? 'صندوق الطلبيات: ' : '') +
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
        salesOrdersOpeningCounts: ordersCounts,
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
      for (final ctrl in ordersControllers.values) {
        ctrl.dispose();
      }
    }
  }
}
