import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/instant_sales_model.dart';
import '../controllers/sales_controller.dart';
import '../utils/instant_sale_display.dart';
import '../utils/sales_amount_format.dart';
import 'instant_sale_audit_info.dart';
import 'instant_sale_lines_modal.dart';

/// Table-style list for instant sales, grouped by calendar day.
class InstantSalesTable extends GetView<SalesController> {
  const InstantSalesTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = controller.salesListRevision.value;
      final filterMode = controller.instantSalesPackageFilter.value;
      final groups = controller.orderedInstantSalesGroupsFiltered;

      if (groups.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        key: ValueKey<int>(filterMode),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TableHeaderRow(),
          for (var i = 0; i < groups.length; i++) ...[
            if (i > 0) SizedBox(height: 14.h),
            _DateGroupHeader(
              label: formatInstantSalesDateHeader(
                groups[i].key,
                invoiceCount: groups[i].value.length,
              ),
            ),
            ...groups[i].value.map(
                  (sale) => _InstantSaleTableRow(
                    sale: sale,
                    onInvoiceTap: () =>
                        showInstantSaleLinesModal(context, sale),
                    onLongPress: () =>
                        controller.showInstantSaleActionsSheet(context, sale),
                  ),
                ),
          ],
          SizedBox(height: 4.h),
        ],
      );
    });
  }
}

class _DateGroupHeader extends StatelessWidget {
  final String label;

  const _DateGroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final bg = ThemeService.isDark.value
        ? AppColors.primaryColor.withValues(alpha: 0.15)
        : AppColors.primaryColor.withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 13.sp,
        ),
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

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
      child: const Row(
        children: [
          _HeaderCell('instantSaleInvoice', flex: 2),
          _HeaderCell('instantSaleAudit', flex: 2),
          _HeaderCell('total', flex: 2),
          _HeaderCell('instantSalePieces', flex: 2),
          _HeaderCell('instantSalePartner', flex: 2),
          _HeaderCell('status', flex: 3),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String labelKey;
  final int flex;

  const _HeaderCell(this.labelKey, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        labelKey.tr,
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

class _InstantSaleTableRow extends StatelessWidget {
  final InstantSalesModel sale;
  final VoidCallback onInvoiceTap;
  final VoidCallback onLongPress;

  const _InstantSaleTableRow({
    required this.sale,
    required this.onInvoiceTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final cancelled = sale.isCancelled;
    final fromMaintenance = sale.isFromMaintenance;
    final adjustment = sale.isAdjustmentSale;
    final bg = cancelled
        ? Colors.red.withValues(alpha: 0.06)
        : adjustment
            ? (isDark ? const Color(0xFF3A2513) : const Color(0xFFFFF7ED))
            : fromMaintenance
                ? (isDark ? const Color(0xFF3B2A11) : const Color(0xFFFFF7E6))
                : (isDark ? AppColors.customGreyColor4 : Colors.white);

    return Material(
      color: bg,
      child: InkWell(
        onTap: onInvoiceTap,
        onLongPress: onLongPress,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 11.h),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: adjustment
                    ? const Color(0xFFF97316)
                    : fromMaintenance
                        ? const Color(0xFFF59E0B)
                        : Colors.grey.shade300,
              ),
              right: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: GestureDetector(
                    onTap: onInvoiceTap,
                    onLongPress: onInvoiceTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 4.h,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SaleCompositionBadge(kind: sale.compositionKind),
                          if (adjustment) ...[
                            SizedBox(height: 2.h),
                            _AdjustmentSaleBadge(
                              label:
                                  sale.saleKindLabelAr ?? 'adjustmentSale'.tr,
                            ),
                          ],
                          SizedBox(height: 2.h),
                          SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.center,
                              child: Text(
                                sale.invoiceNumber,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: fromMaintenance
                                      ? const Color(0xFFB45309)
                                      : _invoiceColorForKind(
                                          sale.compositionKind,
                                        ),
                                  decoration: TextDecoration.underline,
                                  decorationColor: fromMaintenance
                                      ? const Color(0xFFB45309)
                                      : _invoiceColorForKind(
                                          sale.compositionKind,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          if (fromMaintenance) ...[
                            SizedBox(height: 2.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 5.w,
                                vertical: 1.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                sale.maintenanceInvoiceNumber ??
                                    'maintenance'.tr,
                                style: TextStyle(
                                  fontSize: 8.sp,
                                  color: const Color(0xFFB45309),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: InstantSaleAuditInfo(sale: sale, compact: true),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      SalesAmountFormat.display(
                        SalesAmountFormat.parse(sale.totalCost),
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: cancelled ? Colors.red.shade700 : null,
                      ),
                    ),
                    if (sale.hasDebtRemaining && !cancelled) ...[
                      SizedBox(height: 2.h),
                      Text(
                        '${'remainingAmount'.tr}: ${SalesAmountFormat.display(sale.remainingAmountValue)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${sale.piecesCount}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sale.partnerTypeDisplay,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      sale.partnerName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: 4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusChip(cancelled: cancelled),
                      SizedBox(width: 2.w),
                      _OperationInfoButton(sale: sale),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationInfoButton extends StatelessWidget {
  const _OperationInfoButton({required this.sale});

  final InstantSalesModel sale;

  @override
  Widget build(BuildContext context) {
    final boxName = _displayBoxName(sale.paymentBoxName);
    final paid = SalesAmountFormat.parse(sale.paymentBoxValue ?? '0');

    return Tooltip(
      message: 'instantSaleOperationDetails'.tr,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => showDialog<void>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'instantSaleOperationDetails'.tr,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OperationInfoRow(
                    label: 'instantSaleOperationBox'.tr,
                    value: boxName,
                  ),
                  SizedBox(height: 8.h),
                  _OperationInfoRow(
                    label: 'instantSaleCreatedTime'.tr,
                    value: _formatSaleTime(sale),
                  ),
                  if (paid > 0) ...[
                    SizedBox(height: 8.h),
                    _OperationInfoRow(
                      label: 'paidAmount'.tr,
                      value: SalesAmountFormat.display(paid),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('close'.tr),
                ),
              ],
            );
          },
        ),
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: Icon(
            Icons.info_outline,
            size: 20.sp,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _OperationInfoRow extends StatelessWidget {
  const _OperationInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

String _displayBoxName(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return '—';

  return value
      .replaceFirst('صندوق مبيعات يومي - ', '')
      .replaceFirst('Daily sales box - ', '');
}

String _formatSaleTime(InstantSalesModel sale) {
  final time = sale.createdAt ?? sale.date;
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Color _invoiceColorForKind(String kind) {
  switch (kind) {
    case 'mixed':
      return const Color(0xFF6A1B9A);
    case 'package':
      return const Color(0xFFE65100);
    default:
      return AppColors.primaryColor;
  }
}

class _SaleCompositionBadge extends StatelessWidget {
  const _SaleCompositionBadge({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late String labelKey;
    switch (kind) {
      case 'mixed':
        bg = const Color(0xFF6A1B9A);
        labelKey = 'instantSaleCompositionMixed';
        break;
      case 'package':
        bg = const Color(0xFFE65100);
        labelKey = 'instantSaleCompositionPackage';
        break;
      default:
        bg = AppColors.secondaryColor;
        labelKey = 'instantSaleCompositionProduct';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        labelKey.tr,
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdjustmentSaleBadge extends StatelessWidget {
  const _AdjustmentSaleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool cancelled;

  const _StatusChip({required this.cancelled});

  @override
  Widget build(BuildContext context) {
    final color = cancelled ? Colors.red : const Color(0xFF1B8A4A);
    final label = cancelled ? 'cancelled'.tr : 'saleStatusActive'.tr;
    final icon = cancelled ? Icons.cancel_outlined : Icons.check_circle_outline;

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Container(
          width: 30.w,
          height: 30.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Icon(
            icon,
            size: 19.sp,
            color: color,
          ),
        ),
      ),
    );
  }
}
