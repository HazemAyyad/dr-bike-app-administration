import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';

Obx employeeList(controller) {
  return Obx(
    () => AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: ListView.builder(
        shrinkWrap: true,
        key: ValueKey<int>(controller.currentTab.value),
        itemCount: controller.list.length,
        itemBuilder: (context, index) {
          final employee = controller.list[index];
          return Column(
            children: [
              SizedBox(
                height: 35.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Flexible(
                      child: SizedBox(
                        width: controller.currentTab.value == 2 ? 100.w : 100.w,
                        child: Text(
                          employee['employeeName'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.customGreyColor5,
                                  ),
                        ),
                      ),
                    ),
                    Text(
                      controller.currentTab.value == 0
                          ? '${employee['hourlyRate']} ${'currency'.tr}'
                          : controller.currentTab.value == 1
                              ? '${employee['workStartTime']}'
                              : '${employee['salaryHours']} ${'currency'.tr}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.customGreyColor5,
                          ),
                    ),
                    if (controller.currentTab.value == 1) SizedBox(),
                    Text(
                      controller.currentTab.value == 0
                          ? '${employee['points']} ${'point'.tr}'
                          : '${employee['debts']} ${'currency'.tr}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.customGreyColor5,
                          ),
                    ),
                    if (controller.currentTab.value == 1) SizedBox(),
                    if (controller.currentTab.value == 1)
                      Text(
                        '${employee['workHoursOfDay']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w400,
                              color: AppColors.customGreyColor5,
                            ),
                      ),
                    if (controller.currentTab.value == 1) SizedBox(),
                    if (controller.currentTab.value == 2)
                      GestureDetector(
                        onTap: () {
                          // Handle cancel order action
                          print('Cancel ${employee['employeeName']}');
                        },
                        child: Container(
                          height: 24.h,
                          width: 64.w,
                          decoration: BoxDecoration(
                            color: Color(0XFF34C759),
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          child: Center(
                            child: Text(
                              'paySalary'.tr,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                      )
                  ],
                ),
              ),
              Divider(
                  color: const Color.fromRGBO(217, 217, 217, 1), thickness: 1),
            ],
          );
        },
      ),
    ),
  );
}
