import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../../checks/data/models/check_model.dart';
import '../../../../payment_method/presentation/controllers/payment_controller.dart';
import '../../controllers/sales_controller.dart';

/// Payment / قبض section embedded in the new instant sale screen.
class InstantSalePaymentSection extends StatelessWidget {
  const InstantSalePaymentSection({Key? key}) : super(key: key);

  PaymentController get _payment =>
      Get.find<PaymentController>(tag: kInstantSalePaymentTag);

  @override
  Widget build(BuildContext context) {
    final controller = _payment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'paymentMethodReceive'.tr,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(height: 10.h),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: CustomCheckBox(
                  title: 'seller'.tr,
                  value: RxBool(!controller.selectedCustomersSellers.value),
                  onChanged: (_) => controller.setPartnerTab(isCustomer: false),
                ),
              ),
              Expanded(
                child: CustomCheckBox(
                  title: 'customer'.tr,
                  value: RxBool(controller.selectedCustomersSellers.value),
                  onChanged: (_) => controller.setPartnerTab(isCustomer: true),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Obx(
          () => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CustomDropdownFieldWithSearch(
                  tital: controller.partnerDropdownTitle,
                  hint: controller.partnerDropdownHint,
                  items: controller.selectedCustomersSellers.value
                      ? controller.allCustomersList
                      : controller.allSellersList,
                  value: controller.selectedPartner.value,
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
                onPressed: () => Get.toNamed(
                  AppRoutes.ADDNEWCUSTOMERSCREEN,
                  arguments: {
                    'sellerId': '',
                    'employeeId': '',
                    'employeeType': controller.selectedCustomersSellers.value
                        ? 'customer'
                        : 'seller',
                  },
                ),
                icon: Icon(
                  Icons.add_circle_sharp,
                  color: AppColors.primaryColor,
                  size: 32.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: CustomDropdownFieldWithSearch(
                  tital: 'boxName'.tr,
                  hint: 'boxNameExample',
                  isRequired: true,
                  items: controller.shownBoxes,
                  value: controller.selectedBox.value,
                  onChanged: (value) {
                    controller.onBoxSelected(
                      value is ShownBoxesModel ? value : null,
                    );
                  },
                  itemAsString: (item) => item.boxName,
                  compareFn: (a, b) => a.boxId == b.boxId,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: CustomTextField(
                  label: 'cashValue',
                  hintText: 'totalExample',
                  controller: controller.cashValueController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
