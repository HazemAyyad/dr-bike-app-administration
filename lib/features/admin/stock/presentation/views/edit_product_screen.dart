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
