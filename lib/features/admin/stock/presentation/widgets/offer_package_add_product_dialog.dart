import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/all_stock_products_model.dart';
import '../controllers/offer_packages_controller.dart';

class OfferPackageAddProductDialog extends StatefulWidget {
  const OfferPackageAddProductDialog({
    Key? key,
    required this.controller,
    this.initial,
  }) : super(key: key);

  final OfferPackagesController controller;
  final OfferPackageProductRow? initial;

  @override
  State<OfferPackageAddProductDialog> createState() =>
      _OfferPackageAddProductDialogState();
}

class _OfferPackageAddProductDialogState
    extends State<OfferPackageAddProductDialog> {
  late final TextEditingController quantityController;
  AllStockProductsModel? selectedProduct;
  bool get isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController(
      text: widget.initial?.quantityPerPackage.toString() ?? '1',
    );
    if (widget.initial != null) {
      selectedProduct = AllStockProductsModel(
        closeoutId: 0,
        closeoutStatus: 'unarchived',
        productId: widget.initial!.productId,
        name: widget.initial!.productName,
        stock: widget.initial!.stock,
        productMinSalePrice: '0',
        normailPrice: widget.initial!.unitPrice,
        image: 'no image',
        numberOfUsedProducts: '0',
      );
    }
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final isDark = ThemeService.isDark.value;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Dialog(
      backgroundColor: isDark ? AppColors.customGreyColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'editPackageProduct'.tr : 'addProductToPackage'.tr,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            SizedBox(height: 16.h),
            DropdownSearch<AllStockProductsModel>(
              selectedItem: selectedProduct,
              items: (filter, _) async {
                if (filter.trim().length < 2 && selectedProduct == null) {
                  return selectedProduct != null ? [selectedProduct!] : [];
                }
                if (filter.trim().length < 2 && selectedProduct != null) {
                  return [selectedProduct!];
                }
                await c.searchProducts(filter);
                return c.searchResults.toList();
              },
              itemAsString: (p) =>
                  '${p.name} (${'stock'.tr}: ${p.stock}) — ${p.normailPrice}',
              compareFn: (a, b) => a.productId == b.productId,
              onChanged: (value) => setState(() => selectedProduct = value),
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'selectProduct'.tr,
                  labelStyle: TextStyle(color: textColor),
                  filled: true,
                  fillColor:
                      isDark ? AppColors.customGreyColor4 : AppColors.whiteColor2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11.r),
                    borderSide: BorderSide(color: AppColors.customGreyColor3),
                  ),
                ),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(hintText: 'search'.tr),
                ),
                loadingBuilder: (_, __) =>
                    const Center(child: CircularProgressIndicator()),
                emptyBuilder: (_, __) => Center(child: Text('noData'.tr)),
              ),
            ),
            SizedBox(height: 12.h),
            CustomTextField(
              label: 'quantityPerPackage',
              hintText: '1',
              controller: quantityController,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                    ),
                    child: Text('cancel'.tr),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    onPressed: _save,
                    child: Text(isEdit ? 'save'.tr : 'add'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (selectedProduct == null) {
      Get.snackbar('error'.tr, 'selectProduct'.tr);
      return;
    }
    final qty = int.tryParse(quantityController.text.trim()) ?? 0;
    if (qty < 1) {
      Get.snackbar('error'.tr, 'requiredField'.tr);
      return;
    }
    Get.back(
      result: OfferPackageProductRow(
        productId: selectedProduct!.productId,
        productName: selectedProduct!.name,
        stock: selectedProduct!.stock,
        unitPrice: selectedProduct!.normailPrice,
        quantityPerPackage: qty,
      ),
    );
  }
}
