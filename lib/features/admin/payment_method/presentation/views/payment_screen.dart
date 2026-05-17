import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_upload_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/select_time.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../checks/data/repositories/checks_implement.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../data/repositories/payment_implement.dart';
import '../../domain/usecases/add_payment_usecase.dart';
import '../controllers/payment_controller.dart';

class PaymentScreen extends GetView<PaymentController> {
  const PaymentScreen({
    Key? key,
    this.type,
    this.isSeller,
    this.id,
    this.forInstantSale = false,
    this.initialCashValue,
    this.instantSaleBoxLogNote,
  }) : super(key: key);
  final String? type;
  final bool? isSeller;
  final String? id;
  final bool forInstantSale;
  final String? initialCashValue;
  final String? instantSaleBoxLogNote;

  @override
  Widget build(BuildContext context) {
    final PaymentController controller = Get.put(
      PaymentController(
        allCustomersSellersUsecase: AllCustomersSellersUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        getShownBoxUsecase: GetShownBoxUsecase(
          boxesRepository: Get.find<BoxesImplement>(),
        ),
        addPaymentUsecase:
            AddPaymentUsecase(paymentRepository: Get.find<PaymentImplement>()),
      ),
    );
    controller.selectedCustomersSellers.value = isSeller ?? false;
    controller.forInstantSale = forInstantSale;
    controller.instantSaleBoxLogNote = instantSaleBoxLogNote;
    if (initialCashValue != null && initialCashValue!.trim().isNotEmpty) {
      controller.cashValueController.text = initialCashValue!.trim();
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: type == 'payment' ? 'paymentMethod' : 'paymentMethodReceive',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: Column(
          children: [
            Obx(
              () {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: CustomCheckBox(
                        title: 'seller'.tr,
                        value: RxBool(
                            !controller.selectedCustomersSellers.value == true),
                        onChanged: (val) {
                          controller.setPartnerTab(isCustomer: false);
                        },
                      ),
                    ),
                    Flexible(
                      child: CustomCheckBox(
                        title: 'customer'.tr,
                        value: RxBool(
                            !controller.selectedCustomersSellers.value ==
                                false),
                        onChanged: (val) {
                          controller.setPartnerTab(isCustomer: true);
                        },
                      ),
                    )
                  ],
                );
              },
            ),
            SizedBox(height: 10.h),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: CustomDropdownFieldWithSearch(
                      tital: controller.partnerDropdownTitle,
                      hint: controller.partnerDropdownHint,
                      items: controller.selectedCustomersSellers.value
                          ? controller.allCustomersList
                          : controller.allSellersList,
                      value: controller.selectedPartner.value ??
                          (id == null || id!.isEmpty
                              ? null
                              : (controller.selectedCustomersSellers.value
                                  ? controller.allCustomersList
                                      .firstWhereOrNull(
                                      (e) => e.id == int.tryParse(id!),
                                    )
                                  : controller.allSellersList.firstWhereOrNull(
                                      (e) => e.id == int.tryParse(id!),
                                    ))),
                      onChanged: (value) {
                        controller.onPartnerSelected(
                          value is SellerModel ? value : null,
                        );
                      },
                      itemAsString: (item) => item.name,
                      compareFn: (a, b) => a.id == b.id,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Get.toNamed(AppRoutes.ADDNEWCUSTOMERSCREEN, arguments: {
                      'sellerId': '',
                      'employeeId': '',
                      'employeeType': controller.selectedCustomersSellers.value
                          ? 'customer'
                          : 'seller',
                    }),
                    icon: Icon(
                      Icons.add_circle_sharp,
                      color: AppColors.primaryColor,
                      size: 35.sp,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 15.h),
            Row(
              children: [
                Flexible(
                  child: Obx(
                    () => CustomDropdownFieldWithSearch(
                      tital: 'boxName'.tr,
                      hint: 'boxNameExample',
                      isRequired: forInstantSale,
                      items: controller.shownBoxes,
                      value: controller.selectedBox.value,
                      onChanged: (value) {
                        controller.onBoxSelected(
                          value is ShownBoxesModel ? value : null,
                        );
                      },
                      itemAsString: (item) => item.boxName,
                      compareFn: (a, b) => a.boxId == b.boxId,
                      validator: forInstantSale
                          ? (value) {
                              if (value == null) {
                                return 'must_select_box'.tr;
                              }
                              return null;
                            }
                          : (value) => null,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: CustomTextField(
                    label: 'cashValue',
                    hintText: 'totalExample',
                    controller: controller.cashValueController,
                    keyboardType: TextInputType.number,
                    validator: (value) => null,
                  ),
                ),
              ],
            ),
            // SizedBox(height: 15.h),
            // Row(
            //   children: [
            // Flexible(
            //   child: CustomDropdownField(
            //     label: 'paymentMethod'.tr,
            //     hint: 'paymentMethodExample',
            //     items: controller.paymentMethods1,
            //     onChanged: (value) {
            //       if (value != null) {
            //         controller.paymentMethodController.text = value;
            //       }
            //     },
            //     validator: (value) => null,
            //   ),
            // ),
            // SizedBox(width: 10.w),
            // Flexible(
            //   child: CustomTextField(
            //     label: 'totalBill',
            //     hintText: 'totalExample',
            //     controller: controller.totalBillController,
            //     keyboardType: TextInputType.number,
            //     validator: (value) => null,
            //   ),
            // ),
            //   ],
            // ),
            GetBuilder<PaymentController>(
              builder: (controller) {
                return Column(
                  children: [
                    SizedBox(height: 20.h),
                    ...controller.payments.map(
                      (e) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: CustomDropdownField(
                                    label: 'paymentMethod'.tr,
                                    hint: 'paymentMethodExample',
                                    items: controller.paymentMethods,
                                    onChanged: (value) {
                                      if (value != null) {
                                        e.paymentMethod.text = value;
                                        controller.update();
                                      }
                                    },
                                    validator: (value) => null,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Flexible(
                                  child: CustomTextField(
                                    label: e.paymentMethod.text == 'check'
                                        ? 'checkValue'
                                        : 'debtValue2',
                                    hintText: 'totalExample',
                                    controller: e.paymentMethod.text == 'check'
                                        ? e.checkValue
                                        : e.debtValue,
                                    keyboardType: TextInputType.number,
                                    validator: (value) => null,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      selectDate(context, e.dueDate);
                                    },
                                    child: CustomTextField(
                                      enabled: false,
                                      decoration: BoxDecoration(
                                        color: ThemeService.isDark.value
                                            ? AppColors.customGreyColor
                                            : AppColors.whiteColor2,
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      label: 'due_date',
                                      hintText: 'due_date',
                                      hintStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: AppColors.customGreyColor5,
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w400,
                                          ),
                                      controller: e.dueDate,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 10.h),
                            if (e.paymentMethod.text == 'check')
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: CustomDropdownField(
                                          label: 'currencyy'.tr,
                                          hint: 'currencyExample',
                                          items: controller.currencies,
                                          onChanged: (value) {
                                            if (value != null) {
                                              e.currency.text = value.tr;
                                            }
                                          },
                                          validator: (value) => null,
                                        ),
                                      ),
                                      SizedBox(width: 5.w),
                                      Flexible(
                                        child: CustomTextField(
                                          label: 'checkNumber',
                                          hintText: 'checkNumberExample',
                                          controller: e.checkNumber,
                                          keyboardType: TextInputType.number,
                                          validator: (value) => null,
                                        ),
                                      ),
                                      SizedBox(width: 5.w),
                                      Flexible(
                                        child: CustomTextField(
                                          label: 'bankName',
                                          hintText: 'bankNameExample',
                                          controller: e.bankName,
                                          validator: (value) => null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  UploadImageButton(
                                    selectedFile: e.selectedFile,
                                    title: 'uploadImage',
                                  ),
                                  SizedBox(height: 20.h),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    if (controller.boxIdController.text.isEmpty) {
                      controller.addPaymentMethod();
                    }
                  },
                  child: Text(
                    'addPaymentMethod'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            // SizedBox(height: 20.h),
            AppButton(
              isLoading: controller.isLoading,
              text: type == 'payment' ? 'payment'.tr : 'receiptt'.tr,
              onPressed: () {
                controller.addPayment(context: context, type: type!);
              },
            )
          ],
        ),
      ),
    );
  }
}
//  'payment' : 'receive',
