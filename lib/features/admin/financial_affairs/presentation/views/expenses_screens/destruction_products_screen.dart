import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_upload_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../stock/presentation/widgets/search_widget.dart';
import '../../controllers/expenses_controller.dart';

class DestructionProductsScreen extends GetView<ExpensesController> {
  const DestructionProductsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'DestructionProducts', action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              SearchWidget(
                isCloseouts: true,
                productIdController: controller.productIdController,
                productNameController: controller.productNameController,
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      enabled: false,
                      controller: controller.productNameController,
                      label: 'productName',
                      hintText: 'productName',
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: CustomTextField(
                      controller: controller.piecesCountController,
                      label: 'piecesCount',
                      hintText: 'targetValueExample',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              CustomTextField(
                controller: controller.damageReasonController,
                label: 'damageReason',
                hintText: 'damageReason',
              ),
              SizedBox(height: 20.h),
              MediaUploadButton(
                onFilesChanged: (files) {
                  controller.assetsFile = files;
                },
                title: 'uploadMedia',
              ),
              SizedBox(height: 40.h),
              AppButton(
                isLoading: controller.isLoading,
                text: 'goodsDamageTitle',
                onPressed: () {
                  controller.addDestruction(context);
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
