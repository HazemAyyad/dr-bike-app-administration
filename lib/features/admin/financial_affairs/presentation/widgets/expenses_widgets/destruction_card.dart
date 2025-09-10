import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/expenses_models/destruction_model.dart';

class DestructionCard extends StatelessWidget {
  const DestructionCard({Key? key, required this.data}) : super(key: key);

  final DestructionModel data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // controller.isEditing.value = true;
        // controller.getAssetsDetials(assetId: asset.id.toString());
        // Get.toNamed(AppRoutes.ADDNEWASSETSCREEN);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.r),
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(5.r),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9.r),
                    child: CachedNetworkImage(
                      imageUrl: data.image,
                      fit: BoxFit.cover,
                      height: 70.h,
                      width: 70.w,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  children: [
                    Text(
                      data.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.graywhiteColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      '${'piecesCount'.tr}:${data.piecesNumber}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.graywhiteColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            // const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(5.r),
                  decoration: BoxDecoration(
                    borderRadius: Get.locale!.languageCode != 'ar'
                        ? BorderRadius.only(
                            bottomRight: Radius.circular(4.r),
                            topRight: Radius.circular(4.r),
                          )
                        : BorderRadius.only(
                            bottomLeft: Radius.circular(4.r),
                            topLeft: Radius.circular(4.r),
                          ),
                    color: AppColors.graywhiteColor,
                  ),
                  height: 85.h,
                  width: 70.w,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'destructionValue'.tr,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: AppColors.blackColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Flexible(
                        child: Text(
                          NumberFormat('#,###').format(
                              double.parse(data.destructionValue.toString())),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: AppColors.blackColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
