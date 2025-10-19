import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/helpers/showtime.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/assets_controller.dart';

class AssetLogs extends StatelessWidget {
  const AssetLogs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssetsController>(
      builder: (controller) {
        return Column(
          children: [
            ...List.generate(
              controller.assetDetails.value?.logs.length ?? 0,
              (index) {
                final logs = controller.assetDetails.value?.logs
                    .toList()
                    .reversed
                    .toList()[index];
                return Column(
                  children: [
                    if (index == 0)
                      Container(
                        margin: EdgeInsets.only(top: 20.h),
                        height: 1.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(4.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(32),
                              blurRadius: 2.r,
                              spreadRadius: 1.r,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    if (index == 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'movements'.tr,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      decoration: BoxDecoration(
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : AppColors.whiteColor2,
                        borderRadius: BorderRadius.circular(4.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(32),
                            blurRadius: 2.r,
                            spreadRadius: 1.r,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      logs!.type.tr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryColor,
                                          ),
                                    ),
                                  ],
                                ),
                                Text(
                                  showData(logs.createdAt),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w400,
                                        color: ThemeService.isDark.value
                                            ? AppColors.customGreyColor3
                                            : Colors.black
                                                .withValues(alpha: 0.5),
                                      ),
                                )
                              ],
                            ),
                          ),
                          Container(
                            width: 70.w,
                            height: 30.h,
                            decoration: BoxDecoration(
                              color: logs.type != 'create'
                                  ? AppColors.redColor
                                  : AppColors.customGreen1,
                              borderRadius: Get.locale!.languageCode == 'en'
                                  ? BorderRadius.only(
                                      topRight: Radius.circular(4.r),
                                      bottomRight: Radius.circular(4.r),
                                    )
                                  : BorderRadius.only(
                                      topLeft: Radius.circular(4.r),
                                      bottomLeft: Radius.circular(4.r),
                                    ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  NumberFormat('#,##0.00', 'en_US').format(
                                    double.parse(logs.total),
                                  ),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
