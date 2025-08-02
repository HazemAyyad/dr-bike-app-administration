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
                      TextButton(
                        style: TextButton.styleFrom(
                          fixedSize: Size(130.w, 30.h),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                        onPressed: onConfirm,
                        child: Text(
                          'yes'.tr,
                          style: Theme.of(Get.context!)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          fixedSize: Size(130.w, 30.h),
                          side: BorderSide(
                            color: Colors.red,
                            width: 1.w,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                        onPressed: () => Get.back(),
                        child: Text(
                          'cancel'.tr,
                          style: Theme.of(Get.context!)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: Colors.red,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                              ),
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
