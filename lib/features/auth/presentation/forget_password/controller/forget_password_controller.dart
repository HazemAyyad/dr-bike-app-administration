import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgetPasswordController extends GetxController {
  final TextEditingController emailController = TextEditingController();

  late PageController pageController;
  int currentPage = 0;

  List tabs = [
    // OtpPage(email: email),
    // const SendOtpScreen(),
    // ResetPasswordScreen(),
    // const DoneScreen(),
  ];
  void next() async {
    if (currentPage < 3) {
      currentPage++;
    }

    pageController.animateToPage(
      currentPage,
      duration: const Duration(milliseconds: 10),
      curve: Curves.easeInOut,
    );
    update();
  }

  void back() {
    if (currentPage > 0) {
      currentPage--;
    }

    pageController.animateToPage(
      currentPage,
      duration: const Duration(milliseconds: 10),
      curve: Curves.easeInOut,
    );
    update();
  }

  @override
  void onInit() {
    pageController = PageController();
    super.onInit();
  }
  // Login login;
  // LoginController({required this.login});

  // final formKey = GlobalKey<FormState>();

  // final emailController = TextEditingController();

  // final passwordController = TextEditingController();

  // final isRemember = ValueNotifier(false);

  // RxBool isLoading = false.obs;

  // RxBool isPasswordVisible = true.obs;

  // void togglePasswordVisibility() {
  //   isPasswordVisible.value = !isPasswordVisible.value;
  // }

  // @override
  // void onClose() {
  //   emailController.dispose();
  //   passwordController.dispose();
  //   super.onClose();
  // }

  // void sendOtp(BuildContext context) async {
  //   if (formKey.currentState!.validate()) {
  //     isLoading(true);
  //     final result = await login.call(
  //       email: emailController.text,
  //       password: passwordController.text,
  //       fcmToken: NotificationFirebaseService.instance.finalToken,
  //     );
  //     result.fold(
  //       (failure) {
  //         Helpers.showCustomDialogError(
  //           context: context,
  //           title: 'error'.tr,
  //           message: failure.data['message'].toString(),
  //         );
  //       },
  //       (success) {
  //         Helpers.showCustomDialogSuccess(
  //           context: context,
  //           title: 'success'.tr,
  //           message: 'loginSuccess'.tr,
  //         );
  //         Future.delayed(
  //           const Duration(milliseconds: 1500),
  //           () {
  //             if (isRemember.value) {
  //               UserData.saveIsRememberUser(isRemember.value);
  //             }
  //             Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
  //           },
  //         );
  //       },
  //     );
  //     isLoading(false);
  //   }
  // }
}
