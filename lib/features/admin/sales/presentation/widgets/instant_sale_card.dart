import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/instant_sales_model.dart';
import '../controllers/sales_controller.dart';

class InstantSaleCard extends GetView<SalesController> {
  const InstantSaleCard({Key? key, required this.instantSale})
      : super(key: key);

  final InstantSalesModel instantSale;

  @override
  Widget build(BuildContext context) {
    final isPackage = instantSale.isPackageSale;
    final accent = ThemeService.isDark.value
        ? AppColors.primaryColor
        : AppColors.secondaryColor;

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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: Image.asset(
                      isPackage
                          ? AssetsManager.stockImage
                          : AssetsManager.salesImage,
                      width: 50.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPackage)
                          Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'saleTypeOfferPackage'.tr,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                        InfoRow(
                          label: instantSale.displayTitle,
                          value: isPackage
                              ? '${'packageSaleQuantity'.tr}: ${instantSale.quantity}'
                              : '${instantSale.cost} ${'currency'.tr}',
                        ),
                        if (isPackage)
                          InfoRow(
                            label: 'unitPackagePrice'.tr,
                            value:
                                '${instantSale.cost} ${'currency'.tr}',
                          ),
                        if (instantSale.isCancelled)
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Text(
                              'cancelled'.tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 11.sp,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        if (instantSale.displayBuyerLine.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Text(
                              instantSale.displayBuyerLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 11.sp,
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        if (isPackage && instantSale.subProducts.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              instantSale.subProducts
                                  .map(
                                    (e) =>
                                        '${e.productName} (×${e.quantity})',
                                  )
                                  .join(' • '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 11.sp,
                                    color: AppColors.customGreyColor2,
                                  ),
                            ),
                          )
                        else
                          ...instantSale.subProducts.take(2).map(
                                (entry) => InfoRow(
                                  label: entry.productName,
                                  value: '${entry.cost} ${'currency'.tr}',
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 60.w,
            height: 60.h,
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
                  'total'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                ),
                SizedBox(height: 8.h),
                Text(
                  instantSale.totalCost.toString(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor5,
                ),
          ),
        ),
        if (value.isNotEmpty) ...[
          SizedBox(width: 6.w),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor5,
                ),
          ),
        ],
      ],
    );
  }
}
