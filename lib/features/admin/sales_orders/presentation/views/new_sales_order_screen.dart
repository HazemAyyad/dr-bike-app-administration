import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../sales/presentation/controllers/sales_controller.dart';
import '../../../sales/presentation/utils/sales_amount_format.dart';
import '../../../sales/presentation/widgets/new_instant_sale/instant_sale_picker_partner_bar.dart';
import '../controllers/sales_orders_controller.dart';

class NewSalesOrderScreen extends StatefulWidget {
  const NewSalesOrderScreen({Key? key}) : super(key: key);

  @override
  State<NewSalesOrderScreen> createState() => _NewSalesOrderScreenState();
}

class _NewSalesOrderScreenState extends State<NewSalesOrderScreen> {
  SalesOrdersController get controller => Get.find<SalesOrdersController>();
  SalesController get sales => Get.find<SalesController>();

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      controller.resetCreateForm();
      sales.getAllProducts();
      await sales.ensurePickerPartnersLoaded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SalesOrdersController.surfaceGray,
      appBar: CustomAppBar(
        title: 'instantSalePickProducts',
        action: false,
        actions: [
          const InstantSalePickerPartnerIcon(),
          IconButton(
            tooltip: 'instantSaleCart'.tr,
            icon: Obx(() {
              final n = controller.cartItems.length;
              return Badge(
                isLabelVisible: n > 0,
                label: Text('$n'),
                child: const Icon(Icons.shopping_cart_outlined),
              );
            }),
            onPressed: _showCartSheet,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: Column(
          children: [
            _partnerBar(),
            SizedBox(height: 10.h),
            _metaBar(),
            SizedBox(height: 10.h),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'instantSaleSearchProductsAndPackages'.tr,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: SalesOrdersController.cardGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onChanged: sales.onInstantSaleProductSearchChanged,
            ),
            SizedBox(height: 10.h),
            Expanded(child: _productsList()),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: ElevatedButton(
            onPressed: () => Get.offNamed(AppRoutes.NEWSALESORDERSCREEN),
            style: ElevatedButton.styleFrom(
              backgroundColor: SalesOrdersController.textPrimary,
              foregroundColor: SalesOrdersController.cardGray,
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
            child: Text(
              'save'.tr,
              style: TextStyle(fontSize: 15.sp),
            ),
          ),
        ),
      ),
    );
  }

  Widget _partnerBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SalesOrdersController.borderGray),
      ),
      child: Obx(() {
        final partner = sales.pickerSelectedPartner.value;
        final isCustomer = sales.pickerPartnerIsCustomer.value;
        final label = partner == null ? '—' : partner.name;
        return Row(
          children: [
            Expanded(
              child: Text(
                '${isCustomer ? 'customer'.tr : 'seller'.tr}: $label',
                style: TextStyle(
                  color: SalesOrdersController.textPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await showInstantSalePickerPartnerSheet(context);
                final p = sales.pickerSelectedPartner.value;
                if (p != null) {
                  controller.customerNameController.text = p.name;
                  controller.customerPhoneController.text = p.phone;
                }
              },
              child: Text('choose'.tr),
            ),
          ],
        );
      }),
    );
  }

  Widget _metaBar() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SalesOrdersController.borderGray),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<int>(
                    initialValue: controller.selectedCityId.value,
                    hint: Text('city'.tr),
                    decoration: _inputDecoration(),
                    items: controller.cities
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameAr)))
                        .toList(),
                    onChanged: (v) => controller.selectedCityId.value = v,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: controller.selectedPaymentType.value,
                    decoration: _inputDecoration(),
                    items: [
                      DropdownMenuItem(value: 'cash', child: Text('cash'.tr)),
                      DropdownMenuItem(value: 'credit', child: Text('credit'.tr)),
                      DropdownMenuItem(value: 'visa', child: Text('visa'.tr)),
                      DropdownMenuItem(value: 'mixed', child: Text('salesOrderMixed'.tr)),
                    ],
                    onChanged: (v) {
                      if (v != null) controller.selectedPaymentType.value = v;
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: controller.notesController,
            maxLines: 2,
            decoration: _inputDecoration().copyWith(
              hintText: 'note'.tr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productsList() {
    return Obx(() {
      final _ = sales.productsListVersion.value;
      final loading = sales.productsLoading.value || sales.instantSalePickerSearchLoading.value;
      if (loading) {
        return const Center(child: CircularProgressIndicator());
      }

      final products = sales.filteredProductsForPicker;
      if (products.isEmpty) {
        return Center(
          child: Text(
            'noData'.tr,
            style: TextStyle(color: SalesOrdersController.textSecondary, fontSize: 13.sp),
          ),
        );
      }

      return ListView.separated(
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (context, index) {
          final p = products[index];
          final title = (p.nameAr).isNotEmpty ? p.nameAr : '#${p.id}';

          return ListTile(
            tileColor: SalesOrdersController.cardGray,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
              side: const BorderSide(color: SalesOrdersController.borderGray),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: SalesOrdersController.textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${'price'.tr}: ${p.unitPrice}',
              style: TextStyle(color: SalesOrdersController.textSecondary, fontSize: 12.sp),
            ),
            trailing: const Icon(Icons.add),
            onTap: () async => _addProductToCart(p),
          );
        },
      );
    });
  }

  Future<void> _addProductToCart(dynamic product) async {
    final resolved = await sales.ensureProductPricesForPicker(product);
    if (resolved == null) return;
    if (!mounted) return;

    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: resolved.unitPrice.toString());

    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: SalesOrdersController.surfaceGray,
            title: Text('salesOrderAddItem'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(qtyController, 'quantity'.tr, number: true),
                _field(priceController, 'price'.tr, number: true),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('add'.tr)),
            ],
          ),
        ) ??
        false;

    if (!ok) return;
    final qty = SalesAmountFormat.parse(qtyController.text).round();
    final price = SalesAmountFormat.parse(priceController.text);
    if (qty <= 0 || price <= 0) return;

    controller.addCartItem(
      SalesOrderCartItem(
        productId: int.tryParse(resolved.id.toString()) ?? 0,
        productName: (resolved.nameAr).isNotEmpty ? resolved.nameAr : '#${resolved.id}',
        quantity: qty,
        unitPrice: price,
      ),
    );
  }

  void _showCartSheet() {
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: SalesOrdersController.surfaceGray,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: Obx(() {
            final items = controller.cartItems;
            if (items.isEmpty) {
              return SizedBox(
                height: 160.h,
                child: Center(
                  child: Text(
                    'instantSaleCartEmpty'.tr,
                    style: TextStyle(color: SalesOrdersController.textSecondary, fontSize: 13.sp),
                  ),
                ),
              );
            }
            return SizedBox(
              height: 420.h,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (ctx, i) {
                  final it = items[i];
                  return Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: SalesOrdersController.cardGray,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: SalesOrdersController.borderGray),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            it.productName,
                            style: TextStyle(color: SalesOrdersController.textPrimary, fontSize: 13.sp),
                          ),
                        ),
                        Text(
                          '${it.quantity}×${it.unitPrice.toStringAsFixed(2)}',
                          style: TextStyle(color: SalesOrdersController.textSecondary, fontSize: 12.sp),
                        ),
                        IconButton(
                          onPressed: () => controller.removeCartItem(i),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: SalesOrdersController.textPrimary, fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: SalesOrdersController.textSecondary),
          filled: true,
          fillColor: SalesOrdersController.cardGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: SalesOrdersController.borderGray),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
        filled: true,
        fillColor: SalesOrdersController.cardGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: SalesOrdersController.borderGray),
        ),
      );
}
