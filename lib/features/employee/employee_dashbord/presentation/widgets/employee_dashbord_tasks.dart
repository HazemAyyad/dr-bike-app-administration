import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/dashbord_employee_details_model.dart';
import '../controllers/employee_dashbord_controller.dart';

class EmployeeDashbordTasks extends GetView<EmployeeDashbordController> {
  const EmployeeDashbordTasks({Key? key, required this.e}) : super(key: key);

  final Task e;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.TASKDETAILS,
          arguments: {
            'taskId': e.id.toString(),
            'EmployeeDashbordController': controller
          },
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 80.w,
              child: Text(
                e.name,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.customGreyColor5,
                    ),
              ),
            ),
            Container(
              height: 20.h,
              width: 1.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9.r),
                color: AppColors.primaryColor,
              ),
            ),
            Text(
              showData(e.startTime),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.customGreyColor5,
                  ),
            ),
            Container(
              height: 20.h,
              width: 1.w,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9.r),
                color: AppColors.primaryColor,
              ),
            ),
            Text(
              showData(e.endTime),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.customGreyColor5,
                  ),
            ),
            Container(
              height: 20.h,
              width: 1.w,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9.r),
                color: AppColors.primaryColor,
              ),
            ),
            Text(
              showData(e.endTime),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.customGreyColor5,
                  ),
            ),
            Container(
              height: 20.h,
              width: 1.w,
              // padding: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9.r),
                color: AppColors.primaryColor,
              ),
            ),
            // Obx(
            //   () =>
            Transform.scale(
              scale: 1.5,
              child: Checkbox(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
                side: BorderSide(color: AppColors.primaryColor),
                value: false,
                onChanged: (value) {
                  controller.changeTaskToCompleted(
                    context: context,
                    isSubTask: false,
                    taskId: e.id,
                  );
                },
              ),
              // ),
            ),
          ],
        ),
      ),
    );
  }
}
