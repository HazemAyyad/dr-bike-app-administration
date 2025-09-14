import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../maintenance/presentation/widgets/custom_line_steps_widget.dart';
import '../../../maintenance/presentation/widgets/next_back_button.dart';
import '../controllers/project_controller.dart';
import '../widgets/first_step.dart';
import '../widgets/second_step.dart';

class CreateProjectScreen extends GetView<ProjectController> {
  const CreateProjectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'createProject', action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              SizedBox(height: 10.h),
              CustomLineSteps(
                timeLineSteps: controller.timeLineSteps,
                selectedStep: controller.selectedStep,
                changeSelected: controller.changeSelected,
              ),
              SizedBox(height: 20.h),
              Obx(() {
                if (controller.selectedStep.value == 1) return const FirstStep();
                return const SecondStep();
              }),
              SizedBox(height: 40.h),
              NextBackButton(
                isLoading: controller.isLoading,
                endTitle: 'addProject',
                totalSteps: controller.timeLineSteps.length.obs,
                selectedStep: controller.selectedStep,
                onPressedBack: controller.prevStep,
                onPressedNext: controller.nextStep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
