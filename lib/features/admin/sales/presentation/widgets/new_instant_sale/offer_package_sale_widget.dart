import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import 'package:doctorbike/features/admin/stock/data/models/offer_package_model.dart';
import '../../controllers/sales_controller.dart';
import '../../utils/sales_amount_format.dart';

/// ملخص الباكيج المختار في شاشة الدفع (الاختيار من شاشة المنتجات).
class OfferPackageCheckoutSection extends GetView<SalesController> {
  const OfferPackageCheckoutSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isPackageSale.value) {
        return const SizedBox.shrink();
      }

      final pkg = controller.selectedOfferPackage;
      final lineTotal = controller.packageLineTotal.value;

      if (pkg == null) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Text(
            'packageSelectFirst'.tr,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.orange.shade800,
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFFFCC80)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.card_giftcard_rounded,
                  color: const Color(0xFFE65100),
                  size: 22.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'saleOfferPackage'.tr,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                      Text(
                        pkg.name,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          _PackageSaleQuantityRow(
            controller: controller,
            pkg: pkg,
            lineTotal: lineTotal,
          ),
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
  final double lineTotal;

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
                  controller.instantSaleFormKey.currentState?.validate();
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
                hintText: SalesAmountFormat.display(lineTotal),
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
