import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';

class CreateQrcode extends StatelessWidget {
  const CreateQrcode({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darckColor
          : AppColors.whiteColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20.h),
          Text(
            'addBarCode'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Get.isDarkMode
                      ? AppColors.primaryColor
                      : AppColors.secondaryColor,
                ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: Image.asset(
              AssetsManger.qrcode,
              height: 100.h,
              width: 100.w,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.primaryColor,
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child:
                AppButton(text: 'createBarCode', onPressed: () => Get.back()),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}
