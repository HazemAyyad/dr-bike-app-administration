import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/forget_password_controller.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ForgetPasswordController>(
      builder: (controller) {
        return Scaffold(
          appBar: const CustomAppBar(title: '', action: false),
          body: Center(
            child: PageView.builder(
              physics: const NeverScrollableScrollPhysics(),
              controller: controller.pageController,
              itemCount: controller.tabs.length,
              itemBuilder: (context, i) => controller.tabs[i],
            ),
          ),
        );
      },
    );
  }
}
