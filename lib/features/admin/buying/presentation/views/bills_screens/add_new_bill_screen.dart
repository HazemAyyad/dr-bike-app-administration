import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/helpers/product_priority_image.dart';
import '../../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../../routes/app_routes.dart';
import '../../binding/buying_binding.dart';
import '../../controllers/bills_controller.dart';

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
  BillsController get controller => Get.find<BillsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (controller.products.isEmpty) {
        controller.getAllProducts();
      }
      if (controller.purchaseSources.isEmpty) {
        controller.getAllPurchaseSources();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'addNewBill',
        action: false,
        actions: [
          Obx(
            () => Stack(
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
          ),
        ],
      ),
      body: GetBuilder<BillsController>(
        builder: (controller) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
                child: Column(
                  children: [
                    _PurchaseSourceSelector(
                      onTap: () => _showSourceSheet(context),
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: controller.purchaseProductSearchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن منتج للشراء',
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
                  ],
                ),
              ),
              Expanded(
                child: controller.products.isEmpty &&
                        controller.purchaseProductSearch.value.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            SizedBox(height: 10.h),
                            Text(
                              'جاري تحميل المنتجات',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      )
                    : controller.filteredPurchaseProducts.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد منتجات',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 120.h),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10.h,
                              crossAxisSpacing: 10.w,
                              childAspectRatio: 0.72,
                            ),
                            itemCount:
                                controller.filteredPurchaseProducts.length,
                            itemBuilder: (_, index) {
                              final product =
                                  controller.filteredPurchaseProducts[index];
                              return _PurchaseProductCard(
                                product: product,
                                onTap: () => controller
                                    .addProductToPurchaseCart(product),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: GetBuilder<BillsController>(
          builder: (controller) {
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
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الإجمالي',
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Colors.grey.shade700,
                                    fontSize: 11.sp,
                                  ),
                        ),
                        Text(
                          '${controller.totalCost.value} ₪',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16.sp,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  SizedBox(
                    width: 170.w,
                    child: AppButton(
                      isLoading: controller.isAddLoading,
                      text: 'createBill',
                      onPressed: () =>
                          controller.createPurchaseFromCart(context),
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
                return ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 24.h),
                  itemCount: controller.purchaseSources.length + 1,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (_, index) {
                    if (index == 0) {
                      return Text(
                        'مصدر الشراء',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16.sp,
                                ),
                      );
                    }
                    final source = controller.purchaseSources[index - 1];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      title: Text(
                        source.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                        ),
                      ),
                      subtitle: Text(source.typeLabel),
                      trailing: const Icon(
                        Icons.chevron_left,
                        color: AppColors.primaryColor,
                      ),
                      onTap: () {
                        controller.selectPurchaseSource(source);
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  },
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
        return Padding(
          padding: EdgeInsets.only(
            left: 18.w,
            right: 18.w,
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
                    'سلة الشراء',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
                        ),
                  ),
                  SizedBox(height: 12.h),
                  if (controller.purchaseCart.isEmpty)
                    const Text('لا توجد منتجات في السلة')
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: controller.purchaseCart.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (_, index) {
                          final item = controller.purchaseCart[index];
                          return _PurchaseCartRow(item: item);
                        },
                      ),
                    ),
                  SizedBox(height: 14.h),
                  AppButton(
                    isLoading: controller.isAddLoading,
                    text: 'createBill',
                    onPressed: () async {
                      await controller.createPurchaseFromCart(context);
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

class _PurchaseSourceSelector extends GetView<BillsController> {
  const _PurchaseSourceSelector({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final source = controller.selectedPurchaseSource.value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.person_search_outlined,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source?.name ?? 'اختر المورد أو الزبون',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    source?.typeLabel ?? 'مصدر الشراء',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
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

  final dynamic product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inCart =
        controller.purchaseCart.any((item) => item.product.id == product.id);
    final hasImage = product.allImageUrlsInPriority.isNotEmpty;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? ProductPriorityImage(
                            imageUrls: product.allImageUrlsInPriority,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey.shade500,
                              size: 34.sp,
                            ),
                          ),
                    if (inCart)
                      Positioned(
                        top: 6.h,
                        right: 6.w,
                        child: CircleAvatar(
                          radius: 12.r,
                          backgroundColor: AppColors.primaryColor,
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14.sp,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'المخزون ${product.stock} • تكلفة ${product.purchaseCost.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseCartRow extends GetView<BillsController> {
  const _PurchaseCartRow({required this.item});

  final PurchaseCartItemModel item;

  @override
  Widget build(BuildContext context) {
    final intelligence = controller.purchasePriceIntelligence[item.product.id];
    final loading = controller.purchasePriceLoading.contains(item.product.id);
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.product.nameAr,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => controller.removePurchaseCartItem(item),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'quantity',
                  hintText: 'quantity',
                  controller: item.quantityController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => controller.calculatePurchaseCartTotal(),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: CustomTextField(
                  label: 'price',
                  hintText: 'price',
                  controller: item.priceController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => controller.calculatePurchaseCartTotal(),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                '${item.total.toStringAsFixed(2)} ₪',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (loading)
            LinearProgressIndicator(
              minHeight: 2.h,
              color: AppColors.primaryColor,
            )
          else if (intelligence != null && intelligence.isNotEmpty)
            _PurchasePriceIntelBox(
              item: item,
              intelligence: intelligence,
            ),
        ],
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
