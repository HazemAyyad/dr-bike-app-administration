import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_controller.dart';
import '../widgets/new_instant_sale/add_new_instant_sale.dart';
import '../widgets/new_instant_sale/discount_widget.dart';

class NewInstantSaleScreen extends GetView<SalesController> {
  const NewInstantSaleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'newInstantSale'.tr, action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              SizedBox(height: 5.h),
              AddNewInstantSaleWidget(),
              Divider(
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
                thickness: 0.8,
                height: 1,
              ),
              SizedBox(height: 20.h),
              DiscountWidget(),
              SizedBox(height: 20.h),
              AppButton(
                isLoading: controller.isLoading,
                text: 'complete'.tr,
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                onPressed: () {
                  controller.addInstantSale(context: context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
