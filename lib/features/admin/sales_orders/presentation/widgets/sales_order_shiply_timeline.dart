import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/sales_order_model.dart';
import '../controllers/sales_orders_controller.dart';

class SalesOrderShiplyTimeline extends StatelessWidget {
  const SalesOrderShiplyTimeline({
    Key? key,
    required this.tracking,
  }) : super(key: key);

  final SalesOrderShiplyTrackingModel tracking;

  @override
  Widget build(BuildContext context) {
    final sequence = tracking.statusSequence;
    final currentId = tracking.currentStatusId;
    final currentIndex = sequence.indexOf(currentId);
    final eventsByStatus = {
      for (final e in tracking.events) e.parcelStatusId: e,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'shiplyTrackingTimeline'.tr,
          style: TextStyle(
            color: SalesOrdersController.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 10.h),
        ...List.generate(sequence.length, (index) {
          final statusId = sequence[index];
          final isDone = currentIndex >= 0 && index < currentIndex;
          final isCurrent = statusId == currentId;
          final isUpcoming = currentIndex >= 0 && index > currentIndex;
          final event = eventsByStatus[statusId];
          final label = _statusLabel(statusId, event?.statusKey);

          return _TimelineStep(
            label: label,
            note: event?.note,
            occurredAt: event?.occurredAt,
            isDone: isDone,
            isCurrent: isCurrent,
            isUpcoming: isUpcoming,
            isLast: index == sequence.length - 1,
          );
        }),
      ],
    );
  }

  String _statusLabel(int statusId, String? statusKey) {
    if (statusKey != null && statusKey.isNotEmpty) {
      final key = 'shiplyParcelStatus_$statusKey';
      if (key.tr != key) {
        return key.tr;
      }
    }

    final fallback = 'shiplyParcelStatusId_$statusId';
    return fallback.tr != fallback ? fallback.tr : '#$statusId';
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    this.note,
    this.occurredAt,
    required this.isDone,
    required this.isCurrent,
    required this.isUpcoming,
    required this.isLast,
  });

  final String label;
  final String? note;
  final String? occurredAt;
  final bool isDone;
  final bool isCurrent;
  final bool isUpcoming;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = isCurrent
        ? const Color(0xFF2563EB)
        : isDone
            ? const Color(0xFF16A34A)
            : SalesOrdersController.borderGray;
    final lineColor = isDone
        ? const Color(0xFF16A34A)
        : SalesOrdersController.borderGray;
    final titleColor = isUpcoming
        ? SalesOrdersController.textSecondary
        : SalesOrdersController.textPrimary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28.w,
            child: Column(
              children: [
                Container(
                  width: isCurrent ? 14.r : 10.r,
                  height: isCurrent ? 14.r : 10.r,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: const Color(0xFF93C5FD), width: 3)
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.symmetric(vertical: 2.h),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      fontSize: isCurrent ? 13.sp : 12.sp,
                    ),
                  ),
                  if (note != null && note!.trim().isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      note!,
                      style: TextStyle(
                        color: SalesOrdersController.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                  if (occurredAt != null && occurredAt!.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      occurredAt!,
                      style: TextStyle(
                        color: SalesOrdersController.textSecondary,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
