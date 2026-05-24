import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../controllers/create_task_controller.dart';

class EmployeeTaskPrioritySelector extends GetView<CreateTaskController> {
  const EmployeeTaskPrioritySelector({Key? key, this.compact = false})
      : super(key: key);

  final bool compact;

  static const _levels = ['low', 'medium', 'high'];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: _levels
            .map(
              (level) => _PriorityChip(
                label: level,
                selected: controller.priority.value == level,
                compact: compact,
                onTap: () => controller.priority.value = level,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: compact ? 8.h : 12.h),
            decoration: BoxDecoration(
              color: selected ? AppColors.operationalPurple : AppColors.whiteColor,
              borderRadius: BorderRadius.circular(compact ? 8.r : 14.r),
              border: Border.all(
                color: selected
                    ? AppColors.operationalPurple
                    : AppColors.operationalCardBorder,
              ),
            ),
            child: Text(
              label.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 11.sp : 13.sp,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.operationalNavy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
