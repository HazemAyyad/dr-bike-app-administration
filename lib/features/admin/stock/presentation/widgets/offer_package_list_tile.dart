import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../data/models/offer_package_model.dart';

class OfferPackageListTile extends StatelessWidget {
  const OfferPackageListTile({
    Key? key,
    required this.pkg,
    required this.showStockWarning,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  final OfferPackageModel pkg;
  final bool showStockWarning;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Future<void> _showActionsSheet(BuildContext context) async {
    final isDark = ThemeService.isDark.value;
    final sheetColor = isDark ? AppColors.customGreyColor : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    pkg.name,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              ListTile(
                leading: Icon(
                  Icons.edit_outlined,
                  color: isDark
                      ? AppColors.primaryColor
                      : AppColors.secondaryColor,
                ),
                title: Text('edit'.tr),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onEdit();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.redColor),
                title: Text(
                  'delete'.tr,
                  style: const TextStyle(color: AppColors.redColor),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    final subtitleColor = Colors.grey.withValues(alpha: 0.7);

    return InkWell(
      onTap: onTap,
      onLongPress: () => _showActionsSheet(context),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: _PackageThumb(imagePath: pkg.image),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${'price'.tr}: ${pkg.price.toStringAsFixed(2)} ${'currency'.tr}',
                    style: textStyle.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                    ),
                  ),
                  Text(
                    '${'packageDefinitionQty'.tr}: ${pkg.packageQuantity}',
                    style: textStyle.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                  Text(
                    '${'packageSalesCount'.tr}: ${pkg.salesCount} · ${'packagesSoldTotal'.tr}: ${pkg.packagesSold}',
                    style: textStyle.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                    ),
                  ),
                  if (showStockWarning) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'offerPackageInsufficientStock'.tr,
                      style: textStyle.copyWith(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.redColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
              onPressed: () => _showActionsSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageThumb extends StatelessWidget {
  const _PackageThumb({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final resolved = ShowNetImage.getPhoto(imagePath);
    final missing = resolved == AssetsManager.noImageNet ||
        imagePath.trim().toLowerCase() == 'no image';

    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        width: 80.w,
        height: 80.w,
        color: AppColors.customGreyColor6,
        child: missing
            ? Image.asset(AssetsManager.stockImage, fit: BoxFit.contain)
            : CachedNetworkImage(
                imageUrl: resolved,
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) =>
                    Image.asset(AssetsManager.stockImage, fit: BoxFit.contain),
              ),
      ),
    );
  }
}
