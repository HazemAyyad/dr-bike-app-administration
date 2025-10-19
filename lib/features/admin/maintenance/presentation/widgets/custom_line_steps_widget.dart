import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class CustomLineSteps extends StatelessWidget {
  const CustomLineSteps({
    Key? key,
    required this.timeLineSteps,
    required this.selectedStep,
    required this.changeSelected,
    this.width,
    this.isTaped = false,
  }) : super(key: key);

  final List<Map<int, String>> timeLineSteps;
  final RxInt selectedStep;
  final Function(int index) changeSelected;
  final bool isTaped;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.bodyMedium!;

    return Column(
      children: [
        // ✅ الخطوات (الأرقام + الخطوط بس في نفس السطر)
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 15.h, // مسافة بين الأسطر
          children: [
            ...timeLineSteps.asMap().entries.map(
              (entry) {
                final int step = entry.key + 1;
                return Obx(
                  () => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => isTaped ? changeSelected(step) : null,
                        child: Container(
                          height: 45,
                          width: 45,
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
                              entry.value.keys.first.toString(),
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
                      // ✅ نرسم الخط بس لو العنصر ده مش آخر عنصر في Wrap
                      if (step < timeLineSteps.length)
                        Container(
                          height: 2.h,
                          width: width ?? 80.w,
                          color: step < selectedStep.value
                              ? AppColors.primaryColor
                              : Colors.grey.shade400,
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 10.h),

        Obx(
          () => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ...timeLineSteps.asMap().entries.map(
                (entry) {
                  final int step = entry.key + 1;
                  return Flexible(
                    child: Text(
                      entry.value.values.first.tr,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
