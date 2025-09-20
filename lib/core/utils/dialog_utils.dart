import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../helpers/loding_indicator.dart';

class DialogUtils {
  static void showLogoutDialog({
    required VoidCallback onConfirm,
    required String title,
    required RxBool isLoading,
  }) {
    Get.dialog(
      Obx(
        () => isLoading.value
            ? lodingIndicator()
            : AlertDialog(
                content: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                        color: Colors.red,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: AppButton(
                          isSafeArea: false,
                          text: 'yes',
                          onPressed: onConfirm,
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: AppButton(
                          isSafeArea: false,
                          text: 'cancel',
                          onPressed: () => Get.back(),
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                          textColor: Colors.red,
                          borderColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
