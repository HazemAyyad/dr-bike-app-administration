import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/boxes_controller.dart';
import 'movements_widget.dart';
import 'box_report_filter_sheet.dart';

class TaskDetailsTransfer extends StatelessWidget {
  const TaskDetailsTransfer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BoxesController>(
      builder: (controller) {
        return Column(
          children: [
            ...List.generate(
              controller.boxDetailsLogs.length,
              (index) {
                final boxDetailsLog =
                    controller.boxDetailsLogs.toList().reversed.toList()[index];
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
                    // if (index == 0) SizedBox(height: 10.h),
                    if (index == 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'movements'.tr,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_downward_rounded,
                              color: AppColors.primaryColor,
                              size: 25.h,
                            ),
                            onPressed: () {
                              Get.bottomSheet(
                                BoxReportFilterSheet(
                                  boxId: controller.boxDetailsId,
                                  boxName:
                                      controller.editBoxNameController.text,
                                ),
                                isScrollControlled: true,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                              );
                            },
                          ),
                        ],
                      ),
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
      },
    );
  }
}
