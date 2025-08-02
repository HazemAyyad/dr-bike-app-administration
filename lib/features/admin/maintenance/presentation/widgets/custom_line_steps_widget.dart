import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class CustomLineSteps extends StatelessWidget {
  const CustomLineSteps(
      {Key? key,
      required this.timeLineSteps,
      required this.selectedStep,
      required this.changeSelected})
      : super(key: key);

  final List<Map<int, String>> timeLineSteps;
  final RxInt selectedStep;
  final Function(int index) changeSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.bodyMedium!;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...timeLineSteps.map(
              (e) => Obx(
                () {
                  final int step = e.keys.first;
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () => changeSelected(step),
                        child: Container(
                          height: 50.h,
                          width: 50.w,
                          decoration: BoxDecoration(
                            color: selectedStep.value == step
                                ? ThemeService.isDark.value
                                    ? AppColors.customGreyColor
                                    : Colors.white
                                : step < selectedStep.value
                                    ? AppColors.primaryColor
                                    : ThemeService.isDark.value
                                        ? AppColors.customGreyColor
                                        : Colors.white,
                            borderRadius: BorderRadius.circular(50.r),
                            border: Border.all(
                              color: selectedStep.value == step
                                  ? AppColors.customGreyColor5
                                  : step < selectedStep.value
                                      ? Colors.white
                                      : Colors.grey.shade400,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              step.toString(),
                              style: textTheme.copyWith(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                                color: selectedStep.value == step
                                    ? AppColors.customGreyColor2
                                    : step < selectedStep.value
                                        ? Colors.white
                                        : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                      step == 3
                          ? SizedBox()
                          : Container(
                              height: 2.h,
                              width: 80.w,
                              color: step < selectedStep.value
                                  ? AppColors.primaryColor
                                  : Colors.grey.shade400,
                            ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        Obx(
          () => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...timeLineSteps.asMap().entries.map(
                (entry) {
                  final int step = entry.key + 1;
                  return Column(
                    children: [
                      SizedBox(height: 10.h),
                      Text(
                        entry.value.values.first.tr,
                        style: textTheme.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: selectedStep.value == step
                              ? AppColors.primaryColor
                              : step < selectedStep.value
                                  ? AppColors.primaryColor
                                  : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
