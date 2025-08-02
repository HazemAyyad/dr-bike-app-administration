import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/checks_controller.dart';
import 'view_checks_widget.dart';

Future<String?> onLongPress(
  Map<String, dynamic> check,
  BuildContext context,
  ChecksController controller,
  RxList<String> didNotActOnIt,
  RxList<String> actedOnIt,
  RxList<String>? archive,
) {
  return Get.bottomSheet(
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 3.h),
      child: Column(
        children: [
          ViewChecksWidget(
            check: check,
            shadowed: false,
            currentTab: controller.currentTab.value,
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.r)),
            ),
            child: Column(
              children: (controller.currentTab.value == 0
                      ? didNotActOnIt
                      : controller.currentTab.value == 1
                          ? actedOnIt
                          : archive!)
                  .map<Widget>(
                    (option) => Obx(
                      () => RadioListTile<String>(
                        title: Text(
                          option.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        value: option,
                        groupValue: controller.selectedOption.value,
                        onChanged: (value) {
                          // if (value != null) {
                          // controller.selectedOption.value = value;
                          // }
                          print(
                              'اختيار: $value على العنصر رقم ${check['checkNumber']}');
                          Get.back();
                          value == 'endorseTheCheck'
                              ? cashTheCheck(
                                  check,
                                  context,
                                  'beneficiary',
                                  'customerNameExample',
                                  controller.beneficiary,
                                  controller.selectedBeneficiary,
                                )
                              : value == 'cashTheCheck'
                                  ? cashTheCheck(
                                      check,
                                      context,
                                      'boxName',
                                      'boxNameExample',
                                      controller.boxesName,
                                      controller.selectedBox,
                                    )
                                  : null;
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    ),
    isDismissible: true,
    enableDrag: true,
  );
}

Future<String?> cashTheCheck(
  Map<String, dynamic> check,
  BuildContext context,
  String label,
  String hint,
  List<String> items,
  String value,
) {
  return Get.bottomSheet(
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 3.h),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
            ),
            child: CustomDropdownField(
              label: label,
              labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
              hint: hint,
              items: items,
              onChanged: (val) {
                value = val ?? '';
                print('المستفيد: $value');
              },
            ),
          ),
          AppButton(
            height: 48.h,
            width: double.infinity,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8.r),
              bottomRight: Radius.circular(8.r),
            ),
            text: 'cashTheCheck',
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
            onPressed: () {
              print('صرف الشيك: ${check['checkNumber']}');
              Get.back();
            },
          ),
        ],
      ),
    ),
    isDismissible: true,
    enableDrag: true,
  );
}
