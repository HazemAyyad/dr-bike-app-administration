import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Container(
            width: 326.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'search'.tr,
                hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColors.customGreyColor5,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w400,
                    ),
                border: InputBorder.none,
                prefixIcon: Image.asset(
                  AssetsManger.searchIcon,
                  height: 24.h,
                  width: 24.w,
                  color: AppColors.customGreyColor5,
                ),
                contentPadding: EdgeInsets.only(top: 6.h),
                isDense: true,
              ),
            ),
          ),
        ),
        Spacer(),
        GestureDetector(
          onTap: () {},
          child: ClipOval(
            child: Container(
              height: 40.h,
              width: 40.w,
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              child: Image.asset(
                AssetsManger.notificationIcon,
                height: 20.h,
                width: 20.w,
                // color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
