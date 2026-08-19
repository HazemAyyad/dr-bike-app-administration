import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/show_no_data.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../controllers/bills_controller.dart';
import '../../widgets/bills_widgets/bill_details.dart';
import '../../widgets/bills_widgets/bill_seller_details.dart';
import '../../widgets/bills_widgets/bill_title.dart';
import '../../widgets/purchase_orders_widgets/cancel_bill.dart';

class BillDetailsScreen extends GetView<BillsController> {
  const BillDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String page = Get.arguments;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'billDetails',
        action: false,
        actions: [
          IconButton(
            onPressed: () {
              controller.getBillDetails(
                context: context,
                billId: controller.billDetails!.billId.toString(),
                isDownload: true,
              );
            },
            icon: Icon(
              Icons.file_download_outlined,
              color: AppColors.primaryColor,
              size: 30.sp,
            ),
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          SliverToBoxAdapter(child: BillTitle(page: page)),
          SliverToBoxAdapter(child: SizedBox(height: 15.h)),
          GetBuilder<BillsController>(
            builder: (controller) {
              if (controller.isAddLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.billDetails == null) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }
              return SliverToBoxAdapter(
                child: Column(
                  children: [
                    BillDetails(page: page),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      child: _PurchaseWorkflowPanel(page: page),
                    ),
                    SizedBox(height: 10.h),
                    const BillSellerDetails(),
                    SizedBox(height: 10.h),
                    page == '3' || page == '4'
                        ? CancelBill(billId: controller.billDetails!.billId)
                        : const SizedBox.shrink(),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

class _PurchaseWorkflowPanel extends GetView<BillsController> {
  final String page;

  const _PurchaseWorkflowPanel({required this.page});

  @override
  Widget build(BuildContext context) {
    final details = controller.billDetails!;
    final canReceive = page != '1' &&
        details.workflowStatus != 'finalized' &&
        details.products.any((item) => item.remainingQuantity > 0);
    final canFinalize = page != '1' &&
        details.workflowStatus != 'finalized' &&
        details.products.any((item) => item.receivedOwnedQuantity > 0);
    final canPay = details.workflowStatus == 'finalized' &&
        details.paymentStatus != 'paid' &&
        details.remainingAmount != '0';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _StatusChip(
                label: 'حالة الاستلام',
                value: details.workflowStatus.isEmpty
                    ? 'awaiting_receiving'
                    : details.workflowStatus,
              ),
              _StatusChip(
                label: 'حالة الدفع',
                value: details.paymentStatus.isEmpty
                    ? 'unpaid'
                    : details.paymentStatus,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'المستلم: ${details.products.fold<num>(0, (sum, p) => sum + p.receivedOwnedQuantity)} / المطلوب: ${details.products.fold<num>(0, (sum, p) => sum + p.orderedQuantity)}',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
          ),
          if (details.finalTotal != '0' || details.paidAmount != '0') ...[
            SizedBox(height: 6.h),
            Text(
              'الإجمالي النهائي: ${details.finalTotal} | المدفوع: ${details.paidAmount} | المتبقي: ${details.remainingAmount}',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.grey.shade700,
                    fontSize: 12.sp,
                  ),
            ),
          ],
          if (canReceive || canFinalize) SizedBox(height: 12.h),
          if (canReceive)
            AppButton(
              isLoading: controller.isWorkflowLoading,
              text: 'استلام الكميات المتبقية',
              onPressed: () => controller.receiveAllShownItems(context),
            ),
          if (canReceive && canFinalize) SizedBox(height: 8.h),
          if (canFinalize)
            AppButton(
              isLoading: controller.isWorkflowLoading,
              text: 'اعتماد الفاتورة',
              onPressed: () => _showPurchasePaymentSheet(
                context,
                title: 'اعتماد الفاتورة',
                primaryText: 'اعتماد',
                initialAmount: '0',
                onSubmit: () =>
                    controller.finalizeShownPurchaseWithInitialPayment(context),
              ),
            ),
          if (canPay) ...[
            if (canReceive || canFinalize) SizedBox(height: 8.h),
            AppButton(
              isLoading: controller.isWorkflowLoading,
              text: 'تسجيل دفعة مورد',
              onPressed: () => _showPurchasePaymentSheet(
                context,
                title: 'تسجيل دفعة مورد',
                primaryText: 'تسجيل الدفعة',
                initialAmount: details.remainingAmount,
                onSubmit: () => controller.submitShownPurchasePayment(context),
              ),
            ),
          ],
          if (details.sellerId.isNotEmpty) ...[
            SizedBox(height: 8.h),
            AppButton(
              isLoading: controller.isWorkflowLoading,
              text: 'دفعة على حساب المورد',
              onPressed: () => _showPurchasePaymentSheet(
                context,
                title: 'دفعة على حساب المورد',
                primaryText: 'تسجيل وتخصيص للأقدم',
                initialAmount: details.remainingAmount == '0'
                    ? ''
                    : details.remainingAmount,
                onSubmit: () =>
                    controller.paySupplierAccountForShownSeller(context),
              ),
            ),
          ],
          if (controller.isTimelineLoading.value) ...[
            SizedBox(height: 12.h),
            const Center(child: CircularProgressIndicator()),
          ] else if (controller.purchaseTimeline.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'سجل الحركة',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
            ),
            SizedBox(height: 8.h),
            ...controller.purchaseTimeline.take(5).map((event) {
              final title = event['title']?.toString() ?? '';
              final description = event['description']?.toString() ?? '';
              final createdAt = event['created_at']?.toString() ?? '';
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  '$createdAt — ${title.isEmpty ? description : title}',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.grey.shade700,
                        fontSize: 11.sp,
                      ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _showPurchasePaymentSheet(
    BuildContext context, {
    required String title,
    required String primaryText,
    required String initialAmount,
    required Future<void> Function() onSubmit,
  }) async {
    await controller.loadPurchaseBoxes();
    controller.preparePaymentAmount(amount: initialAmount);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 18.h,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18.h,
          ),
          child: GetBuilder<BillsController>(
            builder: (controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
                        ),
                  ),
                  SizedBox(height: 14.h),
                  CustomDropdownFieldWithSearch(
                    tital: 'boxName',
                    hint: 'boxNameExample',
                    items: controller.purchaseBoxes,
                    value: controller.selectedPurchaseBox.value,
                    onChanged: (value) {
                      controller.selectPurchaseBox(
                        value is ShownBoxesModel ? value : null,
                      );
                    },
                    itemAsString: (item) =>
                        '${item.boxName} (${item.currency})',
                    compareFn: (a, b) => a.boxId == b.boxId,
                  ),
                  SizedBox(height: 12.h),
                  CustomTextField(
                    label: 'cashValue',
                    hintText: 'totalExample',
                    controller: controller.purchasePaymentAmountController,
                    keyboardType: TextInputType.number,
                    validator: (value) => null,
                  ),
                  SizedBox(height: 12.h),
                  CustomTextField(
                    label: 'notes',
                    hintText: 'notes',
                    controller: controller.purchasePaymentNoteController,
                    isRequired: false,
                    validator: (value) => null,
                  ),
                  SizedBox(height: 18.h),
                  AppButton(
                    isLoading: controller.isWorkflowLoading,
                    text: primaryText,
                    onPressed: () async {
                      await onSubmit();
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatusChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
            ),
      ),
    );
  }
}
