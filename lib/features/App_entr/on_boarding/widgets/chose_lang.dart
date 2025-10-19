import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../controllers/on_boarding_controller.dart';

class ChoseLang extends GetView<OnboardingController> {
  const ChoseLang({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'chooseLanguage'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? Colors.white
                        : AppColors.secondaryColor,
                    fontSize: 29.sp,
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50.h),
            Flexible(
              child: ListView.builder(
                itemCount: controller.languages.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final lang = controller.languages[index];
                  final isSelected =
                      controller.languageController.currentLocale.value ==
                          lang['code'];

                  return GestureDetector(
                    onTap: () {
                      controller.languageController
                          .changeLanguage(lang['code']!);
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
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Text(
                        lang['title']!.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: isSelected
                                  ? AppColors.secondaryColor
                                  : AppColors.graywhiteColor,
                              fontSize: 21.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
