import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../controllers/stock_controller.dart';
import '../widgets/search_widget.dart';

class CloseoutsScreen extends GetView<StockController> {
  const CloseoutsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'newCloseouts',
        action: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 16.h),
            child: SearchWidget(isCloseouts: true),
          )),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  CustomTextField(
                    enabled: false,
                    label: 'productName',
                    hintText: 'productName',
                    controller: controller.closeoutsProductNameController,
                  ),
                  SizedBox(height: 20.h),
                  CustomTextField(
                    enabled: false,
                    label: 'minimumSale',
                    hintText: 'minimumSale',
                    controller: controller.closeoutsMinimumSaleController,
                  ),
                  SizedBox(height: 30.h),
                  AppButton(
                    isLoading: controller.isLoading,
                    text: 'addCloseout',
                    onPressed: () {
                      if (controller.closeoutsProductsId.isNotEmpty) {
                        controller.toggleAddMenu();
                        controller.moveProductToArchive(
                          context: context,
                          productId: controller.closeoutsProductsId,
                          isMove: false,
                        );
                        controller.closeoutsProductsId = '';
                      } else {
                        Get.snackbar(
                          'error'.tr,
                          'برجاء اختيار منتج'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(milliseconds: 1500),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
