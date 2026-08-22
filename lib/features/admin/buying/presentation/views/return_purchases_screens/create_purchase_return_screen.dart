import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../controllers/bills_controller.dart';

class CreatePurchaseReturnScreen extends GetView<BillsController> {
  const CreatePurchaseReturnScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    controller.preparePurchaseReturnForm();
    controller.loadPurchaseBoxes();
    return Scaffold(
      appBar: const CustomAppBar(title: 'returnPurchase', action: false),
      body: GetBuilder<BillsController>(
        builder: (controller) {
          return ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            children: [
              Text(
                'مرتجع مشتريات جديد',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18.sp,
                    ),
              ),
              SizedBox(height: 12.h),
              _SourceSelector(controller: controller),
              SizedBox(height: 12.h),
              _SettlementSelector(controller: controller),
              if (controller.purchaseReturnResolution.value ==
                  'cash_refund') ...[
                SizedBox(height: 12.h),
                CustomDropdownFieldWithSearch(
                  tital: 'boxName',
                  hint: 'boxNameExample',
                  items: controller.purchaseBoxes,
                  value: controller.selectedPurchaseBox.value,
                  onChanged: (value) => controller.selectPurchaseBox(
                    value is ShownBoxesModel ? value : null,
                  ),
                  itemAsString: (item) => '${item.boxName} (${item.currency})',
                  compareFn: (a, b) => a.boxId == b.boxId,
                ),
              ],
              SizedBox(height: 12.h),
              CustomTextField(
                label: 'notes',
                hintText: 'سبب المرتجع / ملاحظات التسوية',
                controller: controller.purchaseReturnNoteController,
                isRequired: false,
                validator: (_) => null,
              ),
              SizedBox(height: 16.h),
              SearchBar(
                shadowColor: WidgetStateProperty.all(Colors.transparent),
                leading: const Icon(Icons.search),
                hintText: 'بحث عن منتج للمرتجع',
                onChanged: controller.onPurchaseProductSearchChanged,
              ),
              SizedBox(height: 12.h),
              _ProductGrid(controller: controller),
              if (controller.purchaseCart.isNotEmpty) ...[
                SizedBox(height: 16.h),
                _ReturnCart(controller: controller),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: GetBuilder<BillsController>(
        builder: (controller) {
          return SafeArea(
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'الإجمالي: ${controller.totalCost.value}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160.w,
                    child: AppButton(
                      isLoading: controller.isWorkflowLoading,
                      text: 'تأكيد المرتجع',
                      onPressed: () =>
                          controller.createPurchaseReturnFromCart(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SourceSelector extends StatelessWidget {
  final BillsController controller;

  const _SourceSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomDropdownFieldWithSearch(
      tital: 'sellerName1',
      hint: 'اختر المورد / الشخص',
      items: controller.purchaseSources,
      value: controller.selectedPurchaseSource.value,
      onChanged: (value) => controller
          .selectPurchaseSource(value is PurchaseSourceModel ? value : null),
      itemAsString: (item) => '${item.name} - ${item.typeLabel}',
      compareFn: (a, b) => a.id == b.id && a.typeLabel == b.typeLabel,
    );
  }
}

class _SettlementSelector extends StatelessWidget {
  final BillsController controller;

  const _SettlementSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    final options = const {
      'supplier_credit': 'رصيد / تخفيض مديونية',
      'cash_refund': 'استرداد نقدي',
    };
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: options.entries.map((entry) {
        final selected = controller.purchaseReturnResolution.value == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: selected,
          selectedColor: AppColors.primaryColor.withValues(alpha: 0.14),
          onSelected: (_) =>
              controller.changePurchaseReturnResolution(entry.key),
        );
      }).toList(),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final BillsController controller;

  const _ProductGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    final products = controller.filteredPurchaseProducts.take(12).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Get.width > 700 ? 4 : 2,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (_, index) {
        final product = products[index];
        return InkWell(
          onTap: () => controller.addProductToPurchaseCart(product),
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(8.r)),
                    child: product.preferredImageUrl.isEmpty
                        ? Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Icon(Icons.inventory_2_outlined),
                            ),
                          )
                        : Image.network(
                            product.preferredImageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: Icon(Icons.inventory_2_outlined),
                              ),
                            ),
                          ),
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
                          fontWeight: FontWeight.w800,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'مخزون: ${product.stock}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11.sp,
                        ),
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
  }
}

class _ReturnCart extends StatelessWidget {
  final BillsController controller;

  const _ReturnCart({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'منتجات المرتجع',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.sp),
        ),
        SizedBox(height: 8.h),
        ...controller.purchaseCart.map(
          (item) => Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => controller.removePurchaseCartItem(item),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: item.quantityController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) =>
                            controller.calculatePurchaseCartTotal(),
                        decoration: const InputDecoration(labelText: 'الكمية'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextField(
                        controller: item.priceController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) =>
                            controller.calculatePurchaseCartTotal(),
                        decoration: const InputDecoration(labelText: 'السعر'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text('المجموع: ${item.total.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
