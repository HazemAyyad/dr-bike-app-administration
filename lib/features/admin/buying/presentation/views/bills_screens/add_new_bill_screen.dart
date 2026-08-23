import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/helpers/product_priority_image.dart';
import '../../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../../sales/data/models/product_model.dart';
import '../../../../sales/presentation/utils/product_image_viewer.dart';
import '../../binding/buying_binding.dart';
import '../../controllers/bills_controller.dart';

void _logModernPurchaseBuildError(
  String scope,
  Object error,
  StackTrace stackTrace,
) {
  if (kDebugMode) {
    debugPrint('ModernPurchaseScreen.$scope build failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class AddNewBillScreen extends GetView<BillsController> {
  const AddNewBillScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BillsController>()) {
      BuyingBinding().dependencies();
    }
    if (controller.isaddNewBill == '1') {
      return const _ModernPurchaseScreen();
    }
    return Scaffold(
      appBar: CustomAppBar(
        title: controller.isaddNewBill != '2'
            ? 'addNewBill'
            : 'addNewQuantityBill',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              GetBuilder<BillsController>(
                builder: (controller) => Column(
                  children: [
                    ...controller.billModel.map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: 15.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: controller.isaddNewBill != '2'
                                  ? 120.w
                                  : 240.w,
                              child: CustomDropdownFieldWithSearch(
                                tital: 'productName',
                                hint: 'itemExample',
                                items: controller.products,
                                onChanged: (value) {
                                  item.productIdController.text =
                                      value.id.toString();
                                },
                                itemAsString: (item) =>
                                    '${item.nameAr}  (${item.stock})',
                                compareFn: (item1, item2) =>
                                    item1.id == item2.id,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Flexible(
                              child: CustomTextField(
                                label: 'quantity',
                                hintText: 'quantity',
                                controller: item.quantityController,
                                onChanged: (p0) {
                                  controller.calculateGrandTotal();
                                },
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            if (controller.isaddNewBill != '2')
                              SizedBox(width: 5.w),
                            if (controller.isaddNewBill != '2')
                              Flexible(
                                child: CustomTextField(
                                  label: 'price',
                                  hintText: 'price',
                                  controller: item.priceController,
                                  onChanged: (p0) {
                                    controller.calculateGrandTotal();
                                  },
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            if (controller.isaddNewBill != '2')
                              SizedBox(width: 5.w),
                            if (controller.isaddNewBill != '2')
                              Flexible(
                                child: CustomTextField(
                                  enabled: false,
                                  label: 'total',
                                  hintText: item.totalPrice.toString(),
                                  validator: (p0) => null,
                                ),
                              ),
                            if (controller.billModel.length > 1)
                              SizedBox(width: 5.w),
                            if (controller.billModel.length > 1)
                              GestureDetector(
                                child: Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red,
                                  size: 20.sp,
                                ),
                                onTap: () {
                                  controller.removeItem(
                                    controller.billModel.indexOf(item),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5.h),
              TextButton(
                onPressed: controller.addBillModel,
                child: Text(
                  'addNewProduct'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        // color: AppColors.primaryColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (controller.isaddNewBill != '2') SizedBox(height: 10.h),
              if (controller.isaddNewBill != '2')
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: CustomDropdownFieldWithSearch(
                        tital: 'sellerName',
                        hint: 'sellerName',
                        items: controller.allSellersList,
                        // value: controller.sellerIdController.text.isEmpty
                        //     ? null
                        //     : controller.sellerIdController.text,
                        onChanged: (value) {
                          controller.sellerIdController.text =
                              value.id.toString();
                        },
                        itemAsString: (item) => item.name,
                        compareFn: (item1, item2) => item1.id == item2.id,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.toNamed(
                          AppRoutes.ADDNEWCUSTOMERSCREEN,
                          arguments: {
                            'sellerId': '',
                            'employeeId': '',
                            'employeeType': '',
                          })?.then((value) => controller.getAllSellers()),
                      icon: Icon(
                        Icons.add_circle_sharp,
                        color: AppColors.primaryColor,
                        size: 35.sp,
                      ),
                    ),
                    if (controller.isaddNewBill != '3')
                      Flexible(
                        child: CustomTextField(
                          label: 'specialDiscount',
                          hintText: 'discountExample',
                          controller: controller.discountController,
                          isRequired: false,
                          keyboardType: TextInputType.number,
                          onChanged: (p0) {
                            controller.calculateGrandTotal();
                          },
                          validator: (p0) => null,
                        ),
                      ),
                  ],
                ),
              if (controller.isaddNewBill != '2') SizedBox(height: 30.h),
              if (controller.isaddNewBill != '2')
                GetBuilder<BillsController>(
                  builder: (controller) {
                    return Text(
                      ' ${'totalBill'.tr}: ${controller.totalCost.toString()}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    );
                  },
                ),
              SizedBox(height: 30.h),
              AppButton(
                isLoading: controller.isAddLoading,
                text: 'createBill',
                onPressed: () {
                  if (controller.formKey.currentState!.validate()) {
                    controller.addBill(context);

                    // Get.bottomSheet(
                    //   const PaymentScreen(type: 'payment'),
                    //   backgroundColor: Colors.white,
                    //   isScrollControlled: true,
                    // ).then((value) {
                    //   if (value == true) {
                    //     // ignore: use_build_context_synchronously
                    //     controller.addBill(context);
                    //   }
                    // });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernPurchaseScreen extends StatefulWidget {
  const _ModernPurchaseScreen();

  @override
  State<_ModernPurchaseScreen> createState() => _ModernPurchaseScreenState();
}

class _ModernPurchaseScreenState extends State<_ModernPurchaseScreen> {
  late final BillsController controller = Get.find<BillsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (controller.products.isEmpty &&
          controller.purchaseProductsStatus.value !=
              PurchaseLoadStatus.loading) {
        controller.getAllProducts();
      }
      if (controller.purchaseSources.isEmpty &&
          controller.purchaseSourcesStatus.value !=
              PurchaseLoadStatus.loading) {
        controller.getAllPurchaseSources();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار المنتجات'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.secondaryColor,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          GetBuilder<BillsController>(
            builder: (controller) {
              try {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'مصدر الشراء',
                      onPressed: () => _showSourceSheet(context),
                      icon: Icon(
                        Icons.person_search_outlined,
                        color: AppColors.primaryColor,
                        size: 24.sp,
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () => _showCartSheet(context),
                          icon: Icon(
                            Icons.shopping_cart_outlined,
                            color: AppColors.primaryColor,
                            size: 26.sp,
                          ),
                        ),
                        if (controller.purchaseCart.isNotEmpty)
                          Positioned(
                            top: 6.h,
                            right: 6.w,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${controller.purchaseCart.length}',
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
                  ],
                );
              } catch (error, stackTrace) {
                _logModernPurchaseBuildError('cart action', error, stackTrace);
                return IconButton(
                  onPressed: () => _showCartSheet(context),
                  icon: const Icon(Icons.shopping_cart_outlined),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.purchaseProductSearchController,
                        decoration: InputDecoration(
                          hintText: 'بحث منتج للشراء...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                        ),
                        onChanged: controller.onPurchaseProductSearchChanged,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GetBuilder<BillsController>(
                      builder: (controller) => SizedBox(
                        height: 48.h,
                        width: 48.h,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: () => _showSourceSheet(context),
                          child: controller.purchaseSourcesStatus.value ==
                                  PurchaseLoadStatus.loading
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  controller.selectedPurchaseSource.value ==
                                          null
                                      ? Icons.person_search_outlined
                                      : Icons.person_pin_circle_outlined,
                                  size: 22.sp,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GetBuilder<BillsController>(
                  builder: (controller) {
                    try {
                      final products = controller.filteredPurchaseProducts;
                      return _PurchaseProductsContent(
                        products: products,
                        status: controller.purchaseProductsStatus.value,
                        hasSearch: controller.purchaseProductSearch.value
                            .trim()
                            .isNotEmpty,
                        onRetry: controller.retryPurchaseProducts,
                      );
                    } catch (error, stackTrace) {
                      _logModernPurchaseBuildError(
                        'products content',
                        error,
                        stackTrace,
                      );
                      return _PurchaseContentMessage(
                        icon: Icons.error_outline_rounded,
                        title: 'تعذر عرض المنتجات',
                        actionLabel: 'إعادة المحاولة',
                        onAction: controller.retryPurchaseProducts,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: GetBuilder<BillsController>(
          builder: (controller) {
            final count = controller.purchaseCartTotalPieces;
            final lines = controller.purchaseCartDistinctCount;
            final canContinue = controller.purchaseCart.isNotEmpty;
            return Container(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _showCartSheet(context),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            color: AppColors.primaryColor,
                            size: 28.sp,
                          ),
                          if (lines > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                constraints: BoxConstraints(
                                  minWidth: 18.w,
                                  minHeight: 18.w,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$lines',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'السلة ($lines)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                          ),
                        ),
                        Text(
                          '$count القطع • ${controller.totalCost.value} ₪',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  SizedBox(
                    height: 46.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed:
                          canContinue ? () => _showCartSheet(context) : null,
                      child: Text(
                        'متابعة',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showSourceSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.42,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return GetBuilder<BillsController>(
              builder: (controller) {
                return DefaultTabController(
                  length: 2,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'اختيار المورد / الزبون',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16.sp,
                                    ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          height: 44.h,
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: TabBar(
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.18),
                              ),
                            ),
                            labelColor: AppColors.primaryColor,
                            unselectedLabelColor: Colors.grey.shade700,
                            labelStyle: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                            ),
                            tabs: const [
                              Tab(text: 'مورد'),
                              Tab(text: 'زبون'),
                            ],
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _PurchaseSourceList(
                                emptyText: 'لا يوجد موردين',
                                items: controller.allSellersList,
                                sourceBuilder: (seller) => PurchaseSourceModel(
                                  id: seller.id,
                                  name: seller.name,
                                  phone: seller.phone,
                                  hasSeller: true,
                                  hasCustomer: false,
                                  sellerId: seller.id,
                                ),
                                onSelected: (source) {
                                  controller.selectPurchaseSource(source);
                                  Navigator.of(sheetContext).pop();
                                },
                              ),
                              _PurchaseSourceList(
                                emptyText: 'لا يوجد زبائن',
                                items: controller.allCustomersList,
                                sourceBuilder: (customer) =>
                                    PurchaseSourceModel(
                                  id: customer.id,
                                  name: customer.name,
                                  phone: customer.phone,
                                  hasSeller: false,
                                  hasCustomer: true,
                                  customerId: customer.id,
                                ),
                                onSelected: (source) {
                                  controller.selectPurchaseSource(source);
                                  Navigator.of(sheetContext).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showCartSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.45,
          maxChildSize: 0.96,
          expand: false,
          builder: (_, scrollController) {
            return GetBuilder<BillsController>(
              builder: (controller) {
                final source = controller.selectedPurchaseSource.value;
                return ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    18.w,
                    18.h,
                    18.w,
                    MediaQuery.of(sheetContext).viewInsets.bottom + 18.h,
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'إنشاء فاتورة شراء',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18.sp,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _PurchaseCheckoutSourceTile(
                      source: source,
                      onTap: () => _showSourceSheet(context),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'items'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (controller.purchaseCart.isEmpty)
                      const Text('لا توجد منتجات في السلة')
                    else
                      const _PurchaseCheckoutTable(),
                    SizedBox(height: 8.h),
                    const _PurchasePaymentSection(),
                    SizedBox(height: 10.h),
                    const _PurchaseCheckoutSummary(),
                    SizedBox(height: 14.h),
                    AppButton(
                      isLoading: controller.isAddLoading,
                      isSafeArea: false,
                      height: 50.h,
                      text: 'createBill',
                      onPressed: () async {
                        await controller.createPurchaseFromCart(context);
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PurchaseProductsContent extends GetView<BillsController> {
  const _PurchaseProductsContent({
    required this.products,
    required this.status,
    required this.hasSearch,
    required this.onRetry,
  });

  final List<ProductModel> products;
  final PurchaseLoadStatus status;
  final bool hasSearch;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == PurchaseLoadStatus.loading ||
        status == PurchaseLoadStatus.idle) {
      return const _PurchaseContentMessage(
        icon: Icons.inventory_2_outlined,
        title: 'جاري تحميل المنتجات',
        loading: true,
      );
    }

    if (status == PurchaseLoadStatus.error) {
      return _PurchaseContentMessage(
        icon: Icons.error_outline_rounded,
        title: 'تعذر تحميل المنتجات',
        actionLabel: 'إعادة المحاولة',
        onAction: onRetry,
      );
    }

    if (products.isEmpty) {
      return _PurchaseContentMessage(
        icon: Icons.search_off_rounded,
        title: hasSearch ? 'لا توجد نتائج مطابقة' : 'لا توجد منتجات',
      );
    }

    return GridView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 6.w,
        crossAxisSpacing: 6.h,
        mainAxisExtent: 82.w,
      ),
      itemCount: products.length,
      itemBuilder: (_, index) {
        final product = products[index];
        return _PurchaseProductCard(
          product: product,
          onTap: () => controller.togglePurchaseProductSelection(product),
        );
      },
    );
  }
}

class _PurchaseSourceList extends StatelessWidget {
  const _PurchaseSourceList({
    required this.emptyText,
    required this.items,
    required this.sourceBuilder,
    required this.onSelected,
  });

  final String emptyText;
  final List<dynamic> items;
  final PurchaseSourceModel Function(dynamic item) sourceBuilder;
  final ValueChanged<PurchaseSourceModel> onSelected;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, index) {
        final source = sourceBuilder(items[index]);
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
            child: Icon(
              source.hasSeller
                  ? Icons.storefront_outlined
                  : Icons.person_outline_rounded,
              color: AppColors.primaryColor,
            ),
          ),
          title: Text(
            source.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.sp,
            ),
          ),
          subtitle: Text(
            source.phone.isEmpty ? source.typeLabel : source.phone,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(
            Icons.chevron_left,
            color: AppColors.primaryColor,
          ),
          onTap: () => onSelected(source),
        );
      },
    );
  }
}

class _PurchaseCheckoutSourceTile extends StatelessWidget {
  const _PurchaseCheckoutSourceTile({
    required this.source,
    required this.onTap,
  });

  final PurchaseSourceModel? source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentSource = source;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
              child: Icon(
                Icons.person_search_outlined,
                color: AppColors.primaryColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مصدر الشراء',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    currentSource == null
                        ? 'اختر المورد أو الزبون'
                        : '${currentSource.name} - ${currentSource.typeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}

class _PurchasePaymentSection extends GetView<BillsController> {
  const _PurchasePaymentSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'طريقة الدفع',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CustomDropdownFieldWithSearch(
                tital: 'الصندوق',
                hint: 'اختر الصندوق',
                items: controller.purchaseBoxes,
                value: controller.selectedPurchaseBox.value,
                onChanged: (value) => controller.selectPurchaseBox(value),
                itemAsString: (box) =>
                    '${box.boxName} - (${box.totalBalance} ${box.currency})',
                compareFn: (a, b) => a.boxId == b.boxId,
                isRequired: false,
                titalTextStyle: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            IconButton(
              onPressed: () => Get.toNamed(AppRoutes.CREATEBOXESSCREEN)
                  ?.then((_) => controller.loadPurchaseBoxes()),
              icon: Icon(
                Icons.add_circle_rounded,
                color: AppColors.primaryColor,
                size: 34.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        CustomTextField(
          label: 'قيمة المبلغ المدفوع',
          hintText: '0',
          controller: controller.purchasePaymentAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => controller.update(),
        ),
      ],
    );
  }
}

class _PurchaseCheckoutSummary extends GetView<BillsController> {
  const _PurchaseCheckoutSummary();

  @override
  Widget build(BuildContext context) {
    final total = controller.totalCost.value;
    final paid =
        num.tryParse(controller.purchasePaymentAmountController.text.trim()) ??
            0;
    final remaining = total - paid;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          _PurchaseSummaryLine(
            label: 'إجمالي الفاتورة',
            value: '$total ₪',
            color: AppColors.primaryColor,
          ),
          SizedBox(height: 8.h),
          _PurchaseSummaryLine(
            label: 'المبلغ المدفوع',
            value: '${paid.toStringAsFixed(2)} ₪',
            color: Colors.green,
          ),
          SizedBox(height: 8.h),
          _PurchaseSummaryLine(
            label: 'المتبقي',
            value: '${remaining.toStringAsFixed(2)} ₪',
            color: remaining > 0 ? Colors.black87 : Colors.green,
          ),
        ],
      ),
    );
  }
}

class _PurchaseSummaryLine extends StatelessWidget {
  const _PurchaseSummaryLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PurchaseContentMessage extends StatelessWidget {
  const _PurchaseContentMessage({
    required this.icon,
    required this.title,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator()
            else
              Icon(icon, color: AppColors.primaryColor, size: 36.sp),
            SizedBox(height: 12.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 10.h),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PurchaseProductCard extends GetView<BillsController> {
  const _PurchaseProductCard({
    required this.product,
    required this.onTap,
  });

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BillsController>(
      builder: (controller) {
        final qty = controller.purchaseCartQtyForProduct(product.id);
        final inCart = qty > 0;
        final hasImage = product.allImageUrlsInPriority.isNotEmpty &&
            product.imageUrl != 'no image';
        final stock = int.tryParse(product.stock) ?? 0;
        final locationLabel = _productLocationLabel(product);

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: inCart ? AppColors.primaryColor : Colors.grey.shade300,
                width: inCart ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: InkWell(
                    onTap: onTap,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        hasImage
                            ? ProductPriorityImage(
                                imageUrls: product.allImageUrlsInPriority,
                                fit: BoxFit.cover,
                                placeholder: _PurchaseProductImagePlaceholder(
                                  iconSize: 22.sp,
                                ),
                                missingPlaceholder:
                                    _PurchaseProductImagePlaceholder(
                                  iconSize: 22.sp,
                                ),
                              )
                            : _PurchaseProductImagePlaceholder(
                                iconSize: 22.sp,
                              ),
                        if (locationLabel != null)
                          Positioned(
                            top: 3.h,
                            left: 3.w,
                            right: 3.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 3.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.62),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 6.5.sp,
                                  fontWeight: FontWeight.w600,
                                  height: 1.05,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 3.h,
                          right: 3.w,
                          child: _PurchaseStockBadge(stock: stock),
                        ),
                        if (inCart)
                          Positioned(
                            top: locationLabel != null ? 18.h : 3.h,
                            left: 3.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 5.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                '$qty',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: onTap,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 74.w,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      product.nameAr,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w600,
                                        height: 1.05,
                                      ),
                                    ),
                                    Text(
                                      '${product.purchaseCost.toStringAsFixed(2)} ₪',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 7.sp,
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        height: 1.05,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 22.h,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PurchaseSelectButton(
                                selected: inCart,
                                onTap: () => controller
                                    .togglePurchaseProductSelection(product),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _productLocationLabel(ProductModel product) {
    final section = product.storeSectionName?.trim() ?? '';
    final code = product.displayProductCode.trim();
    if (section.isEmpty && code.isEmpty) return null;
    if (section.isEmpty) return code;
    if (code.isEmpty) return section;
    return '$section - $code';
  }
}

class _PurchaseSelectButton extends StatelessWidget {
  const _PurchaseSelectButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryColor.withValues(alpha: 0.12)
          : AppColors.primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.r),
        side: BorderSide(
          color: selected
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.r),
        child: SizedBox(
          width: 46.w,
          height: 22.h,
          child: Icon(
            selected ? Icons.check : Icons.add,
            size: 14.sp,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _PurchaseProductImagePlaceholder extends StatelessWidget {
  const _PurchaseProductImagePlaceholder({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.grey.shade100,
      child: Icon(
        Icons.inventory_2_outlined,
        size: iconSize,
        color: Colors.grey.shade400,
      ),
    );
  }
}

class _PurchaseStockBadge extends StatelessWidget {
  const _PurchaseStockBadge({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final color = stock <= 0
        ? Colors.red
        : stock <= 2
            ? const Color(0xFFE65100)
            : Colors.black.withValues(alpha: 0.68);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$stock',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 2.w),
          Icon(
            Icons.inventory_2_outlined,
            size: 9.sp,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _PurchaseCheckoutTable extends GetView<BillsController> {
  const _PurchaseCheckoutTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 520.w),
          child: Column(
            children: [
              Container(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                child: Row(
                  children: [
                    _PurchaseTableHeaderCell('الصنف', width: 185.w),
                    _PurchaseTableHeaderCell('الكمية', width: 78.w),
                    _PurchaseTableHeaderCell('السعر', width: 92.w),
                    _PurchaseTableHeaderCell('الإجمالي', width: 90.w),
                    SizedBox(width: 42.w),
                  ],
                ),
              ),
              ...controller.purchaseCart.map(
                (item) => _PurchaseCheckoutTableRow(item: item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseTableHeaderCell extends StatelessWidget {
  const _PurchaseTableHeaderCell(this.text, {required this.width});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.primaryColor,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PurchaseCheckoutTableRow extends GetView<BillsController> {
  const _PurchaseCheckoutTableRow({required this.item});

  final PurchaseCartItemModel item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.product.preferredImageUrl;
    final hasImage = imageUrl.trim().isNotEmpty && imageUrl != 'no image';
    final intelligence = controller.purchasePriceIntelligence[item.product.id];
    final loading = controller.purchasePriceLoading.contains(item.product.id);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 185.w,
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: hasImage
                          ? () => openProductImageViewer(
                                context,
                                imageUrl,
                                imageUrls: item.product.allImageUrlsInPriority,
                                title: item.product.nameAr,
                              )
                          : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: SizedBox(
                          width: 38.w,
                          height: 38.w,
                          child: hasImage
                              ? ProductPriorityImage(
                                  imageUrls:
                                      item.product.allImageUrlsInPriority,
                                  fit: BoxFit.cover,
                                  placeholder: _PurchaseProductImagePlaceholder(
                                    iconSize: 18.sp,
                                  ),
                                  missingPlaceholder:
                                      _PurchaseProductImagePlaceholder(
                                    iconSize: 18.sp,
                                  ),
                                )
                              : _PurchaseProductImagePlaceholder(
                                  iconSize: 18.sp,
                                ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        item.product.nameAr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _PurchaseTableInput(
                width: 78.w,
                controller: item.quantityController,
                onChanged: (_) => controller.calculatePurchaseCartTotal(),
              ),
              SizedBox(width: 8.w),
              _PurchaseTableInput(
                width: 92.w,
                controller: item.priceController,
                onChanged: (_) => controller.calculatePurchaseCartTotal(),
              ),
              SizedBox(
                width: 90.w,
                child: Text(
                  '${item.total.toStringAsFixed(2)} ₪',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                width: 42.w,
                child: IconButton(
                  onPressed: () => controller.removePurchaseCartItem(item),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
          if (loading) ...[
            SizedBox(height: 6.h),
            LinearProgressIndicator(
              minHeight: 2.h,
              color: AppColors.primaryColor,
            ),
          ] else if (intelligence != null && intelligence.isNotEmpty) ...[
            SizedBox(height: 6.h),
            _PurchasePriceIntelBox(item: item, intelligence: intelligence),
          ],
        ],
      ),
    );
  }
}

class _PurchaseTableInput extends StatelessWidget {
  const _PurchaseTableInput({
    required this.width,
    required this.controller,
    required this.onChanged,
  });

  final double width;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 38.h,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9.r),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9.r),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9.r),
            borderSide: const BorderSide(color: AppColors.primaryColor),
          ),
        ),
      ),
    );
  }
}

class _PurchasePriceIntelBox extends GetView<BillsController> {
  const _PurchasePriceIntelBox({
    required this.item,
    required this.intelligence,
  });

  final PurchaseCartItemModel item;
  final Map<String, dynamic> intelligence;

  @override
  Widget build(BuildContext context) {
    final supplierLast = asString(intelligence['supplier_last_price']);
    final latest = asString(intelligence['latest_price']);
    final lowest = asString(intelligence['lowest_price']);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.w,
            runSpacing: 4.h,
            children: [
              if (lowest.isNotEmpty)
                _IntelChip(label: 'أقل سعر', value: lowest),
              if (supplierLast.isNotEmpty)
                _IntelChip(label: 'آخر سعر للمصدر', value: supplierLast),
              if (latest.isNotEmpty)
                _IntelChip(label: 'آخر سعر عام', value: latest),
            ],
          ),
          SizedBox(height: 4.h),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _showHistory(context),
            icon: Icon(Icons.history, size: 16.sp),
            label: const Text('عرض سجل الأسعار'),
          ),
        ],
      ),
    );
  }

  Future<void> _showHistory(BuildContext context) async {
    final history = mapList(
      intelligence['history'],
      (Map<String, dynamic> m) => m,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return ListView.separated(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 24.h),
              itemCount: history.length + 1,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (_, index) {
                if (index == 0) {
                  return Text(
                    'سجل أسعار ${item.product.nameAr}',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
                        ),
                  );
                }
                final row = history[index - 1];
                final price = asString(row['unit_price']);
                final quantity = asString(row['quantity']);
                final date = asString(row['priced_at']);
                final sellerId = asString(row['seller_id']);
                final customerId = asString(row['customer_id']);
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  title: Text(
                    '$price ₪',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                    ),
                  ),
                  subtitle: Text(
                    [
                      if (quantity.isNotEmpty) 'كمية $quantity',
                      if (sellerId.isNotEmpty) 'مورد #$sellerId',
                      if (customerId.isNotEmpty) 'زبون #$customerId',
                      if (date.isNotEmpty) date,
                    ].join(' • '),
                  ),
                  trailing: TextButton(
                    onPressed: price.isEmpty
                        ? null
                        : () {
                            controller.applyHistoricalPurchasePrice(
                              item: item,
                              price: price,
                            );
                            Navigator.of(sheetContext).pop();
                          },
                    child: const Text('استخدام'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _IntelChip extends StatelessWidget {
  const _IntelChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '$label: $value ₪',
        style: TextStyle(
          color: AppColors.primaryColor,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
