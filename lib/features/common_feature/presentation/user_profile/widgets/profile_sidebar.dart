import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../core/utils/dialog_utils.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/profile_controller.dart';
import 'build_sidebar_item.dart';
import 'chang_lang.dart';
import 'dark_mode.dart';

class BuildProfileSidebar extends GetView<ProfileController> {
  const BuildProfileSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 82.h),
        // شعار التطبيق
        Image.asset(
          ThemeService.isDark.value
              ? AssetsManager.logoNoNameDark
              : AssetsManager.logoNoNameWhite,
          width: 100.w,
          height: 72.h,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.electric_scooter,
            size: 80,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(height: 30.h),
        Text(
          'profile'.tr,
          style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                color: ThemeService.isDark.value
                    ? Colors.white
                    : AppColors.secondaryColor,
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: 30.h),

        // قائمة الخيارات
        buildSidebarItem(
          'personalDetails'.tr,
          Icons.person,
          () {
            Get.toNamed(AppRoutes.PERSONALDETAILSSCREEN);
          },
        ),
        buildSidebarItem(
          'changePassword'.tr,
          Icons.lock_outline_rounded,
          () {
            Get.toNamed(AppRoutes.CHANGEPASSWORDSCREEN);
          },
        ),
        buildSidebarItem(
          'myOrders'.tr,
          Icons.shopping_bag_outlined,
          () {
            Get.toNamed(AppRoutes.MYORDERSSCREEN);
          },
        ),
        buildSidebarItem(
            'termsAndConditions'.tr, Icons.description_outlined, null),
        buildSidebarItem('aboutUs'.tr, Icons.help_outline_rounded, null),
        buildSidebarItem(
          'contactUs'.tr,
          Icons.phone_outlined,
          () {
            Get.toNamed(AppRoutes.CONTACTUSSCREEN);
          },
        ),
        changLang(controller),
        // ignore: prefer_const_constructors
        DarkMode(),
        SizedBox(height: 70.h),
        // زر تسجيل الخروج
        GestureDetector(
          onTap: () {
            DialogUtils.showLogoutDialog(
              isLoading: controller.logOutController.isLoading,
              onConfirm: () {
                controller.logOutController.logOut(context);
              },
              title: 'logoutConfirmation'.tr,
            );
          },
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8.w),
              Text(
                'logout'.tr,
                style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                      color: Colors.red,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(height: 50.h),
      ],
    );
  }
}
