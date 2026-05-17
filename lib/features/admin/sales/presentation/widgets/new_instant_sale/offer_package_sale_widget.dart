import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import 'package:doctorbike/features/admin/stock/data/models/offer_package_model.dart';
import '../../controllers/sales_controller.dart';

class OfferPackageSaleWidget extends GetView<SalesController> {
  const OfferPackageSaleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPackage = controller.isPackageSale.value;
      final pkg = controller.selectedOfferPackage;
      final lineTotal = controller.packageLineTotal.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text('item'.tr),
                  selected: !isPackage,
                  onSelected: (_) => controller.setPackageSaleMode(false),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ChoiceChip(
                  label: Text('saleOfferPackage'.tr),
                  selected: isPackage,
                  onSelected: (_) => controller.setPackageSaleMode(true),
                ),
              ),
            ],
          ),
          if (isPackage) ...[
            SizedBox(height: 12.h),
            DropdownSearch<OfferPackageModel>(
              selectedItem: pkg,
              items: (filter, _) => controller.offerPackagesForSale,
              itemAsString: (p) =>
                  '${p.name} — ${'unitPackagePrice'.tr}: ${p.price} (${'maxPackagesToSell'.tr}: ${p.maxSellableQuantity})',
              compareFn: (a, b) => a.id == b.id,
              onChanged: controller.onOfferPackageSelected,
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'selectOfferPackage'.tr,
                  filled: true,
                  fillColor: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.whiteColor2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              popupProps: const PopupProps.menu(showSearchBox: true),
            ),
            SizedBox(height: 10.h),
            _PackageSaleQuantityRow(
              controller: controller,
              pkg: pkg,
              lineTotal: lineTotal,
            ),
          ],
        ],
      );
    });
  }
}

class _PackageSaleQuantityRow extends StatelessWidget {
  const _PackageSaleQuantityRow({
    required this.controller,
    required this.pkg,
    required this.lineTotal,
  });

  final SalesController controller;
  final OfferPackageModel? pkg;
  final int lineTotal;

  @override
  Widget build(BuildContext context) {
    final item = controller.items.first;
    final helper = controller.packageSaleQuantityHelperText();
    final accent = ThemeService.isDark.value
        ? AppColors.primaryColor
        : AppColors.secondaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomTextField(
                key: ValueKey('pkg_qty_${pkg?.id ?? 'none'}'),
                isRequired: true,
                label: 'packageSaleQuantity',
                hintText: '1',
                controller: item.quantityController,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  controller.calculateGrandTotal();
                  controller.formKey.currentState?.validate();
                },
                validator: controller.validatePackageSaleQuantity,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: CustomTextField(
                isRequired: false,
                label: 'unitPackagePrice',
                hintText: '0',
                controller: item.priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: false,
                validator: (_) => null,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: CustomTextField(
                enabled: false,
                label: 'total',
                hintText: lineTotal.toString(),
                validator: (_) => null,
              ),
            ),
          ],
        ),
        if (helper != null) ...[
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              helper,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12.sp,
                    color: pkg != null && pkg!.maxSellableQuantity < 1
                        ? AppColors.redColor
                        : accent,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
