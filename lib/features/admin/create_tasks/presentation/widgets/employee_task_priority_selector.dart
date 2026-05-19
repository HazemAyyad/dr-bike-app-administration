import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../controllers/create_task_controller.dart';

class EmployeeTaskPrioritySelector extends GetView<CreateTaskController> {
  const EmployeeTaskPrioritySelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Wrap(
        spacing: 8.w,
        children: ['low', 'medium', 'high'].map((level) {
          final selected = controller.priority.value == level;
          Color color;
          switch (level) {
            case 'high':
              color = AppColors.redColor;
              break;
            case 'low':
              color = AppColors.customGreyColor5;
              break;
            default:
              color = AppColors.operationalPurple;
          }
          return ChoiceChip(
            label: Text(level.tr),
            selected: selected,
            selectedColor: color.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: selected ? color : AppColors.operationalNavy,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => controller.priority.value = level,
          );
        }).toList(),
      ),
    );
  }
}
