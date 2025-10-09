import 'package:doctorbike/routes/app_routes.dart' show AppRoutes;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../../admin_dashbord/presentation/widgets/stat_card.dart';
import '../../controllers/assets_controller.dart';
import '../../controllers/finacial_service.dart';

class AssetsData extends StatelessWidget {
  const AssetsData({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 24.w),
        child: GetBuilder<AssetsController>(
          builder: (controller) {
            if (controller.isLoading.value) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9.r),
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          show: true,
                          title: 'totalAssets',
                          imageicon: AssetsManager.cashIcon,
                          value: NumberFormat('#,###').format(
                            double.parse(FinacialService()
                                .assets
                                .value!
                                .totalAssetsOriginalPrices),
                          ),
                          subtitle: '',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: StatCard(
                          show: true,
                          title: 'averageConsumptionRatio',
                          imageicon: AssetsManager.percentageIcon2,
                          value:
                              '${FinacialService().assets.value!.averageDepreciationRate.toStringAsFixed(5)}%',
                          subtitle: '',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        isSafeArea: false,
                        color: AppColors.primaryColor,
                        textStyle:
                            Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  color: AppColors.whiteColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                        text:
                            '${'assetsConsumption'.tr}(${NumberFormat('#,###').format(double.parse(FinacialService().assets.value!.totalAssetsDepreciatePrices))})',
                        onPressed: () {
                          Get.dialog(const AssetsConsumption());
                        },
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: AppButton(
                        isSafeArea: false,
                        color: AppColors.primaryColor,
                        textStyle:
                            Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  color: AppColors.whiteColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                        text: 'log',
                        onPressed: () {
                          controller.getAssetsLogs();
                          Get.toNamed(AppRoutes.ASSETLOGSCREEN);
                        },
                      ),
                    ),
                  ],
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class AssetsConsumption extends GetView<AssetsController> {
  const AssetsConsumption({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.blackColor
          : AppColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // العنوان
            Text(
              '${'assetsConsumption'.tr}؟',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeService.isDark.value
                        ? AppColors.whiteColor
                        : AppColors.blackColor,
                  ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: AppButton(
                    isSafeArea: false,
                    color: Colors.red,
                    onPressed: () {
                      Get.back();
                    },
                    text: 'cancel',
                  ),
                ),
                SizedBox(width: 20.h),
                Expanded(
                  child: AppButton(
                    isLoading: controller.isLoadingDepreciate,
                    isSafeArea: false,
                    onPressed: () {
                      controller.depreciateAssets();
                    },
                    text: 'yes',
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
