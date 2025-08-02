import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/on_boarding_controller.dart';
import '../models/onboarding_page.dart';
import '../widgets/chose_lang.dart';
import '../widgets/on_boarding_button.dart';
import '../widgets/on_boarding_indicator.dart';
import '../widgets/onboarding_item.dart';
import '../widgets/skip_button.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            SkipButton(controller: controller),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) => controller.currentPage.value = index,
                itemBuilder: (_, index) {
                  final item = onboardingData[index];
                  return index == 0
                      ? const ChoseLang()
                      : OnboardingItem(
                          imagePath: item['image']!,
                          title: item['title']!.tr,
                          description: item['desc']!.tr,
                        );
                },
              ),
            ),
            OnBoardingIndicator(controller: controller),
            SizedBox(height: 25.h),
            Obx(
              () => OnBoardingButton(
                progress: controller.currentPage.value,
                onTap: controller.nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
