import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'activityLog', action: false),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  children: [
                    Flexible(
                      child: Container(
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            CustomText(title: 'activity'),
                            CustomText(title: 'description'),
                            CustomText(title: 'details'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: List.generate(
                  10,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(vertical: 5.h),
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    height: 40.h,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.primaryColor, width: 1.w),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          title: 'إضافة عقوبة جديدة',
                          color: AppColors.customGreyColor2,
                        ),
                        SizedBox(width: 5.w),
                        Container(
                          width: 1.w,
                          height: 20.h,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(width: 5.w),
                        CustomText(
                          title: 'خصم يوم عمل للموظف احمد علي',
                          color: AppColors.customGreyColor2,
                        ),
                        Container(
                          width: 1.w,
                          height: 20.h,
                          color: AppColors.primaryColor,
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.exit_to_app,
                                color: Get.isDarkMode
                                    ? AppColors.primaryColor
                                    : AppColors.secondaryColor,
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomText extends StatelessWidget {
  const CustomText({
    Key? key,
    required this.title,
    this.color,
  }) : super(key: key);
  final String title;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        title.tr,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: color ?? Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 14.sp,
            ),
      ),
    );
  }
}
