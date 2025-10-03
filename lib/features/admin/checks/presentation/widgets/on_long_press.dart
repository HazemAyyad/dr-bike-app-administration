import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../payment_method/presentation/views/payment_screen.dart';
import '../../data/models/check_model.dart';
import '../controllers/checks_controller.dart';
import 'view_checks_widget.dart';

class OnLongPress extends GetView<ChecksController> {
  const OnLongPress({Key? key, required this.check}) : super(key: key);

  final CheckModel check;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: ViewChecksWidget(
            type: controller.isInComing,
            check: check,
            shadowed: false,
            currentTab: controller.currentTab.value,
          ),
        ),
        Dialog(
          backgroundColor: ThemeService.isDark.value
              ? AppColors.darkColor
              : AppColors.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            children: [
              Container(
                // padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8.r)),
                ),
                child: Column(
                  children: (controller.currentTab.value == 0
                          ? controller.isInComing
                              ? controller.incomingChecksDidNotActOnIt
                              : controller.outgoingChecksDidNotActOnIt
                          : controller.currentTab.value == 1
                              ? controller.isInComing
                                  ? controller.incomingChecksActedOnIt
                                  : controller.outgoingChecksActedOnIt
                              : controller.archive)
                      .map<Widget>(
                        (option) => RadioListTile<String>(
                          title: Text(
                            option.tr,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          value: option,
                          groupValue: null,
                          onChanged: (value) {
                            Get.back();
                            if (value == 'voidTheCheck') {
                              Get.dialog(
                                IfCancelCheck(
                                  check: check,
                                  isReturn: false,
                                  toPerson: false,
                                ),
                              );
                            }
                            if (value == 'endorseTheCheck') {
                              Get.dialog(
                                CashTheCheck(
                                  label: 'beneficiary'.tr,
                                  hint: 'customerNameExample'.tr,
                                  check: check,
                                ),
                              );
                            }

                            if (value == 'cashTheCheck') {
                              Get.dialog(
                                controller.currentTab.value == 0
                                    ? CashToBox(
                                        label: 'boxName',
                                        hint: 'boxNameExample',
                                        check: check,
                                      )
                                    : IfCancelCheck(
                                        check: check,
                                        isReturn: false,
                                        toPerson: true,
                                      ),
                              );
                            }
                            if (value == 'returnedCheck') {
                              Get.dialog(
                                IfCancelCheck(
                                  check: check,
                                  isReturn: true,
                                  toPerson: true,
                                ),
                              );
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class IfCancelCheck extends GetView<ChecksController> {
  const IfCancelCheck({
    Key? key,
    required this.check,
    required this.isReturn,
    required this.toPerson,
  }) : super(key: key);

  final CheckModel check;
  final bool isReturn;
  final bool toPerson;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 15.w,
          vertical: 10.h,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(8.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 5.h),
            Text(
              'areYouSure'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Flexible(
                  child: AppButton(
                    isSafeArea: false,
                    isLoading: controller.isLoading,
                    width: double.infinity,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.r),
                    ),
                    text: 'yes'.tr,
                    textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                    onPressed: () {
                      isReturn
                          ? controller.returnCheck(
                              checkId: check.id.toString(),
                              isCancel: false,
                            )
                          : toPerson
                              ? !controller.isInComing
                                  ? Get.bottomSheet(
                                      PaymentScreen(
                                        type: 'payment',
                                        isSeller: check.seller != null ||
                                                check.toSeller != null
                                            ? true
                                            : false,
                                        id: check.seller != null
                                            ? check.seller!.id.toString()
                                            : check.customer != null
                                                ? check.customer!.id.toString()
                                                : check.toSeller != null
                                                    ? check.toSeller!.id
                                                        .toString()
                                                    : check.toCustomer!.id
                                                        .toString(),
                                      ),
                                      backgroundColor: Colors.white,
                                      isScrollControlled: true,
                                    ).then((value) {
                                      if (value == true) {
                                        // ignore: use_build_context_synchronously
                                        controller.cashedToPersonOrCashed(
                                          checkId: check.id.toString(),
                                        );
                                      }
                                    })
                                  : controller.cashedToPersonOrCashed(
                                      checkId: check.id.toString(),
                                    )
                              : controller.returnCheck(
                                  checkId: check.id.toString(),
                                  isCancel: true,
                                );
                    },
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: AppButton(
                    isSafeArea: false,
                    color: Colors.red,
                    width: double.infinity,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.r),
                    ),
                    text: 'cancel'.tr,
                    textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                    onPressed: () {
                      Get.back();
                    },
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

class CashTheCheck extends GetView<ChecksController> {
  const CashTheCheck({
    Key? key,
    required this.label,
    required this.hint,
    required this.check,
  }) : super(key: key);

  final String label;
  final String hint;
  final CheckModel check;

  @override
  Widget build(BuildContext context) {
    final RxnString selectedValue = RxnString();
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 15.h),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: CustomCheckBox(
                    title: 'seller'.tr,
                    value: RxBool(
                        !controller.selectedCustomersSellers.value == true),
                    onChanged: (val) {
                      selectedValue.value = null;

                      controller.selectedCustomersSellers.value = false;
                    },
                  ),
                ),
                Flexible(
                  child: CustomCheckBox(
                    title: 'customer'.tr,
                    value: RxBool(
                        !controller.selectedCustomersSellers.value == false),
                    onChanged: (val) {
                      selectedValue.value = null;
                      controller.selectedCustomersSellers.value = true;
                    },
                  ),
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
            ),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: CustomDropdownFieldWithSearch(
                      tital: label,
                      hint: hint,
                      items: controller.selectedCustomersSellers.value == false
                          ? controller.allCustomersList
                          : controller.allSellersList,
                      onChanged: (value) {
                        if (value != null) {
                          selectedValue.value = value.id.toString();
                        }
                      },
                      itemAsString: (item) => item.name,
                      compareFn: (a, b) => a.id == b.id,
                      validator: (value) => null,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Get.toNamed(AppRoutes.ADDNEWCUSTOMERSCREEN, arguments: {
                      'sellerId': '',
                      'employeeId': '',
                      'employeeType': '',
                    }),
                    icon: Icon(
                      Icons.add_circle_sharp,
                      color: ThemeService.isDark.value
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                      size: 35.sp,
                    ),
                  )
                ],
              ),
            ),
          ),
          AppButton(
            isSafeArea: false,
            isLoading: controller.isLoading,
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
              if (selectedValue.value != null) {
                controller.cashedToPersonOrCashed(
                  checkId: check.id.toString(),
                  customerId: controller.selectedCustomersSellers.value == false
                      ? selectedValue.value
                      : null,
                  sellerId: controller.selectedCustomersSellers.value == true
                      ? selectedValue.value
                      : null,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class CashToBox extends GetView<ChecksController> {
  const CashToBox({
    Key? key,
    required this.label,
    required this.hint,
    required this.check,
  }) : super(key: key);

  final String label;
  final String hint;
  final CheckModel check;

  @override
  Widget build(BuildContext context) {
    final RxnString selectedValue = RxnString();
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: CustomDropdownFieldWithSearch(
                    tital: label,
                    hint: hint,
                    titalTextStyle:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: AppColors.primaryColor,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                    items: controller.shownBoxesList
                        .where((element) => element.currency == check.currency)
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedValue.value = value.boxId.toString();
                      }
                    },
                    itemAsString: (item) =>
                        '${item.boxName} - (${item.totalBalance} ${item.currency})',
                    compareFn: (a, b) => a.boxId == b.boxId,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.toNamed(AppRoutes.CREATEBOXESSCREEN),
                  icon: Icon(
                    Icons.add_circle_sharp,
                    color: AppColors.primaryColor,
                    size: 35.sp,
                  ),
                )
              ],
            ),
          ),
          AppButton(
            isSafeArea: false,
            isLoading: controller.isLoading,
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
              if (selectedValue.value != null) {
                controller.chashToBox(
                  checkId: check.id.toString(),
                  boxId: selectedValue.value!,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
