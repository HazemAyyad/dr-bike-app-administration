import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/customer_product_price_history_model.dart';
import '../../controllers/sales_controller.dart';
import '../../models/instant_sale_cart_line.dart';
import '../../utils/sales_amount_format.dart';
import '../../../../stock/presentation/utils/open_instant_sale_invoice.dart';

Future<void> showInstantSalePriceHistorySheet(
  BuildContext context, {
  required InstantSaleCartLine line,
  int? cartLineIndex,
  bool allowApply = false,
}) async {
  final controller = Get.find<SalesController>();

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => Dialog(
      backgroundColor: AdminUiColors.cardBackground(ctx),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: const Center(child: CircularProgressIndicator()),
      ),
    ),
  );

  final history = await controller.fetchLinePriceHistory(
    productId: line.productId,
    sizeColorId: line.sizeColorId,
  );

  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PriceHistorySheet(
      line: line,
      history: history,
      cartLineIndex: cartLineIndex,
      allowApply: allowApply,
    ),
  );
}

class _PriceHistorySheet extends StatelessWidget {
  const _PriceHistorySheet({
    required this.line,
    required this.history,
    this.cartLineIndex,
    this.allowApply = false,
  });

  final InstantSaleCartLine line;
  final CustomerProductPriceHistory? history;
  final int? cartLineIndex;
  final bool allowApply;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();
    final entries = history?.entries ?? const <CustomerProductPriceEntry>[];
    final hasPartner = controller.hasPickerPartner;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        constraints: BoxConstraints(maxHeight: 0.55.sh),
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: AdminUiColors.cardBackground(context),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hasPartner
                  ? 'instantSaleLastPricesTitle'.tr
                  : 'instantSaleRecentSalesTitle'.tr,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              line.displayName,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
            ),
            if (allowApply) ...[
              SizedBox(height: 4.h),
              Text(
                'instantSaleTapPriceToApply'.tr,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
              ),
            ],
            SizedBox(height: 12.h),
            if (entries.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  hasPartner
                      ? 'instantSaleNoPriceHistory'.tr
                      : 'instantSaleNoRecentSales'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => Divider(height: 1.h),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        SalesAmountFormat.display(entry.cost),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${'billNumber'.tr}: ${entry.invoiceId}'
                        '${entry.soldAt.isNotEmpty ? '\n${entry.soldAt}' : ''}',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (allowApply)
                            Icon(
                              Icons.check_circle_outline,
                              size: 20.sp,
                              color: AppColors.primaryColor,
                            ),
                          SizedBox(width: 4.w),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'billDetails'.tr,
                            icon: Icon(Icons.receipt_long_outlined, size: 20.sp),
                            onPressed: () {
                              Navigator.pop(context);
                              openInstantSaleInvoiceFromStock(
                                context: context,
                                saleId: entry.invoiceId.toString(),
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: allowApply && cartLineIndex != null
                          ? () {
                              controller.applyHistoricalPriceToCartLine(
                                cartLineIndex!,
                                entry.cost,
                              );
                              Navigator.pop(context);
                              Get.snackbar(
                                'success'.tr,
                                'instantSalePriceApplied'.tr,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          : () {
                              Navigator.pop(context);
                              openInstantSaleInvoiceFromStock(
                                context: context,
                                saleId: entry.invoiceId.toString(),
                              );
                            },
                    );
                  },
                ),
              ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('close'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InstantSalePriceHistoryButton extends StatelessWidget {
  const InstantSalePriceHistoryButton({
    Key? key,
    required this.line,
    this.cartLineIndex,
    this.compact = false,
    this.allowApply = false,
    this.forceShow = false,
  }) : super(key: key);

  final InstantSaleCartLine line;
  final int? cartLineIndex;
  final bool compact;
  final bool allowApply;
  final bool forceShow;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();

    return Obx(() {
      final _ = controller.cartRevision.value;
      final ___ = controller.pickerSellerIdRx.value;
      if (!forceShow && !controller.hasPickerPartner) {
        return const SizedBox.shrink();
      }

      if (compact) {
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 24.w, minHeight: 24.w),
          visualDensity: VisualDensity.compact,
          tooltip: 'instantSaleLastPrices'.tr,
          onPressed: () => showInstantSalePriceHistorySheet(
            context,
            line: line,
            cartLineIndex: cartLineIndex,
            allowApply: allowApply,
          ),
          icon: Icon(Icons.history, size: 16.sp, color: AppColors.primaryColor),
        );
      }

      return TextButton.icon(
        onPressed: () => showInstantSalePriceHistorySheet(
          context,
          line: line,
          cartLineIndex: cartLineIndex,
          allowApply: allowApply,
        ),
        icon: Icon(Icons.history, size: 18.sp),
        label: Text(
          'instantSaleLastPrices'.tr,
          style: TextStyle(fontSize: 12.sp),
        ),
      );
    });
  }
}
