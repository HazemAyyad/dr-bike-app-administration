import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../widgets/new_instant_sale/instant_sale_cart_sheet.dart';
import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../../checks/data/repositories/checks_implement.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../../payment_method/data/repositories/payment_implement.dart';
import '../../../payment_method/domain/usecases/add_payment_usecase.dart';
import '../../../payment_method/presentation/controllers/payment_controller.dart';
import '../controllers/sales_controller.dart';
import '../widgets/new_instant_sale/add_new_instant_sale.dart';
import '../widgets/new_instant_sale/discount_widget.dart';
import '../widgets/new_instant_sale/instant_sale_payment_section.dart';

class NewInstantSaleScreen extends StatefulWidget {
  const NewInstantSaleScreen({Key? key}) : super(key: key);

  @override
  State<NewInstantSaleScreen> createState() => _NewInstantSaleScreenState();
}

class _NewInstantSaleScreenState extends State<NewInstantSaleScreen> {
  SalesController get controller => Get.find<SalesController>();

  @override
  void initState() {
    super.initState();
    _ensurePaymentController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.loadOfferPackagesForSale();
      controller.syncCartToItems();
      controller.syncPaymentCashFromTotal();
      controller.refreshInstantSalePaymentSummary();
    });
  }

  void _ensurePaymentController() {
    if (Get.isRegistered<PaymentController>(tag: kInstantSalePaymentTag)) {
      final existing = Get.find<PaymentController>(tag: kInstantSalePaymentTag);
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
    Get.put(pc, tag: kInstantSalePaymentTag);
  }

  void _releasePaymentController() {
    if (Get.isRegistered<PaymentController>(tag: kInstantSalePaymentTag)) {
      Get.delete<PaymentController>(tag: kInstantSalePaymentTag);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PaymentController>(tag: kInstantSalePaymentTag)) {
      return Scaffold(
        appBar: CustomAppBar(title: 'newInstantSale'.tr, action: false),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _releasePaymentController();
      },
      child: Scaffold(
      appBar: CustomAppBar(
        title: 'newInstantSale',
        action: false,
        actions: [
          Obx(() {
            final _ = controller.cartRevision.value;
            final __ = controller.selectedPackageId.value;
            final n = controller.pickerSelectionCount;
            final packageOnly = controller.hasSelectedPackage && n == 1;
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
                        decoration: BoxDecoration(
                          color: packageOnly
                              ? const Color(0xFFE65100)
                              : Colors.red,
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
          key: controller.instantSaleFormKey,
          child: Column(
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
              const DiscountWidget(),
              SizedBox(height: 16.h),
              Divider(
                color: Colors.grey.shade300,
                height: 1,
              ),
              SizedBox(height: 12.h),
              const InstantSalePaymentSection(),
              SizedBox(height: 20.h),
              AppButton(
                isLoading: controller.isLoading,
                text: 'complete'.tr,
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                onPressed: () => controller.submitInstantSaleWithPayment(context),
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
