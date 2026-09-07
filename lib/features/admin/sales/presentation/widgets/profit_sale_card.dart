import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/profit_sale_model.dart';
import '../controllers/sales_controller.dart';
import '../utils/product_image_viewer.dart';
import '../utils/sales_amount_format.dart';

class ProfitSalesTable extends GetView<SalesController> {
  const ProfitSalesTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = controller.salesListRevision.value;
      final groups = controller.salesService.filterProfitSalesTasks.entries
          .where((entry) => entry.value.isNotEmpty)
          .toList();

      if (groups.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ProfitTableHeaderRow(),
          for (final group in groups)
            ...group.value.map(
              (sale) => _ProfitSaleTableRow(sale: sale),
            ),
          SizedBox(height: 4.h),
        ],
      );
    });
  }
}

class _ProfitTableHeaderRow extends StatelessWidget {
  const _ProfitTableHeaderRow();

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
          _ProfitHeaderCell('instantSaleInvoice', flex: 2),
          _ProfitHeaderCell('instantSaleAudit', flex: 2),
          _ProfitHeaderCell('total', flex: 2),
          _ProfitHeaderCell('details', flex: 2),
          _ProfitHeaderCell('customerName', flex: 2),
          _ProfitHeaderCell('status', flex: 3),
        ],
      ),
    );
  }
}

class _ProfitHeaderCell extends StatelessWidget {
  const _ProfitHeaderCell(this.labelKey, {required this.flex});

  final String labelKey;
  final int flex;

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

class _ProfitSaleTableRow extends StatelessWidget {
  const _ProfitSaleTableRow({required this.sale});

  final ProfitSale sale;

  @override
  Widget build(BuildContext context) {
    final cancelled = sale.isCancelled;
    final bg = cancelled
        ? Colors.red.withValues(alpha: 0.06)
        : (ThemeService.isDark.value
            ? AppColors.customGreyColor4
            : Colors.white);

    return Material(
      color: bg,
      child: InkWell(
        onLongPress: () =>
            Get.find<SalesController>().confirmCancelProfitSale(context, sale),
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
              _ProfitInvoiceCell(sale: sale),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatProfitSaleTime(sale),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _displayProfitBoxName(sale.paymentBoxName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _ProfitTextCell(
                SalesAmountFormat.display(
                  SalesAmountFormat.parse(sale.totalCost),
                ),
                flex: 2,
                strong: true,
              ),
              _ProfitTextCell(sale.notes, flex: 2),
              _ProfitTextCell(sale.partnerDisplay, flex: 2),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: 4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProfitStatusChip(cancelled: cancelled),
                      SizedBox(width: 2.w),
                      _ProfitOperationInfoButton(sale: sale),
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

class _ProfitInvoiceCell extends StatelessWidget {
  const _ProfitInvoiceCell({required this.sale});

  final ProfitSale sale;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: InkWell(
        onTap: () => showProfitSaleDetailsModal(context, sale),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Text(
            '#${sale.id}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfitStatusChip extends StatelessWidget {
  const _ProfitStatusChip({required this.cancelled});

  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final color = cancelled ? Colors.red : const Color(0xFF1B8A4A);
    final label = cancelled ? 'cancelled'.tr : 'saleStatusActive'.tr;

    return Tooltip(
      message: label,
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
          cancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
          size: 19.sp,
          color: color,
        ),
      ),
    );
  }
}

class _ProfitOperationInfoButton extends StatelessWidget {
  const _ProfitOperationInfoButton({required this.sale});

  final ProfitSale sale;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'instantSaleOperationDetails'.tr,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => showProfitSaleDetailsModal(context, sale),
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

String _displayProfitBoxName(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return '—';

  return value
      .replaceFirst('صندوق مبيعات يومي - ', '')
      .replaceFirst('Daily sales box - ', '');
}

String _formatProfitSaleTime(ProfitSale sale) {
  final local = sale.createdAt.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

void showProfitSaleDetailsModal(BuildContext context, ProfitSale sale) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProfitSaleDetailsSheet(sale: sale),
  );
}

class _ProfitSaleDetailsSheet extends StatelessWidget {
  const _ProfitSaleDetailsSheet({required this.sale});

  final ProfitSale sale;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final total = SalesAmountFormat.parse(sale.totalCost);
    final paid = SalesAmountFormat.parse(sale.paymentBoxValue ?? '0');
    final remaining = (total - paid).clamp(0, double.infinity).toDouble();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.85.sh),
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.customGreyColor4 : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'newCashProfit'.tr} #${sale.id}',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          sale.partnerDisplay,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade300),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                children: [
                  _ProfitDetailRow(label: 'details'.tr, value: sale.notes),
                  _ProfitDetailRow(
                    label: 'customerName'.tr,
                    value: sale.partnerDisplay,
                  ),
                  _ProfitDetailRow(
                    label: 'boxName'.tr,
                    value: sale.paymentBoxName?.trim().isNotEmpty == true
                        ? sale.paymentBoxName!
                        : '-',
                  ),
                  SizedBox(height: 12.h),
                  _ProfitMediaRow(sale: sale),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? AppColors.customGreyColor : Colors.grey.shade50,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16.r),
                ),
              ),
              child: Column(
                children: [
                  _ProfitTotalRow(label: 'totalBill'.tr, value: total),
                  SizedBox(height: 6.h),
                  _ProfitTotalRow(
                    label: 'paidAmount'.tr,
                    value: paid,
                    color: Colors.green.shade700,
                  ),
                  SizedBox(height: 6.h),
                  _ProfitTotalRow(
                    label: 'remainingAmount'.tr,
                    value: remaining,
                    color: remaining > 0 ? Colors.red.shade700 : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfitDetailRow extends StatelessWidget {
  const _ProfitDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(fontSize: 12.sp, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitMediaRow extends StatelessWidget {
  const _ProfitMediaRow({required this.sale});

  final ProfitSale sale;

  @override
  Widget build(BuildContext context) {
    final hasImage = sale.imagePath?.trim().isNotEmpty == true;
    final hasVideo = sale.videoPath?.trim().isNotEmpty == true;

    if (!hasImage && !hasVideo) {
      return _ProfitDetailRow(label: 'attachments'.tr, value: '-');
    }

    return Row(
      children: [
        SizedBox(
          width: 95.w,
          child: Text(
            'attachments'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        if (hasImage)
          IconButton(
            tooltip: 'invoiceImage'.tr,
            onPressed: () => openProductImageViewer(context, sale.imagePath!),
            icon: Icon(
              Icons.image_outlined,
              color: AppColors.primaryColor,
              size: 24.sp,
            ),
          ),
        if (hasVideo)
          Icon(
            Icons.videocam_outlined,
            color: AppColors.primaryColor,
            size: 24.sp,
          ),
      ],
    );
  }
}

class _ProfitTotalRow extends StatelessWidget {
  const _ProfitTotalRow({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '${SalesAmountFormat.display(value)} ${'currency'.tr}',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProfitTextCell extends StatelessWidget {
  const _ProfitTextCell(
    this.text, {
    required this.flex,
    this.strong = false,
  });

  final String text;
  final int flex;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor6
              : AppColors.customGreyColor5,
        ),
      ),
    );
  }
}

class ProfitSaleCard extends GetView<SalesController> {
  const ProfitSaleCard({Key? key, required this.profitSale}) : super(key: key);

  final ProfitSale profitSale;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor4
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(32),
            blurRadius: 5.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
              child: Row(
                children: [
                  // الصورة
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: Image.asset(
                      AssetsManager.salesImage,
                      width: 50.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // التفاصيل
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            profitSale.notes.toString(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w400,
                                  color: ThemeService.isDark.value
                                      ? AppColors.customGreyColor6
                                      : AppColors.customGreyColor5,
                                ),
                          ),
                        ),
                        if ((profitSale.imagePath?.isNotEmpty ?? false) ||
                            (profitSale.videoPath?.isNotEmpty ?? false)) ...[
                          SizedBox(height: 5.h),
                          Wrap(
                            spacing: 6.w,
                            alignment: WrapAlignment.center,
                            children: [
                              if (profitSale.imagePath?.isNotEmpty ?? false)
                                Icon(Icons.image_outlined,
                                    size: 16.sp, color: AppColors.primaryColor),
                              if (profitSale.videoPath?.isNotEmpty ?? false)
                                Icon(Icons.videocam_outlined,
                                    size: 16.sp, color: AppColors.primaryColor),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // الإجمالي
          Container(
            constraints: BoxConstraints(minWidth: 72.w, maxWidth: 110.w),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.customGreen1,
              borderRadius: Get.locale!.languageCode == 'en'
                  ? const BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.currentTab.value == 0 ? 'total'.tr : 'price'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                ),
                SizedBox(height: 4.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    SalesAmountFormat.display(
                      SalesAmountFormat.parse(profitSale.totalCost),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor5,
                ),
          ),
        ),
        if (value.isNotEmpty) ...[
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor5,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
