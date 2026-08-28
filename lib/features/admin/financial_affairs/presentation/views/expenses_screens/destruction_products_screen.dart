import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_upload_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../stock/presentation/widgets/search_widget.dart';
import '../../controllers/expenses_controller.dart';
import '../../widgets/financial_operational_ui.dart';

class DestructionProductsScreen extends GetView<ExpensesController> {
  const DestructionProductsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'DestructionProducts', action: false),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 90.h),
          children: [
            const FinancialGroupTitle(title: 'اختيار المنتجات'),
            FinancialOperationalCard(
              child: Column(children: [
                SearchWidget(
                  isCloseouts: true,
                  productIdController: controller.productIdController,
                  productNameController: controller.productNameController,
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        controller.addSelectedDestructionProduct(context),
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    label: const Text('إضافة المنتج إلى جدول الإتلاف'),
                  ),
                ),
              ]),
            ),
            Obx(() => controller.destructionDraftLines.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Text('اختر منتجًا ليظهر هنا',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.customGreyColor5,
                            fontSize: 12.sp)),
                  )
                : Column(children: [
                    FinancialGroupTitle(
                        title: 'بنود الإتلاف',
                        count: controller.destructionDraftLines.length),
                    ...controller.destructionDraftLines.asMap().entries.map(
                          (entry) => _DestructionLineCard(
                              line: entry.value,
                              onDelete: () =>
                                  controller.removeDestructionLine(entry.key)),
                        ),
                  ])),
            const FinancialGroupTitle(title: 'سبب الإتلاف والمرفقات'),
            FinancialOperationalCard(
              child: Column(children: [
                CustomTextField(
                  controller: controller.damageReasonController,
                  label: 'damageReason',
                  hintText: 'damageReason',
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 3,
                  maxLines: 7,
                ),
                SizedBox(height: 10.h),
                MediaUploadButton(
                  onFilesChanged: (files) => controller.assetsFile = files,
                  title: 'uploadMedia',
                ),
              ]),
            ),
            SizedBox(height: 14.h),
            AppButton(
              isLoading: controller.isLoading,
              text: 'goodsDamageTitle',
              onPressed: () => controller.addDestruction(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestructionLineCard extends StatelessWidget {
  const _DestructionLineCard({required this.line, required this.onDelete});
  final DestructionDraftLine line;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return FinancialOperationalCard(
      child: Column(children: [
        Row(children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: AppColors.operationalSurface,
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Icon(Icons.inventory_2_outlined,
                color: AppColors.operationalPurple, size: 18.sp),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(line.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.operationalNavy)),
          ),
          IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red)),
        ]),
        SizedBox(height: 7.h),
        Row(children: [
          Text('الكمية', style: TextStyle(fontSize: 10.sp)),
          SizedBox(width: 6.w),
          _QtyButton(
              icon: Icons.remove,
              onTap: () {
                if (line.quantity.value > 1) line.quantity.value--;
              }),
          Obx(() => SizedBox(
              width: 38.w,
              child: Text('${line.quantity.value}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 12.sp)))),
          _QtyButton(
              icon: Icons.add,
              onTap: () {
                final max = line.selectedLayer.value?.remainingQuantity;
                if (max == null || line.quantity.value < max) {
                  line.quantity.value++;
                }
              }),
          SizedBox(width: 8.w),
          Expanded(
            child: line.layers.isEmpty
                ? const FinancialMiniChip(
                    label: 'لا توجد طبقات تكلفة', color: Colors.red)
                : Obx(() => DropdownButtonFormField<DestructionCostLayer>(
                      isExpanded: true,
                      initialValue: line.selectedLayer.value,
                      decoration: const InputDecoration(
                        labelText: 'سعر التكلفة والكمية المتاحة',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: line.layers
                          .map((layer) => DropdownMenuItem(
                                value: layer,
                                child: Text(
                                    '${layer.unitCost} ${layer.currency} · متاح ${layer.remainingQuantity}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (value) {
                        line.selectedLayer.value = value;
                        if (value != null &&
                            line.quantity.value > value.remainingQuantity) {
                          line.quantity.value = value.remainingQuantity.floor();
                        }
                      },
                    )),
          ),
        ]),
        Obx(() {
          final cost = line.selectedLayer.value?.unitCost ?? 0;
          return Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: FinancialMiniChip(
                label:
                    'الإجمالي ${(cost * line.quantity.value).toStringAsFixed(2)} شيكل',
                color: AppColors.operationalPurple,
                icon: Icons.calculate_outlined,
              ),
            ),
          );
        }),
      ]),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: AppColors.operationalSurface,
            borderRadius: BorderRadius.circular(7.r),
          ),
          child: Icon(icon, size: 16.sp, color: AppColors.operationalPurple),
        ),
      );
}
