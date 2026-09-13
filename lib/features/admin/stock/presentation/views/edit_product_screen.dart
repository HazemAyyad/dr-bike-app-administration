import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../controllers/stock_controller.dart';
import '../widgets/edit_product_layout_widgets.dart';
import '../widgets/product_options_picker.dart';
import '../widgets/store_location_edit_section.dart';

class EditProductScreen extends GetView<StockController> {
  const EditProductScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUiColors.scaffoldBackground(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(
          () => CustomAppBar(
            title: controller.editingProductId.value == null
                ? 'addProduct'
                : 'editProduct',
            action: false,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 6.h),
                  EditProductHero(controller: controller),
                  SizedBox(height: 8.h),
                  EditProductOverviewSection(controller: controller),
                  Obx(() => controller.editingProductId.value == null
                      ? _OpeningStockSection(controller: controller)
                      : const SizedBox.shrink()),
                  SizedBox(height: 12.h),
                  EditSizeColorSection(controller: controller),
                  SizedBox(height: 12.h),
                  const StoreLocationPickerTile(),
                  SizedBox(height: 10.h),
                  const ProductOptionsPickerTile(),
                  SizedBox(height: 12.h),
                  EditProductMediaSection(controller: controller),
                  SizedBox(height: 16.h),
                  EditProductSaveBar(controller: controller),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpeningStockSection extends StatelessWidget {
  const _OpeningStockSection({required this.controller});

  final StockController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('إضافة مخزون افتتاحي',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text(
                    'اختياري، ويُسجل كحركة وطبقة تكلفة ضمن نفس العملية.'),
                value: controller.addOpeningStock.value,
                onChanged: (value) => controller.addOpeningStock.value = value,
              ),
              if (controller.addOpeningStock.value) ...[
                if (controller.items.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                        'للمنتج ذي المتغيرات أدخل كمية وتكلفة الافتتاح داخل كل مقاس/لون.',
                        style: TextStyle(color: Colors.orange)),
                  )
                else ...[
                  Row(children: [
                    Expanded(
                        child: TextField(
                      controller: controller.openingQuantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'كمية الافتتاح',
                          border: OutlineInputBorder()),
                    )),
                    SizedBox(width: 8.w),
                    Expanded(
                        child: TextField(
                      controller: controller.openingUnitCostController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'تكلفة الوحدة',
                          border: OutlineInputBorder()),
                    )),
                  ]),
                  SizedBox(height: 10.h),
                ],
                Row(children: [
                  SizedBox(
                    width: 105.w,
                    child: TextField(
                      controller: controller.openingCurrencyController,
                      decoration: const InputDecoration(
                          labelText: 'العملة', border: OutlineInputBorder()),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                      child: TextField(
                    controller: controller.openingNotesController,
                    decoration: const InputDecoration(
                        labelText: 'ملاحظات', border: OutlineInputBorder()),
                  )),
                ]),
              ],
            ],
          )),
    );
  }
}
