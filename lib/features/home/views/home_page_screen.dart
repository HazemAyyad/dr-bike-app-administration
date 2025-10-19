import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/services/languague_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/utils/app_colors.dart';
import '../controllers/home_page_controller.dart';

class HomePageScreen extends GetView<HomePageController> {
  const HomePageScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    RxBool isDark = false.obs;
    LanguageController languageController = Get.put(LanguageController());

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Obx(
              () => Switch(
                value: isDark.value,
                onChanged: (value) {
                  isDark.value = value;
                  ThemeService.instance.themeMode =
                      value ? ThemeMode.dark : ThemeMode.light;
                  ThemeService.isDark.value = value;
                },
              ),
            ),
            Text('homeTitle'.tr),
            SizedBox(
              height: 200.h,
              width: 400.w,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        languageController.changeLanguage('en');
                      },
                      child: Container(
                        height: 51.h,
                        width: 382.w,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 8,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ThemeService.isDark.value
                              ? Colors.white
                              : AppColors.customGreyColor,
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                        child: Text(
                          'en',
                          style: Theme.of(Get.context!)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: AppColors.graywhiteColor,
                                fontSize: 21.sp,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        languageController.changeLanguage('ar');
                      },
                      child: Container(
                        height: 51.h,
                        width: 382.w,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 8,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                        child: Text(
                          'ar',
                          style: Theme.of(Get.context!)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: AppColors.graywhiteColor,
                                fontSize: 21.sp,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
