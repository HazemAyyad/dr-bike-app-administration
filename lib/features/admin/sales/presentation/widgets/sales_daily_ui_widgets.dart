import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/daily_session_model.dart';
import '../utils/sales_daily_status_ui.dart';

class SalesDailyStatusBadge extends StatelessWidget {
  const SalesDailyStatusBadge({
    Key? key,
    required this.status,
    this.compact = true,
  }) : super(key: key);

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = SalesDailyStatusUi.colorFor(status);
    final label = compact
        ? SalesDailyStatusUi.shortLabelFor(status)
        : SalesDailyStatusUi.labelFor(status);
    final icon = SalesDailyStatusUi.iconFor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class SalesDailyRequestStatusBadge extends StatelessWidget {
  const SalesDailyRequestStatusBadge({Key? key, required this.status})
      : super(key: key);

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = Colors.green.shade700;
        label = 'salesDailyRequestApproved'.tr;
        break;
      case 'rejected':
        color = Colors.red.shade700;
        label = 'salesDailyRequestRejected'.tr;
        break;
      default:
        color = Colors.orange.shade800;
        label = 'salesDailyRequestPending'.tr;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SalesDailySummaryStrip extends StatelessWidget {
  const SalesDailySummaryStrip({
    Key? key,
    required this.openCount,
    required this.pendingCount,
    required this.closedCount,
  }) : super(key: key);

  final int openCount;
  final int pendingCount;
  final int closedCount;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final bg = isDark ? AppColors.darkColor : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _cell(
                count: openCount,
                label: 'salesDailyStatusOpen'.tr,
                color: AppColors.primaryColor,
              ),
            ),
            VerticalDivider(width: 1, color: Colors.grey.shade300),
            Expanded(
              child: _cell(
                count: pendingCount,
                label: 'salesDailyStatusPending'.tr,
                color: Colors.orange.shade800,
              ),
            ),
            VerticalDivider(width: 1, color: Colors.grey.shade300),
            Expanded(
              child: _cell(
                count: closedCount,
                label: 'salesDailyStatusClosed'.tr,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell({
    required int count,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class SalesDailySessionTile extends StatelessWidget {
  const SalesDailySessionTile({
    Key? key,
    required this.item,
    required this.onTap,
    this.showEmployee = true,
  }) : super(key: key);

  final DailySessionSummaryModel item;
  final VoidCallback onTap;
  final bool showEmployee;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final title = showEmployee && (item.employeeName?.isNotEmpty ?? false)
        ? item.employeeName!
        : item.businessDate;

    return Material(
      color: isDark ? AppColors.darkColor : Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
                child: Icon(
                  Icons.person_outline,
                  size: 16.sp,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SalesDailyStatusBadge(status: item.status),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                        height: 1.2,
                      ),
                    ),
                    if (item.currencies.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      _currencyStrip(),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                size: 18.sp,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final parts = <String>[
      if (showEmployee && (item.employeeName?.isNotEmpty ?? false))
        item.businessDate,
      '${'instant_sales'.tr}:${item.instantSalesCount}',
      '${'cashProfit'.tr}:${item.profitSalesCount}',
      if (item.closedOnNextDay) 'salesDailyClosedOnNextDayShort'.tr,
    ];
    return parts.join('  •  ');
  }

  Widget _currencyStrip() {
    return Wrap(
      spacing: 6.w,
      runSpacing: 2.h,
      children: item.currencies.map((c) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            '${c.currency} ${c.boxBalance.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SalesDailyCurrencyTable extends StatelessWidget {
  const SalesDailyCurrencyTable({
    Key? key,
    required this.currencies,
  }) : super(key: key);

  final List<DailyCurrencyRow> currencies;

  @override
  Widget build(BuildContext context) {
    if (currencies.isEmpty) {
      return Text('noData'.tr, style: TextStyle(fontSize: 12.sp));
    }

    final isDark = ThemeService.isDark.value;
    final headerBg = isDark
        ? AppColors.primaryColor.withValues(alpha: 0.15)
        : AppColors.primaryColor.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: headerBg,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'salesDailyCurrencyCol'.tr,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                Expanded(child: _head('salesDailyOpeningFloat'.tr)),
                Expanded(child: _head('salesDailySalesCollected'.tr)),
                Expanded(child: _head('salesDailySystemBalance'.tr)),
                Expanded(child: _head('salesDailyBoxBalance'.tr)),
              ],
            ),
          ),
          ...currencies.asMap().entries.map((entry) {
            final row = entry.value;
            final last = entry.key == currencies.length - 1;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
              decoration: BoxDecoration(
                border: last
                    ? null
                    : Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.currency,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(child: _val(row.openingFloat)),
                  Expanded(child: _val(row.salesCollected)),
                  Expanded(child: _val(row.systemBalance, bold: true)),
                  Expanded(child: _val(row.boxBalance)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _head(String text) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 8.sp,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
        height: 1.1,
      ),
    );
  }

  Widget _val(double value, {bool bold = false}) {
    return Text(
      value.toStringAsFixed(0),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 10.sp,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      ),
    );
  }
}

class SalesDailyDetailHeader extends StatelessWidget {
  const SalesDailyDetailHeader({
    Key? key,
    required this.session,
    required this.instantCount,
    required this.profitCount,
  }) : super(key: key);

  final DailySessionInfo session;
  final int instantCount;
  final int profitCount;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final statusColor = SalesDailyStatusUi.colorFor(session.status);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.14),
            (isDark ? AppColors.darkColor : Colors.white),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.employeeName?.isNotEmpty == true
                      ? session.employeeName!
                      : session.businessDate,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SalesDailyStatusBadge(status: session.status, compact: false),
            ],
          ),
          SizedBox(height: 6.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 4.h,
            children: [
              _meta(Icons.calendar_today_outlined, session.businessDate),
              _meta(Icons.receipt_long_outlined,
                  '${'instant_sales'.tr}: $instantCount'),
              _meta(Icons.payments_outlined,
                  '${'cashProfit'.tr}: $profitCount'),
              if (session.openedAt != null)
                _meta(Icons.login, _shortTime(session.openedAt!)),
              if (session.closedAt != null)
                _meta(Icons.logout, _shortTime(session.closedAt!)),
              if (session.closedOnNextDay)
                _meta(
                  Icons.nightlight_round,
                  'salesDailyClosedOnNextDay'.tr,
                  highlight: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text, {bool highlight = false}) {
    final color = highlight ? Colors.orange.shade800 : Colors.grey.shade600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11.sp, color: color),
        SizedBox(width: 3.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 10.sp,
            color: highlight ? Colors.orange.shade900 : Colors.grey.shade700,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _shortTime(String raw) {
    if (raw.length >= 16) return raw.substring(11, 16);
    return raw;
  }
}

class SalesDailyClosingTile extends StatelessWidget {
  const SalesDailyClosingTile({Key? key, required this.request})
      : super(key: key);

  final DailyClosingHistoryModel request;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkColor : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${request.id}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 6.w),
              SalesDailyRequestStatusBadge(status: request.status),
              const Spacer(),
              if (request.requestedAt != null)
                Text(
                  _shortTime(request.requestedAt!),
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
                ),
            ],
          ),
          if (request.isLateClose) ...[
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                request.requestedDate != null
                    ? 'salesDailyLateCloseOnDate'.trParams({
                        'date': request.requestedDate!,
                      })
                    : 'salesDailyClosedOnNextDay'.tr,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (request.lateCloseReason != null &&
              request.lateCloseReason!.trim().isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              '${'salesDailyLateCloseReason'.tr}: ${request.lateCloseReason}',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade700),
            ),
          ],
          if (request.reviewedBy != null) ...[
            SizedBox(height: 4.h),
            Text(
              '${'salesDailyReviewedBy'.tr}: ${request.reviewedBy}',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
            ),
          ],
          if (request.cashCounts.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: request.cashCounts.map((row) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${row.currency} ${row.physicalCount.toStringAsFixed(0)} → ${row.amountToTransfer.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 9.sp),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _shortTime(String raw) {
    if (raw.length >= 16) return raw.substring(0, 16);
    return raw;
  }
}

class SalesDailySectionTitle extends StatelessWidget {
  const SalesDailySectionTitle({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, top: 4.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}
