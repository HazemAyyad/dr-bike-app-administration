import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';

Obx orderCards(controller) {
  return Obx(
    () => AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: ListView.builder(
        shrinkWrap: true,
        key: ValueKey<int>(controller.currentTab.value),
        itemCount: controller.list.length,
        itemBuilder: (context, index) {
          final order = controller.list[index];
          return Column(
            children: [
              InkWell(
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                onTap: () {
                  // Handle order card tap
                  Get.toNamed(
                    AppRoutes.TASKDETAILS,
                    arguments: 'privateTaskDetails',
                  );
                },
                child: SizedBox(
                  height: 35.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        child: SizedBox(
                          width:
                              controller.currentTab.value == 1 ? 130.w : 160.w,
                          child: Text(
                            order['taskName'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.customGreyColor5,
                                ),
                          ),
                        ),
                      ),
                      Text(
                        order['startDate'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w400,
                              color: AppColors.customGreyColor5,
                            ),
                      ),
                      SizedBox(),
                      Text(
                        order['endDate'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w400,
                              color: AppColors.customGreyColor5,
                            ),
                      ),
                      if (controller.currentTab.value == 1)
                        GestureDetector(
                          onTap: () {
                            // Handle cancel order action
                            print('Cancel ${order['taskName']}');
                          },
                          child: Container(
                            height: 24.h,
                            width: 80.w,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red,
                                width: 1.w,
                              ),
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                            child: Center(
                              child: Text(
                                'employeeCancelTask'.tr,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.red,
                                    ),
                              ),
                            ),
                          ),
                        )
                    ],
                  ),
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
