import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/boxes_controller.dart';
import 'movements_widget.dart';

class TaskDetailsTransfer extends GetView<BoxesController> {
  const TaskDetailsTransfer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(
          controller.boxDetailsLogs.length,
          (index) {
            final boxDetailsLog = controller.boxDetailsLogs[index];
            return Column(
              children: [
                if (index == 0)
                  Container(
                    margin: EdgeInsets.only(top: 20.h),
                    height: 1.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(4.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(32),
                          blurRadius: 2.r,
                          spreadRadius: 1.r,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                if (index == 0) SizedBox(height: 10.h),
                if (index == 0)
                  Row(
                    children: [
                      Text(
                        'movements'.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                if (index == 0) SizedBox(height: 10.h),
                Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2,
                    borderRadius: BorderRadius.circular(4.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(32),
                        blurRadius: 2.r,
                        spreadRadius: 1.r,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: MovementsWidget(box: boxDetailsLog),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
