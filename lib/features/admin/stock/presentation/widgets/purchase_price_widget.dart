import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/product_details_model.dart';

class ShowPurchasePrice extends StatelessWidget {
  const ShowPurchasePrice({Key? key, required this.product}) : super(key: key);
  final ProductDetailsModel product;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darckColor
          : AppColors.whiteColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.h),
          Text(
            'purchasePrice'.tr,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.secondaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                ),
          ),
          Container(
            margin: EdgeInsets.symmetric(
              vertical: 10.h,
              horizontal: 25.w,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 5.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'sellerName'.tr,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                        color: AppColors.whiteColor,
                      ),
                ),
                Text(
                  'price'.tr,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                        color: AppColors.whiteColor,
                      ),
                ),
              ],
            ),
          ),
          if (product.purchasePrices!.isEmpty) ShowNoData(),
          SingleChildScrollView(
            child: Column(
              children: [
                ...product.purchasePrices!.map(
                  (price) {
                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 25.w,
                        vertical: 5.h,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 5.h),
                      decoration: BoxDecoration(
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : AppColors.customGreyColor6,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            price.sellerId!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.sp,
                                    ),
                          ),
                          Text(
                            price.price.toString(),
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.sp,
                                    ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 15.h),
        ],
      ),
    );
  }
}
