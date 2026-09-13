import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../checks/data/repositories/checks_implement.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../../payment_method/data/repositories/payment_implement.dart';
import '../../../payment_method/domain/usecases/add_payment_usecase.dart';
import '../../../payment_method/presentation/controllers/payment_controller.dart';
import '../../../widgets/unified_partner_selector.dart';
import '../controllers/sales_controller.dart';
import '../utils/sales_amount_format.dart';

class NewCashProfitScreen extends StatefulWidget {
  const NewCashProfitScreen({Key? key}) : super(key: key);

  @override
  State<NewCashProfitScreen> createState() => _NewCashProfitScreenState();
}

class _NewCashProfitScreenState extends State<NewCashProfitScreen> {
  SalesController get controller => Get.find<SalesController>();

  PaymentController get payment =>
      Get.find<PaymentController>(tag: kProfitSalePaymentTag);

  @override
  void initState() {
    super.initState();
    _ensurePaymentController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (Get.isRegistered<PaymentController>(tag: kProfitSalePaymentTag)) {
        Get.find<PaymentController>(tag: kProfitSalePaymentTag)
            .clearPaymentForm();
      }
      await controller.loadDailySession();
      controller.applyDailyBoxToPayment(payment);
      await payment.getAllCustomersAndSellers();
      final editing = controller.editingProfitSale.value;
      if (editing != null) {
        final isSeller = editing.sellerId != null;
        final partnerId = editing.sellerId ?? editing.customerId;
        payment.selectedCustomersSellers.value = !isSeller;
        if (partnerId != null) {
          final partners =
              isSeller ? payment.allSellersList : payment.allCustomersList;
          var partner =
              partners.firstWhereOrNull((item) => item.id == partnerId);
          partner ??= SellerModel(
            id: partnerId,
            name: editing.buyerName?.trim().isNotEmpty == true
                ? editing.buyerName!.trim()
                : '#$partnerId',
            phone: '',
          );
          if (!partners.any((item) => item.id == partnerId)) {
            partners.insert(0, partner);
          }
          payment.onPartnerSelected(partner);
        }
        payment.cashValueController.text = SalesAmountFormat.display(
          SalesAmountFormat.parse(editing.paymentBoxValue ?? '0'),
        );
        controller.update();
      }
    });
  }

  void _ensurePaymentController() {
    if (Get.isRegistered<PaymentController>(tag: kProfitSalePaymentTag)) {
      final existing = Get.find<PaymentController>(tag: kProfitSalePaymentTag);
      existing.forInstantSale = true;
      return;
    }

    final pc = PaymentController(
      allCustomersSellersUsecase: AllCustomersSellersUsecase(
        checksRepository: Get.find<ChecksImplement>(),
      ),
      getShownBoxUsecase: GetShownBoxUsecase(
        boxesRepository: Get.find<BoxesImplement>(),
      ),
      addPaymentUsecase: AddPaymentUsecase(
        paymentRepository: Get.find<PaymentImplement>(),
      ),
    );
    pc.forInstantSale = true;
    Get.put(pc, tag: kProfitSalePaymentTag);
  }

  @override
  void dispose() {
    controller.clearProfitSaleForm();
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (Get.isRegistered<PaymentController>(tag: kProfitSalePaymentTag)) {
        Get.delete<PaymentController>(tag: kProfitSalePaymentTag);
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: controller.isEditingProfitSale
            ? 'تعديل بيع ربحي #${controller.editingProfitSale.value!.id}'
            : 'newCashProfit'.tr,
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              SizedBox(height: 5.h),
              CustomTextField(
                isRequired: true,
                label: 'totalCost',
                hintText: 'totalExample',
                controller: controller.totalCostController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (Get.isRegistered<PaymentController>(
                      tag: kProfitSalePaymentTag)) {
                    payment.cashValueController.text = value;
                  }
                  controller.update();
                },
              ),
              SizedBox(height: 20.h),
              CustomTextField(
                minLines: 3,
                maxLines: 5,
                label: 'details',
                hintText: 'detailsExample',
                controller: controller.noteController,
                validator: (value) {
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.only(bottom: 8.h),
                leading: const Icon(Icons.attach_file_outlined),
                title: Text(
                  'إضافة صورة أو فيديو (اختياري)',
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
                children: [
                  UploadImageButton(
                    selectedFile: controller.profitSaleImage,
                    title: 'invoiceImage',
                  ),
                  SizedBox(height: 12.h),
                  UploadImageButton(
                    selectedFile: controller.profitSaleVideo,
                    title: 'video',
                    isVideo: true,
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              const _ProfitSalePaymentSection(),
              SizedBox(height: 50.h),
              AppButton(
                isLoading: controller.isLoading,
                height: 45.h,
                width: 382.w,
                text: 'complete'.tr,
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                onPressed: () =>
                    controller.submitProfitSaleWithPayment(context),
              ),
            ],
          ),
        ),
      ),
      // floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: AppButton(
      //   isLoading: controller.isLoading,
      //   height: 45.h,
      //   width: 382.w,
      //   text: 'complete'.tr,
      //   textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
      //         fontSize: 16.sp,
      //         fontWeight: FontWeight.w700,
      //         color: Colors.white,
      //       ),
      //   onPressed: () {
      //     controller.addProfitSale(context: context);
      //   },
      // ),
    );
  }
}

class _ProfitSalePaymentSection extends StatelessWidget {
  const _ProfitSalePaymentSection();

  PaymentController get controller =>
      Get.find<PaymentController>(tag: kProfitSalePaymentTag);
  SalesController get sales => Get.find<SalesController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'paymentMethodReceive'.tr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          () => UnifiedPartnerSelector<SellerModel>(
            customers: controller.allCustomersList,
            sellers: controller.allSellersList,
            selected: controller.selectedPartner.value,
            selectedIsSeller: !controller.selectedCustomersSellers.value,
            idOf: (partner) => partner.id,
            nameOf: (partner) => partner.name,
            phoneOf: (partner) => partner.phone,
            onSelected: (partner, isSeller) {
              controller.selectedCustomersSellers.value = !isSeller;
              controller.onPartnerSelected(partner);
            },
            onCleared: () => controller.onPartnerSelected(null),
            onAddRequested: (isSeller) async {
              controller.setPartnerTab(isCustomer: !isSeller);
              await controller.openAddPartnerScreen();
            },
            showTitle: false,
            compact: true,
          ),
        ),
        SizedBox(height: 12.h),
        CustomTextField(
          label: 'cashValue',
          hintText: 'totalExample',
          controller: controller.cashValueController,
          keyboardType: TextInputType.number,
          onChanged: (_) => sales.update(),
          validator: (_) => null,
        ),
        SizedBox(height: 6.h),
        Text(
          'سيُضاف المبلغ المقبوض تلقائيًا إلى صندوق المبيعات اليومي.',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
        ),
        SizedBox(height: 12.h),
        _ProfitPaymentSummary(sales: sales, payment: controller),
      ],
    );
  }
}

class _ProfitPaymentSummary extends StatelessWidget {
  const _ProfitPaymentSummary({
    required this.sales,
    required this.payment,
  });

  final SalesController sales;
  final PaymentController payment;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesController>(
      builder: (_) {
        final total = SalesAmountFormat.parse(sales.totalCostController.text);
        final paid = SalesAmountFormat.parse(payment.cashValueController.text);
        final remaining = (total - paid).clamp(0, double.infinity).toDouble();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _SummaryRow(label: 'totalBill'.tr, value: total),
              SizedBox(height: 6.h),
              _SummaryRow(
                label: 'paidAmount'.tr,
                value: paid,
                color: Colors.green.shade700,
              ),
              SizedBox(height: 6.h),
              _SummaryRow(
                label: 'remainingAmount'.tr,
                value: remaining,
                color: remaining > 0 ? Colors.red.shade700 : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '${SalesAmountFormat.display(value)} ${'currency'.tr}',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
