import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../employee_section/presentation/controllers/employee_service.dart';
import '../controllers/create_task_controller.dart';

class EmployeeSelectorField extends GetView<CreateTaskController> {
  const EmployeeSelectorField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final employees = Get.find<EmployeeService>().employeeList;

    return Obx(
      () {
        final selectedId = controller.employeeIdConroller.text;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'employeeName'.tr,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.operationalNavy,
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              height: 88.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: employees.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  final emp = employees[index];
                  final id = emp.id.toString();
                  final selected = selectedId == id;
                  return GestureDetector(
                    onTap: () => controller.employeeIdConroller.text = id,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28.r,
                          backgroundColor: selected
                              ? AppColors.operationalPurple.withValues(alpha: 0.15)
                              : AppColors.operationalSurface,
                          backgroundImage: emp.employeeImg.isNotEmpty
                              ? CachedNetworkImageProvider(emp.employeeImg)
                              : null,
                          child: emp.employeeImg.isEmpty
                              ? Icon(Icons.person, color: AppColors.operationalPurple)
                              : null,
                        ),
                        SizedBox(height: 4.h),
                        SizedBox(
                          width: 64.w,
                          child: Text(
                            emp.employeeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w400,
                              color: selected
                                  ? AppColors.operationalPurple
                                  : AppColors.customGreyColor5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
