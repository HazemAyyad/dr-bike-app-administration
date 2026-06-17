import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../../checks/data/repositories/checks_implement.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../../payment_method/data/repositories/payment_implement.dart';
import '../../../payment_method/domain/usecases/add_payment_usecase.dart';
import '../../../payment_method/presentation/controllers/payment_controller.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
import '../../../sales/presentation/widgets/new_instant_sale/add_new_instant_sale.dart';
import '../../../sales/presentation/widgets/new_instant_sale/discount_widget.dart';
import '../../../sales/presentation/widgets/new_instant_sale/instant_sale_cart_sheet.dart';
import '../../../sales/presentation/widgets/new_instant_sale/instant_sale_payment_section.dart';
import '../../../sales/presentation/widgets/new_instant_sale/instant_sale_picker_partner_bar.dart';
import '../controllers/sales_orders_controller.dart';
import '../widgets/sales_order_shiply_address_section.dart';
import '../widgets/sales_order_checkout_totals.dart';

/// مراجعة الطلبية قبل الحفظ — نفس تدفق البيع الفوري.
class SalesOrderCheckoutScreen extends StatefulWidget {
  const SalesOrderCheckoutScreen({Key? key}) : super(key: key);

  @override
  State<SalesOrderCheckoutScreen> createState() =>
      _SalesOrderCheckoutScreenState();
}

class _SalesOrderCheckoutScreenState extends State<SalesOrderCheckoutScreen> {
  SalesController get sales => Get.find<SalesController>();
  SalesOrdersController get orders => Get.find<SalesOrdersController>();

  @override
  void initState() {
    super.initState();
    _ensurePaymentController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await sales.loadDailySession();
      if (Get.isRegistered<PaymentController>(tag: kSalesOrderPaymentTag)) {
        final payment = Get.find<PaymentController>(tag: kSalesOrderPaymentTag);
        sales.applyDailyBoxToPayment(payment);
      }
      sales.syncCartToItems();
      if (Get.isRegistered<PaymentController>(tag: kSalesOrderPaymentTag)) {
        final payment =
            Get.find<PaymentController>(tag: kSalesOrderPaymentTag);
        await payment.getAllCustomersAndSellers();
        sales.syncPickerPartnerFromPayment();
        sales.resolvePartnerFromOrderSnapshot(
          customerId: orders.detail.value?.customerId,
          name: orders.customerNameController.text.trim().isNotEmpty
              ? orders.customerNameController.text.trim()
              : orders.detail.value?.customerName,
          phone: orders.customerPhoneController.text.trim().isNotEmpty
              ? orders.customerPhoneController.text.trim()
              : orders.detail.value?.customerPhone,
        );
        if (sales.hasPaymentSnapshot) {
          sales.applySuspendedPaymentToController(payment);
        }
        // Default paid amount is 0 for new orders (employee can change it).
        if (!orders.isEditingOrder && !orders.hasSuspendedDraft.value) {
          payment.cashValueController.text = '0';
        }
        sales.refreshInstantSalePaymentSummaryForTag(kSalesOrderPaymentTag);
      }
      if (orders.cities.isEmpty) {
        await orders.loadLookups();
      }
    });
  }

  void _ensurePaymentController() {
    if (Get.isRegistered<PaymentController>(tag: kSalesOrderPaymentTag)) {
      final existing =
          Get.find<PaymentController>(tag: kSalesOrderPaymentTag);
      existing.forInstantSale = true;
      existing.clearPaymentForm();
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
    Get.put(pc, tag: kSalesOrderPaymentTag);
  }

  void _releasePaymentController() {
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (Get.isRegistered<PaymentController>(tag: kSalesOrderPaymentTag)) {
        Get.delete<PaymentController>(tag: kSalesOrderPaymentTag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PaymentController>(tag: kSalesOrderPaymentTag)) {
      return Scaffold(
        appBar: CustomAppBar(title: 'salesOrderNew'.tr, action: false),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _releasePaymentController();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: orders.isEditingOrder ? 'salesOrderEdit' : 'salesOrderNew',
          action: false,
          actions: [
            Obx(() {
              final _ = sales.cartRevision.value;
              final n = sales.pickerSelectionCount;
              return IconButton(
                onPressed: () => showInstantSaleCartSheet(context),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: AppColors.primaryColor,
                      size: 26.sp,
                    ),
                    if (n > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$n',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: sales.instantSaleFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 5.h),
                const AddNewInstantSaleWidget(),
                Divider(
                  color: ThemeService.isDark.value
                      ? AppColors.primaryColor
                      : AppColors.secondaryColor,
                  thickness: 0.8,
                  height: 1,
                ),
                SizedBox(height: 10.h),
                const DiscountWidget(
                  showNotes: false,
                  showHints: false,
                ),
                SizedBox(height: 16.h),
                Obx(() {
                  final _ = sales.cartRevision.value;
                  final parcelPrice = sales.totalCost.value;
                  return SalesOrderShiplyAddressSection(
                    parcelPriceForFee: parcelPrice,
                  );
                }),
                SizedBox(height: 12.h),
                const SalesOrderCheckoutTotals(),
                SizedBox(height: 16.h),
                _SalesOrderPartnerCard(
                  onEdit: () => showInstantSalePickerPartnerSheet(context),
                ),
                SizedBox(height: 16.h),
                // Notes are not needed for sales orders at the moment.
                Divider(color: Colors.grey.shade300, height: 1),
                SizedBox(height: 12.h),
                Obx(() {
                  final _ = sales.cartRevision.value;
                  final deliveryFee = orders.manualDeliveryFee.value;
                  return InstantSalePaymentSection(
                    paymentTag: kSalesOrderPaymentTag,
                    showHeader: false,
                    showPartner: false,
                    showDailyBoxInfo: false,
                    extraTotal: deliveryFee,
                  );
                }),
                SizedBox(height: 16.h),
                Obx(() {
                  if (orders.hasSuspendedDraft.value) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Text(
                        'salesOrderDraftResuming'.tr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFFE65100),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                OutlinedButton.icon(
                  onPressed: orders.suspendOrderDraft,
                  icon: const Icon(Icons.pause_circle_outline),
                  label: Text('salesOrderSuspend'.tr),
                ),
                SizedBox(height: 12.h),
                Obx(
                  () => AppButton(
                    isLoading: orders.isSubmitting,
                    text: orders.isEditingOrder ? 'saveChanges'.tr : 'save'.tr,
                    textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                    onPressed: () =>
                        orders.submitCreateOrderFromCheckout(sales),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesOrderPartnerCard extends StatelessWidget {
  const _SalesOrderPartnerCard({
    required this.onEdit,
  });

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final sales = Get.find<SalesController>();
    final orders = Get.find<SalesOrdersController>();

    return Obx(() {
      final partner = sales.pickerSelectedPartner.value;
      final name = (partner?.name ?? '').trim().isNotEmpty
          ? partner!.name
          : (orders.customerNameController.text.trim().isNotEmpty
              ? orders.customerNameController.text.trim()
              : '-');
      final phone = (partner?.phone ?? '').trim().isNotEmpty
          ? partner!.phone
          : (orders.customerPhoneController.text.trim().isNotEmpty
              ? orders.customerPhoneController.text.trim()
              : '');

      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: SalesOrdersController.cardGray,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: SalesOrdersController.borderGray),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline,
                color: SalesOrdersController.textSecondary, size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: SalesOrdersController.textPrimary,
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: SalesOrdersController.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, size: 18.sp),
              label: Text('edit'.tr),
              style: TextButton.styleFrom(
                foregroundColor: SalesOrdersController.textPrimary,
                backgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
