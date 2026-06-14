import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../data/models/product_details_model.dart';

class StockVariantAdjustTarget {
  const StockVariantAdjustTarget({
    required this.sizeColorId,
    required this.sizeLabel,
    required this.colorLabel,
    required this.currentStock,
  });

  final String sizeColorId;
  final String sizeLabel;
  final String colorLabel;
  final int currentStock;

  String get subtitle => '$sizeLabel / $colorLabel';
}

Future<StockVariantAdjustTarget?> showStockVariantAdjustSheet({
  required BuildContext context,
  required ProductDetailsModel product,
}) {
  return showModalBottomSheet<StockVariantAdjustTarget>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _StockVariantAdjustSheet(product: product),
  );
}

class _StockVariantAdjustSheet extends StatelessWidget {
  const _StockVariantAdjustSheet({required this.product});

  final ProductDetailsModel product;

  List<StockVariantAdjustTarget> get _targets {
    final rows = <StockVariantAdjustTarget>[];
    for (final size in product.sizes ?? <Size>[]) {
      final sizeLabel = size.size?.trim().isNotEmpty == true ? size.size! : '—';
      for (final color in size.colorSizes ?? <ColorSize>[]) {
        if (color.id == null || color.id!.isEmpty || color.id == '0') continue;
        rows.add(
          StockVariantAdjustTarget(
            sizeColorId: color.id!,
            sizeLabel: sizeLabel,
            colorLabel: color.colorAr?.trim().isNotEmpty == true
                ? color.colorAr!
                : '—',
            currentStock: int.tryParse(color.stock ?? '0') ?? 0,
          ),
        );
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final targets = _targets;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        constraints: BoxConstraints(maxHeight: 0.72.sh),
        decoration: BoxDecoration(
          color: AdminUiColors.cardBackground(context),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'selectSizeColor'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (targets.isEmpty)
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Text('noData'.tr, textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                  itemCount: targets.length,
                  separatorBuilder: (_, __) => SizedBox(height: 6.h),
                  itemBuilder: (ctx, i) {
                    final t = targets[i];
                    ColorSize? colorModel;
                    for (final size in product.sizes ?? <Size>[]) {
                      for (final c in size.colorSizes ?? <ColorSize>[]) {
                        if (c.id == t.sizeColorId) {
                          colorModel = c;
                          break;
                        }
                      }
                    }
                    return Material(
                      color: AdminUiColors.subtleOverlay(context),
                      borderRadius: BorderRadius.circular(12.r),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(t),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 10.h,
                          ),
                          child: Row(
                            children: [
                              if (colorModel?.imageUrl != null &&
                                  colorModel!.imageUrl!.trim().isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6.r),
                                  child: Image.network(
                                    ShowNetImage.getPhoto(colorModel.imageUrl!),
                                    width: 36.w,
                                    height: 36.w,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        SizedBox(width: 36.w, height: 36.w),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.subtitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    Text(
                                      '${'stock'.tr}: ${t.currentStock}',
                                      style:
                                          Theme.of(context).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_left,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.45),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
