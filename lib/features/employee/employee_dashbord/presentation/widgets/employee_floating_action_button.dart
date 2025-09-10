import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_dashbord_controller.dart';

class EmployeeFloatingActionButton extends GetView<EmployeeDashbordController> {
  const EmployeeFloatingActionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Get.locale!.languageCode == 'ar'
          ? Alignment.bottomLeft
          : Alignment.bottomRight,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Get.locale!.languageCode == 'ar'
              ? Alignment.bottomLeft
              : Alignment.bottomRight,
          children: [
            Obx(() {
              if (!controller.isAddMenuOpen.value) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: GestureDetector(
                  onTap: () => controller.toggleAddMenu(),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              );
            }),

            Positioned(
              bottom: 50.h,
              left: Get.locale!.languageCode == 'ar' ? 0.w : 180.w,
              right: Get.locale!.languageCode == 'ar' ? 180.w : 0.w,
              child: SizeTransition(
                sizeFactor: controller.sizeAnimation,
                axisAlignment: -1.0,
                child: FadeTransition(
                  opacity: controller.opacityAnimation,
                  child: Container(
                    width: 200.w,
                    // height: 211.h,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor
                          : AppColors.whiteColor2,
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...controller.employeeAddList.map(
                          (e) => InkWell(
                            overlayColor:
                                const WidgetStatePropertyAll(Colors.transparent),
                            onTap: () {
                              Get.dialog(
                                e['title'] == 'overtimeRequest'
                                    ? Form(
                                        key: controller.formKey,
                                        child: EmployeeRequstes(
                                          title: e['title']!,
                                          label: e['label']!,
                                          onPressed: () {
                                            controller.toggleAddMenu();
                                            controller.requestOverTimeOrLoan(
                                              context: context,
                                              isOverTime: true,
                                            );
                                          },
                                          textController: controller
                                              .overtimeRequestController,
                                        ),
                                      )
                                    : Form(
                                        key: controller.formKey,
                                        child: EmployeeRequstes(
                                          title: e['title']!,
                                          label: e['label']!,
                                          onPressed: () {
                                            controller.toggleAddMenu();
                                            controller.requestOverTimeOrLoan(
                                              context: context,
                                              isOverTime: false,
                                            );
                                          },
                                          textController:
                                              controller.loanRequestController,
                                        ),
                                      ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                      child: Image.asset(e['icon']!,
                                          height: 24.h, width: 24.w)),
                                  SizedBox(width: 8.w),
                                  Text(
                                    e['title']!.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: Get.isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // زر الإضافة
            SizedBox(
              height: 55.h,
              width: 55.w,
              child: FloatingActionButton(
                onPressed: () => controller.toggleAddMenu(),
                backgroundColor: AppColors.secondaryColor,
                elevation: 2.0,
                shape: const CircleBorder(),
                child: Obx(
                  () => AnimatedRotation(
                    turns: controller.isAddMenuOpen.value
                        ? -0.125
                        : 0, // 0.125 = 45 درجة
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.add,
                      key: ValueKey(controller.isAddMenuOpen.value),
                      color: AppColors.whiteColor,
                      size: 42.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmployeeRequstes extends GetView<EmployeeDashbordController> {
  const EmployeeRequstes({
    Key? key,
    required this.title,
    required this.label,
    required this.onPressed,
    required this.textController,
  }) : super(key: key);

  final String title;
  final String label;
  final Function onPressed;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darckColor
          : AppColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.secondaryColor,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: 15.h),
            CustomTextField(
              label: label,
              labelTextstyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
              hintText: 'discountExample',
              controller: textController,
            ),
            SizedBox(height: 20.h),
            AppButton(
              isLoading: controller.isLoading,
              text: 'submitRequest'.tr,
              onPressed: () => onPressed(),
            ),
          ],
        ),
      ),
    );
  }
}
