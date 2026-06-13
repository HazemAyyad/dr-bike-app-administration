import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../../checks/data/models/check_model.dart';
import '../../../../payment_method/presentation/controllers/payment_controller.dart';
import '../../controllers/sales_controller.dart';
import 'instant_sale_payment_summary.dart';

/// Payment / قبض section embedded in the new instant sale screen.
class InstantSalePaymentSection extends StatelessWidget {
  const InstantSalePaymentSection({Key? key}) : super(key: key);

  PaymentController get _payment =>
      Get.find<PaymentController>(tag: kInstantSalePaymentTag);

  @override
  Widget build(BuildContext context) {
    final controller = _payment;
    final sales = Get.find<SalesController>();

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
        SizedBox(height: 4.h),
        Text(
          'salesPartnerOptionalHint'.tr,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
        ),
        SizedBox(height: 10.h),
        Obx(
          () {
            final isCustomer = controller.selectedCustomersSellers.value;
            return Row(
              children: [
                Expanded(
                  child: _PartnerTabCheckbox(
                    title: 'seller'.tr,
                    selected: !isCustomer,
                    onTap: () => controller.setPartnerTab(isCustomer: false),
                  ),
                ),
                Expanded(
                  child: _PartnerTabCheckbox(
                    title: 'customer'.tr,
                    selected: isCustomer,
                    onTap: () => controller.setPartnerTab(isCustomer: true),
                  ),
                ),
              ],
            );
          },
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
                  isRequired: false,
                  items: controller.selectedCustomersSellers.value
                      ? controller.allCustomersList
                      : controller.allSellersList,
                  value: controller.selectedPartner.value,
                  onChanged: (value) {
                    controller.onPartnerSelected(
                      value is SellerModel ? value : null,
                    );
                  },
                  validator: (_) => null,
                  itemAsString: (item) => item.name,
                  compareFn: (a, b) => a.id == b.id,
                ),
              ),
              IconButton(
                onPressed: () => controller.openAddPartnerScreen(),
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
          () {
            if (controller.useDailySalesBox.value) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${'salesDailyBox'.tr}: ${controller.dailySalesBoxLabel.value}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  CustomTextField(
                    label: 'cashValue',
                    hintText: 'totalExample',
                    controller: controller.cashValueController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => sales.refreshInstantSalePaymentSummary(),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: CustomDropdownFieldWithSearch(
                    tital: 'boxName'.tr,
                    hint: 'boxNameExample',
                    isRequired: true,
                    items: controller.selectableBoxes,
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
                    onChanged: (_) => sales.refreshInstantSalePaymentSummary(),
                  ),
                ),
              ],
            );
          },
        ),
        const InstantSalePaymentSummary(),
      ],
    );
  }
}

class _PartnerTabCheckbox extends StatelessWidget {
  const _PartnerTabCheckbox({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: selected,
            onChanged: (_) => onTap(),
            activeColor: AppColors.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Flexible(
            child: Text(
              title.tr,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}
