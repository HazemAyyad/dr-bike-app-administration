import 'package:doctorbike/core/services/user_data.dart';
import 'package:doctorbike/features/App_entr/on_boarding/widgets/login_or_sign_up.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/languague_service.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();

  LanguageController languageController = Get.put(LanguageController());

  var currentPage = 0.obs;

  final List<Map<String, String>> languages = [
    {'title': 'english', 'code': 'en'},
    {'title': 'arabic', 'code': 'ar'},
  ];

  void nextPage() {
    if (currentPage.value < 3) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      finishOnboarding();
    }
  }

  void skip() {
    finishOnboarding();
  }

  void finishOnboarding() {
    Get.offAll(
      () => LoginOrSignUpScreen(),
      transition: languageController.currentLocale.value == 'ar'
          ? Transition.leftToRight
          : Transition.rightToLeft,
    );
    UserData.saveIsFirstTime(false);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
