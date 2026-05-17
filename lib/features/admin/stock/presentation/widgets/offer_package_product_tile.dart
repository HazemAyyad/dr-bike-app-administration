import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/offer_packages_controller.dart';

/// Product line inside add/edit package — matches employee section row style.
class OfferPackageProductTile extends StatelessWidget {
  const OfferPackageProductTile({
    Key? key,
    required this.row,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  final OfferPackageProductRow row;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitleColor = Colors.grey.withValues(alpha: 0.75);

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.customGreyColor5,
                        ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${'quantity'.tr}: ${row.quantityPerPackage} · ${'price'.tr}: ${row.unitPrice.toStringAsFixed(2)} · ${'stock'.tr}: ${row.stock}',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: subtitleColor,
                        ),
                  ),
                  Text(
                    '${'total'.tr}: ${row.lineTotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'edit'.tr,
              icon: Icon(
                Icons.edit_outlined,
                size: 22.sp,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'delete'.tr,
              icon: Icon(Icons.delete_outline, color: AppColors.redColor, size: 22.sp),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
