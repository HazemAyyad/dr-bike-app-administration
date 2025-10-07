import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/assets_models/assets_data_model.dart';
import '../../controllers/assets_controller.dart';

class DestructionAssets extends GetView<AssetsController> {
  const DestructionAssets({Key? key, required this.asset}) : super(key: key);

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'destruction'.tr} ${asset.name}',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.whiteColor
                        : AppColors.secondaryColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: AppButton(
                    isSafeArea: false,
                    text: 'cancel'.tr,
                    onPressed: () {
                      Get.back();
                    },
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppButton(
                    isLoading: controller.isLoading,
                    isSafeArea: false,
                    color: Colors.red,
                    text: 'destruction'.tr,
                    onPressed: () {
                      controller.destructionOneAssets(
                        asset.assetId.toString(),
                      );
                    },
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
