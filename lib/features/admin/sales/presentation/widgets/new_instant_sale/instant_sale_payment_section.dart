import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../checks/data/models/check_model.dart';
import '../../../../payment_method/presentation/controllers/payment_controller.dart';
import '../../../../widgets/unified_partner_selector.dart';
import '../../controllers/sales_controller.dart';
import 'instant_sale_payment_summary.dart';

/// Payment / قبض section embedded in the new instant sale screen.
class InstantSalePaymentSection extends StatelessWidget {
  const InstantSalePaymentSection({
    Key? key,
    this.paymentTag = kInstantSalePaymentTag,
    this.showHeader = true,
    this.showPartner = true,
    this.showDailyBoxInfo = true,
    this.showPaymentFields = true,
    this.extraTotal = 0,
  }) : super(key: key);

  final String paymentTag;
  final bool showHeader;
  final bool showPartner;
  final bool showDailyBoxInfo;
  final bool showPaymentFields;
  final double extraTotal;

  PaymentController get _payment =>
      Get.find<PaymentController>(tag: paymentTag);

  @override
  Widget build(BuildContext context) {
    final controller = _payment;
    final sales = Get.find<SalesController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
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
        ],
        if (showPartner) ...[
          Obx(
            () => UnifiedPartnerSelector<SellerModel>(
              customers: controller.allCustomersList,
              sellers: controller.allSellersList,
              selected: controller.selectedPartner.value,
              selectedIsSeller: !controller.selectedCustomersSellers.value,
              idOf: (item) => item.id,
              nameOf: (item) => item.name,
              phoneOf: (item) => item.phone,
              onSelected: (item, isSeller) {
                controller.selectedCustomersSellers.value = !isSeller;
                controller.onPartnerSelected(item);
              },
              onCleared: () => controller.onPartnerSelected(null),
              onAddRequested: (isSeller) async {
                controller.setPartnerTab(isCustomer: !isSeller);
                await controller.openAddPartnerScreen();
              },
            ),
          ),
          SizedBox(height: 12.h),
        ],
        if (showPaymentFields)
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
                      child: showDailyBoxInfo
                          ? Text(
                              '${'salesDailyBox'.tr}: ${controller.dailySalesBoxLabel.value}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    SizedBox(height: 10.h),
                    CustomTextField(
                      label: 'cashValue',
                      hintText: 'totalExample',
                      controller: controller.cashValueController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        if (paymentTag == kInstantSalePaymentTag) {
                          sales.markInstantSalePaymentAmountTouched();
                        } else {
                          sales.refreshInstantSalePaymentSummaryForTag(
                              paymentTag);
                        }
                      },
                    ),
                  ],
                );
              }
              return const _MissingDailySalesBoxNotice();
            },
          ),
        if (showPaymentFields)
          InstantSalePaymentSummary(extraTotal: extraTotal),
      ],
    );
  }
}

class _MissingDailySalesBoxNotice extends StatelessWidget {
  const _MissingDailySalesBoxNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Text(
        'salesDailyNoSessionOpen'.tr,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: Colors.red.shade700,
        ),
      ),
    );
  }
}
