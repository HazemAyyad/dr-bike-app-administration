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
              onInvoiceTap: () => showInstantSaleLinesModal(context, sale),
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
      child: Row(
        children: const [
          _HeaderCell('instantSaleInvoice', flex: 2),
          _HeaderCell('instantSaleAudit', flex: 2),
          _HeaderCell('total', flex: 2),
          _HeaderCell('instantSalePieces', flex: 2),
          _HeaderCell('instantSalePartner', flex: 2),
          _HeaderCell('status', flex: 2),
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
    final bg = cancelled
        ? Colors.red.withValues(alpha: 0.06)
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
              left: BorderSide(color: Colors.grey.shade300),
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
                          SizedBox(height: 2.h),
                          Text(
                            sale.invoiceNumber,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: _invoiceColorForKind(sale.compositionKind),
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  _invoiceColorForKind(sale.compositionKind),
                            ),
                          ),
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
                flex: 2,
                child: Center(child: _StatusChip(cancelled: cancelled)),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class _StatusChip extends StatelessWidget {
  final bool cancelled;

  const _StatusChip({required this.cancelled});

  @override
  Widget build(BuildContext context) {
    final color = cancelled ? Colors.red : const Color(0xFF1B8A4A);
    final label = cancelled ? 'cancelled'.tr : 'saleStatusActive'.tr;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
