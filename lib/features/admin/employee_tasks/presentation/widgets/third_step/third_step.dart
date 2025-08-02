import 'package:doctorbike/core/helpers/loding_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../controllers/create_task_controller.dart';
import 'task_image.dart';
import 'multi_select_dropdown.dart';

// بناء الخطوة الثالثة: الخيارات الإضافية
Widget buildThirdStep(
    BuildContext context, CreateTaskController controller, String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // التكرار

      SizedBox(height: 20.h),

      // صورة المهمة
      title == 'createNewEmployeeTask'
          ? taskImage(context, controller)
          : const SizedBox.shrink(),
      SizedBox(height: 20.h),

      Obx(
        () => controller.isLoding.value
            ? lodingIndicator()
            : AppButton(
                text: 'createTask'.tr,
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                onPressed: () {
                  controller.createTask(context);
                },
                height: 40.h,
              ),
      ),
      SizedBox(height: 50.h),
    ],
  );
}
