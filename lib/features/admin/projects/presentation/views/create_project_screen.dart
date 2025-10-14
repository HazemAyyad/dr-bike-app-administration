import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../payment_method/presentation/views/payment_screen.dart';
import '../controllers/project_controller.dart';
import '../widgets/creat_project_widgets/first_step.dart';

class CreateProjectScreen extends GetView<ProjectController> {
  const CreateProjectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: controller.isEdit.value ? 'editProject' : 'createProject',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              SizedBox(height: 10.h),
              // CustomLineSteps(
              //   timeLineSteps: controller.timeLineSteps,
              //   selectedStep: controller.selectedStep,
              //   changeSelected: controller.changeSelected,
              // ),
              // SizedBox(height: 20.h),
              const FirstStep(),
              SizedBox(height: 40.h),
              AppButton(
                  isLoading: controller.isLoading,
                  text: 'addProject',
                  onPressed: () {
                    if (controller.formKey.currentState!.validate()) {
                      if (controller.partnerId.value.isNotEmpty &&
                          controller.partnerShareController.text.isEmpty) {
                        Get.snackbar(
                          'error'.tr,
                          'يجب تحديد نسبة الشريك',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                        );
                      } else {
                        Get.bottomSheet(
                          const PaymentScreen(type: 'payment'),
                          backgroundColor: Colors.white,
                          isScrollControlled: true,
                        ).then((value) {
                          if (value == true) {
                            // ignore: use_build_context_synchronously
                            controller.addNewProject(context);
                          }
                        });
                      }
                    }
                  }),
              // NextBackButton(
              //   isLoading: controller.isLoading,
              //   endTitle: 'addProject',
              //   totalSteps: controller.timeLineSteps.length.obs,
              //   selectedStep: controller.selectedStep,
              //   onPressedBack: controller.prevStep,
              //   onPressedNext: () => controller.nextStep(),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
