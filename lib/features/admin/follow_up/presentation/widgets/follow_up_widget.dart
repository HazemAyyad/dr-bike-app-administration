import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/follow_up_controller.dart';
import 'contact_dialog.dart';

class FollowUpWidget extends StatelessWidget {
  const FollowUpWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FollowUpController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.currentTab.value == 0 && controller.followups.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final followup = controller.followups[index];
              return Container(
                height: 70.h,
                margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
                decoration: BoxDecoration(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.whiteColor2,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              followup.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeService.isDark.value
                                        ? AppColors.customGreyColor6
                                        : AppColors.customGreyColor5,
                                  ),
                            ),
                            SizedBox(width: 5.w),
                            GestureDetector(
                              onTap: () {
                                Get.dialog(const ContactDialog());
                              },
                              child: Icon(
                                Icons.phone_outlined,
                                size: 23.sp,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          followup.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeService.isDark.value
                                        ? AppColors.customGreyColor6
                                        : AppColors.customGreyColor5,
                                  ),
                        ),
                      ],
                    ),
                    Container(
                      height: 35.h,
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.redColor,
                        ),
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: Center(
                        child: Text(
                          'cancelFollowUp'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.redColor,
                                  ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
            childCount: controller.followups.length,
          ),
        );
      },
    );
  }
}
