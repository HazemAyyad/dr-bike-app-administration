import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/buying_controller.dart';

class BuyingScreen extends GetView<BuyingController> {
  const BuyingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'purchasesandReturns',
        action: false,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9.r),
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
            ),
            child: GetBuilder<BuyingController>(
              builder: (controller) {
                return Column(
                  children: [
                    MainPageWidget(
                      onTap: () {
                        Get.toNamed(AppRoutes.BILLSSCREEN);
                      },
                      icon: AssetsManager.mingcuteIcon,
                      title: 'newBill'.tr,
                    ),
                    MainPageWidget(
                      onTap: () {},
                      icon: AssetsManager.solarIcon,
                      title: 'purchaseOrders'.tr,
                    ),
                    MainPageWidget(
                      onTap: () {},
                      icon: AssetsManager.designProductIcon,
                      title: 'purchaseReturns'.tr,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MainPageWidget extends StatelessWidget {
  const MainPageWidget({
    Key? key,
    required this.onTap,
    required this.icon,
    required this.title,
  }) : super(key: key);

  final Function() onTap;
  final String icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : Colors.white,
          borderRadius: BorderRadius.circular(5.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              height: 20.h,
              width: 25.w,
              scale: 0.5,
            ),
            SizedBox(width: 5.w),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? Colors.white
                          : AppColors.secondaryColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
