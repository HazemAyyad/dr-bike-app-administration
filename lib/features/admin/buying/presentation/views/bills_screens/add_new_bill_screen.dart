import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/bills_controller.dart';

class AddNewBillScreen extends GetView<BillsController> {
  const AddNewBillScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    SizedBox(width: 10.h),
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
