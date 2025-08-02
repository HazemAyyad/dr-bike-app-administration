import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/checks_controller.dart';
import '../widgets/checks_informaiton.dart';

class ChecksScreen extends GetView<ChecksController> {
  const ChecksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        title: 'checksandCommitments'.tr,
        action: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          SizedBox(height: 10.h),
          ChecksInformaiton(controller: controller),
          SizedBox(height: 30.h),
          AppButton(
            text: 'outgoingChecks',
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16.sp,
                  color: AppColors.whiteColor,
                  fontWeight: FontWeight.w700,
                ),
            onPressed: () {
              Get.toNamed(AppRoutes.OUTGOINGCHECKSSCREEN);
            },
            color: AppColors.primaryColor,
            height: 48.h,
          ),
          SizedBox(height: 15.h),
          AppButton(
            text: 'incomingChecks',
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16.sp,
                  color: AppColors.whiteColor,
                  fontWeight: FontWeight.w700,
                ),
            onPressed: () {
              Get.toNamed(AppRoutes.INCOMINGCHECKSSCREEN);
            },
            color: AppColors.primaryColor,
            height: 48.h,
          ),
        ],
      ),
    );
  }
}
