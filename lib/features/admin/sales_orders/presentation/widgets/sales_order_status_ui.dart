import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';

/// ألوان وشارات حالة الطلبية + مسار سير العمل الرئيسي.
class SalesOrderStatusUi {
  SalesOrderStatusUi._();

  static const workflowSteps = [
    'unconfirmed',
    'confirmed',
    'ready',
    'with_delivery',
    'delivered',
    'archived',
  ];

  static Color statusColor(String status) {
    switch (status) {
      case 'unconfirmed':
        return const Color(0xFF6B7280);
      case 'confirmed':
        return const Color(0xFF2563EB);
      case 'ready':
        return const Color(0xFF7C3AED);
      case 'with_delivery':
        return const Color(0xFFD97706);
      case 'delivered':
        return const Color(0xFF059669);
      case 'archived':
        return const Color(0xFF374151);
      case 'review':
      case 'partial_delivered':
        return const Color(0xFFEA580C);
      case 'partial_return':
      case 'alternative_return':
      case 'returned':
        return const Color(0xFFDC2626);
      case 'postponed':
        return const Color(0xFF9333EA);
      case 'canceled':
        return const Color(0xFF9CA3AF);
      default:
        return SalesOrdersController.textSecondary;
    }
  }

  static Color statusBg(String status) => statusColor(status).withValues(alpha: 0.12);

  static int workflowIndex(String status) {
    if (status == 'review' || status == 'partial_delivered') {
      return workflowSteps.indexOf('with_delivery');
    }
    if (status == 'partial_return' ||
        status == 'alternative_return' ||
        status == 'returned') {
      return workflowSteps.indexOf('delivered');
    }
    if (status == 'postponed') {
      return workflowSteps.indexOf('unconfirmed');
    }
    if (status == 'canceled') {
      return -1;
    }
    final idx = workflowSteps.indexOf(status);
    return idx >= 0 ? idx : 0;
  }

  static Widget statusBadge(String status, SalesOrdersController controller) {
    final color = statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        controller.statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget workflowTimeline({
    required String status,
    required SalesOrdersController controller,
  }) {
    final activeIdx = workflowIndex(status);
    final isCanceled = status == 'canceled';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SalesOrdersController.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'salesOrderWorkflow'.tr,
            style: TextStyle(
              color: SalesOrdersController.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 12.h),
          if (isCanceled)
            Text(
              'salesOrderStatusCanceled'.tr,
              style: TextStyle(color: statusColor('canceled'), fontSize: 12.sp),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(workflowSteps.length, (i) {
                  final step = workflowSteps[i];
                  final done = i < activeIdx;
                  final current = i == activeIdx;
                  final color = done || current
                      ? statusColor(step)
                      : SalesOrdersController.borderGray;
                  return Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done || current
                                  ? color.withValues(alpha: 0.15)
                                  : SalesOrdersController.surfaceGray,
                              border: Border.all(
                                color: color,
                                width: current ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              done
                                  ? Icons.check_rounded
                                  : current
                                      ? Icons.radio_button_checked
                                      : Icons.circle_outlined,
                              size: 14.sp,
                              color: color,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          SizedBox(
                            width: 56.w,
                            child: Text(
                              controller.statusLabel(step),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: current
                                    ? SalesOrdersController.textPrimary
                                    : SalesOrdersController.textSecondary,
                                fontWeight:
                                    current ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (i < workflowSteps.length - 1)
                        Container(
                          width: 20.w,
                          height: 2,
                          margin: EdgeInsets.only(bottom: 28.h),
                          color: i < activeIdx
                              ? statusColor(workflowSteps[i + 1])
                              : SalesOrdersController.borderGray,
                        ),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

/// إجراء متاح على الطلبية (للزر الرئيسي أو قائمة الإجراءات).
enum SalesOrderActionId {
  confirm,
  markReady,
  handover,
  deliver,
  partialDeliver,
  partialReturn,
  followUp,
  settle,
  archive,
  share,
  uploadMedia,
  cancel,
  revertStatus,
}

class SalesOrderActionDef {
  const SalesOrderActionDef({
    required this.id,
    required this.labelKey,
    this.isPrimary = false,
    this.isDanger = false,
  });

  final SalesOrderActionId id;
  final String labelKey;
  final bool isPrimary;
  final bool isDanger;

  String get label => labelKey.tr;
}

class SalesOrderActions {
  SalesOrderActions._();

  static bool canRevert(String status) {
    return const {
      'confirmed',
      'ready',
      'with_delivery',
      'postponed',
    }.contains(status);
  }

  static List<SalesOrderActionDef> forStatus(String status) {
    final actions = _baseActionsFor(status);
    if (canRevert(status)) {
      return [
        ...actions,
        const SalesOrderActionDef(
          id: SalesOrderActionId.revertStatus,
          labelKey: 'salesOrderRevertStatus',
        ),
      ];
    }
    return actions;
  }

  static List<SalesOrderActionDef> _baseActionsFor(String status) {
    switch (status) {
      case 'unconfirmed':
        return const [
          SalesOrderActionDef(
            id: SalesOrderActionId.confirm,
            labelKey: 'confirm',
            isPrimary: true,
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.uploadMedia,
            labelKey: 'salesOrderUploadMedia',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.share,
            labelKey: 'salesOrderShare',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.cancel,
            labelKey: 'cancel',
            isDanger: true,
          ),
        ];
      case 'confirmed':
        return const [
          SalesOrderActionDef(
            id: SalesOrderActionId.markReady,
            labelKey: 'salesOrderMarkReady',
            isPrimary: true,
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.uploadMedia,
            labelKey: 'salesOrderUploadMedia',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.share,
            labelKey: 'salesOrderShare',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.cancel,
            labelKey: 'cancel',
            isDanger: true,
          ),
        ];
      case 'ready':
        return const [
          SalesOrderActionDef(
            id: SalesOrderActionId.handover,
            labelKey: 'salesOrderHandover',
            isPrimary: true,
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.uploadMedia,
            labelKey: 'salesOrderUploadMedia',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.share,
            labelKey: 'salesOrderShare',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.cancel,
            labelKey: 'cancel',
            isDanger: true,
          ),
        ];
      case 'with_delivery':
        return const [
          SalesOrderActionDef(
            id: SalesOrderActionId.deliver,
            labelKey: 'salesOrderDeliver',
            isPrimary: true,
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.partialDeliver,
            labelKey: 'salesOrderPartialDeliver',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.partialReturn,
            labelKey: 'salesOrderPartialReturn',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.uploadMedia,
            labelKey: 'salesOrderUploadMedia',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.share,
            labelKey: 'salesOrderShare',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.cancel,
            labelKey: 'cancel',
            isDanger: true,
          ),
        ];
      case 'review':
      case 'partial_delivered':
        return const [
          SalesOrderActionDef(
            id: SalesOrderActionId.partialDeliver,
            labelKey: 'salesOrderPartialDeliver',
            isPrimary: true,
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.followUp,
            labelKey: 'salesOrderFollowUp',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.uploadMedia,
            labelKey: 'salesOrderUploadMedia',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.share,
            labelKey: 'salesOrderShare',
          ),
        ];
      case 'delivered':
        return const [
          SalesOrderActionDef(
            id: SalesOrderActionId.settle,
            labelKey: 'salesOrderSettle',
            isPrimary: true,
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.archive,
            labelKey: 'salesOrderArchive',
          ),
          SalesOrderActionDef(
            id: SalesOrderActionId.share,
            labelKey: 'salesOrderShare',
          ),
        ];
      case 'archived':
      case 'canceled':
      case 'returned':
        return const [
          SalesOrderActionDef(
            id: SalesOrderActionId.share,
            labelKey: 'salesOrderShare',
          ),
        ];
      default:
        return const [
          SalesOrderActionDef(
            id: SalesOrderActionId.share,
            labelKey: 'salesOrderShare',
          ),
        ];
    }
  }

  static SalesOrderActionDef? primaryFor(String status) {
    for (final a in forStatus(status)) {
      if (a.isPrimary) return a;
    }
    return null;
  }

  static List<SalesOrderActionDef> secondaryFor(String status) {
    return forStatus(status).where((a) => !a.isPrimary).toList();
  }
}
