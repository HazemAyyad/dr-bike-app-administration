import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../../core/helpers/show_net_image.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/utils/sale_variant_display.dart';
import '../../models/instant_sale_cart_line.dart';
import '../../utils/product_image_viewer.dart';
import '../../utils/sales_amount_format.dart';
import 'instant_sale_price_history_sheet.dart';

void showInstantSaleCartLineSheet(
  BuildContext context,
  InstantSaleCartLine line,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _InstantSaleCartLineSheet(line: line),
  );
}

class _InstantSaleCartLineSheet extends StatelessWidget {
  const _InstantSaleCartLineSheet({required this.line});

  final InstantSaleCartLine line;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        constraints: BoxConstraints(maxHeight: 0.75.sh),
        decoration: BoxDecoration(
          color: AdminUiColors.cardBackground(context),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'productDetails'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: cs.onSurface),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _image(context),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      line.productName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
              ),
              if (hasProductVariant(
                sizeLabel: line.sizeLabel,
                colorLabel: line.colorLabel,
              )) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        context,
                        label: 'size'.tr,
                        value: variantDashOrValue(line.sizeLabel),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _infoTile(
                        context,
                        label: 'color'.tr,
                        value: variantDashOrValue(line.colorLabel),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _infoTile(
                      context,
                      label: 'quantity'.tr,
                      value: line.quantityText.isEmpty ? '—' : line.quantityText,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _infoTile(
                      context,
                      label: 'price'.tr,
                      value: line.priceText.isEmpty
                          ? '—'
                          : SalesAmountFormat.display(
                              SalesAmountFormat.parse(line.priceText),
                            ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              _infoTile(
                context,
                label: 'total'.tr,
                value: SalesAmountFormat.display(line.lineTotal.value),
              ),
              SizedBox(height: 8.h),
              _infoTile(
                context,
                label: 'stock'.tr,
                value: '${line.stock}',
              ),
              SizedBox(height: 12.h),
              InstantSalePriceHistoryButton(line: line),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(BuildContext context) {
    final url = ShowNetImage.getThumbnailPhoto(line.imageUrl);
    final ok = url.isNotEmpty && line.imageUrl != 'no image';

    return GestureDetector(
      onTap: () => openProductImageViewer(context, line.imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: SizedBox(
          width: 72.w,
          height: 72.w,
          child: ok
              ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
              : ColoredBox(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 28.sp,
                    color: Colors.grey,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _infoTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                ),
          ),
        ],
      ),
    );
  }
}
