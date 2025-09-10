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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...instantSale.subProducts.take(3).map(
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
          // الإجمالي
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
                  controller.currentTab.value == 0 ? 'total'.tr : 'price'.tr,
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
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor5,
                ),
          ),
        ),
        value == '' ? const SizedBox() : const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor6
                    : AppColors.customGreyColor5,
              ),
        ),
      ],
    );
  }
}
