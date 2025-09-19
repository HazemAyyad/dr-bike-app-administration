import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';

class ContactDialog extends StatelessWidget {
  const ContactDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 10.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: () {
                // launchDialer(employee.phone);
              },
              child: Row(
                children: [
                  SizedBox(width: 5.h),
                  Icon(
                    Icons.phone_outlined,
                    color: AppColors.primaryColor,
                    size: 30.sp,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'directContact'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blackColor,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: () {
                // launchWhatsApp(
                //     phoneNumber:
                //         employee.phone);
              },
              child: Row(
                children: [
                  Image.asset(
                    AssetsManager.whatsapp,
                    height: 30.h,
                    width: 30.w,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'whatsappCall'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blackColor,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
