import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/suspended_instant_sale_model.dart';
import '../utils/sales_amount_format.dart';
import '../utils/suspended_invoice_display.dart';

class SuspendedInvoicesTable extends StatelessWidget {
  const SuspendedInvoicesTable({
    Key? key,
    required this.items,
    required this.showOwner,
    required this.onResume,
    required this.onNotes,
    required this.onCancel,
  }) : super(key: key);

  final List<SuspendedInstantSaleModel> items;
  final bool showOwner;
  final ValueChanged<SuspendedInstantSaleModel> onResume;
  final ValueChanged<SuspendedInstantSaleModel> onNotes;
  final ValueChanged<SuspendedInstantSaleModel> onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SuspendedTableHeader(showOwner: showOwner),
        for (var i = 0; i < items.length; i++) ...[
          _SuspendedTableRow(
            item: items[i],
            showOwner: showOwner,
            onResume: () => onResume(items[i]),
            onNotes: () => onNotes(items[i]),
            onCancel: () => onCancel(items[i]),
          ),
          if (i < items.length - 1)
            Divider(height: 1, color: Colors.grey.shade300),
        ],
      ],
    );
  }
}

class _SuspendedTableHeader extends StatelessWidget {
  const _SuspendedTableHeader({required this.showOwner});

  final bool showOwner;

  @override
  Widget build(BuildContext context) {
    final bg = ThemeService.isDark.value
        ? AppColors.customGreyColor
        : const Color(0xFFEEF4FF);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const _HeaderCell('instantSaleInvoice', flex: 2),
          if (showOwner) const _HeaderCell('suspendedInvoiceOwner', flex: 2),
          const _HeaderCell('total', flex: 2),
          const _HeaderCell('date', flex: 2),
          const _HeaderCell('actions', flex: 3),
        ],
      ),
    );
  }
}

class _SuspendedTableRow extends StatelessWidget {
  const _SuspendedTableRow({
    required this.item,
    required this.showOwner,
    required this.onResume,
    required this.onNotes,
    required this.onCancel,
  });

  final SuspendedInstantSaleModel item;
  final bool showOwner;
  final VoidCallback onResume;
  final VoidCallback onNotes;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey.shade300;
    final summary = item.summaryLabel.isNotEmpty
        ? item.summaryLabel
        : 'suspendedInvoicesDefaultLabel'.tr;

    return Container(
      decoration: BoxDecoration(
        color: ThemeService.isDark.value ? AppColors.darkColor : Colors.white,
        border: Border(
          left: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.referenceCode,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE65100),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.sp),
                ),
              ],
            ),
          ),
          if (showOwner)
            Expanded(
              flex: 2,
              child: Text(
                item.createdByName ?? '-',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
          Expanded(
            flex: 2,
            child: Text(
              SalesAmountFormat.display(item.totalCost),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatSuspendedInvoiceDateTime(item.suspendedAt),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10.sp,
                height: 1.25,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionTap(
                      tooltip: 'suspendedInvoiceNotes'.tr,
                      icon: item.noteCount > 0
                          ? Icons.speaker_notes_rounded
                          : Icons.note_add_rounded,
                      color: Colors.blueGrey.shade700,
                      onTap: onNotes,
                    ),
                    SizedBox(width: 2.w),
                    _ActionTap(
                      tooltip: 'suspendedInvoiceResume'.tr,
                      icon: Icons.play_arrow_rounded,
                      color: AppColors.primaryColor,
                      onTap: onResume,
                    ),
                    SizedBox(width: 2.w),
                    _ActionTap(
                      tooltip: 'suspendedInvoiceCancel'.tr,
                      icon: Icons.close_rounded,
                      color: Colors.red.shade700,
                      onTap: onCancel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTap extends StatelessWidget {
  const _ActionTap({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Icon(icon, color: color, size: 20.sp),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label.tr,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}
