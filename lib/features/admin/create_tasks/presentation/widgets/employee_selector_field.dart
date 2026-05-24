import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../controllers/create_task_controller.dart';

class EmployeeSelectorField extends GetView<CreateTaskController> {
  const EmployeeSelectorField({Key? key, this.compact = false}) : super(key: key);

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final employees = controller.employeeService.employeeList;
      final selectedCount = controller.selectedEmployeeIds.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact)
            Text(
              'employeeName'.tr,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.operationalNavy,
              ),
            ),
          if (!compact)
            Padding(
              padding: EdgeInsets.only(top: 2.h, bottom: 6.h),
              child: Text(
                'selectMultipleEmployeesHint'.tr,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.customGreyColor5,
                ),
              ),
            ),
          if (!compact) SizedBox(height: 4.h),
          if (employees.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: OutlinedButton.icon(
                onPressed: controller.getEmployee,
                icon: const Icon(Icons.refresh),
                label: Text('loadEmployees'.tr),
              ),
            )
          else
            SizedBox(
              height: compact ? 72.h : 96.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemCount: employees.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: compact ? 8.w : 10.w),
                itemBuilder: (context, index) {
                  final emp = employees[index];
                  final id = emp.id.toString();
                  final selected =
                      controller.selectedEmployeeIds.contains(id);
                  return _EmployeeAvatarTile(
                    name: emp.employeeName,
                    imageUrl: emp.employeeImg,
                    selected: selected,
                    compact: compact,
                    onTap: () => controller.toggleEmployee(id),
                  );
                },
              ),
            ),
          if (selectedCount > 0) ...[
            SizedBox(height: 6.h),
            Text(
              'employeesSelectedCount'.tr.replaceAll('@count', '$selectedCount'),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.operationalPurple,
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _EmployeeAvatarTile extends StatelessWidget {
  const _EmployeeAvatarTile({
    required this.name,
    required this.imageUrl,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String name;
  final String imageUrl;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 22.r : 26.r;
    final diameter = radius * 2;
    final tileWidth = compact ? 60.w : 72.w;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: SizedBox(
          width: tileWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: diameter + 8.w,
                height: diameter + 8.w,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: diameter + 6.w,
                      height: diameter + 6.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.operationalPurple
                              : AppColors.operationalCardBorder,
                          width: selected ? 2.5 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.operationalPurple
                                      .withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: CircleAvatar(
                        radius: radius,
                        backgroundColor: selected
                            ? AppColors.operationalPurple
                                .withValues(alpha: 0.12)
                            : AppColors.operationalSurface,
                        backgroundImage: imageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(imageUrl)
                            : null,
                        child: imageUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                color: AppColors.operationalPurple,
                                size: compact ? 18.sp : 22.sp,
                              )
                            : null,
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: compact ? 18.w : 20.w,
                          height: compact ? 18.w : 20.w,
                          decoration: const BoxDecoration(
                            color: AppColors.operationalPurple,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: compact ? 11.sp : 13.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 9.sp : 10.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected
                      ? AppColors.operationalPurple
                      : AppColors.customGreyColor5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
