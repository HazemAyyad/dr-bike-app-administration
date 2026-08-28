import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_upload_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/expenses_controller.dart';
import '../../widgets/financial_operational_ui.dart';
import 'destruction_product_picker_screen.dart';

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
              onTap: () => Get.to(() => const DestructionProductPickerScreen()),
              child: Row(children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.operationalSurface,
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(Icons.add_shopping_cart_outlined,
                      color: AppColors.operationalPurple, size: 21.sp),
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('فتح صفحة اختيار المنتجات',
                          style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.operationalNavy)),
                      SizedBox(height: 2.h),
                      Text('اضغط على المنتج ليضاف مباشرة إلى الجدول',
                          style: TextStyle(
                              fontSize: 9.5.sp,
                              color: AppColors.customGreyColor5)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded),
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
          Obx(() => InkWell(
                borderRadius: BorderRadius.circular(7.r),
                onTap: () => _editQuantity(context, line),
                child: Container(
                  width: 46.w,
                  height: 30.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.operationalPurple.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(7.r),
                    border: Border.all(
                      color: AppColors.operationalPurple.withValues(alpha: .24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${line.quantity.value}',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 12.sp)),
                      SizedBox(width: 3.w),
                      Icon(Icons.edit_outlined,
                          size: 11.sp, color: AppColors.operationalPurple),
                    ],
                  ),
                ),
              )),
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

  Future<void> _editQuantity(
    BuildContext context,
    DestructionDraftLine line,
  ) async {
    final input = TextEditingController(text: '${line.quantity.value}');
    final max = line.selectedLayer.value?.remainingQuantity.floor();
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل الكمية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (max != null)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text('الكمية المتاحة حسب سعر التكلفة: $max'),
              ),
            TextField(
              controller: input,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'الكمية',
                prefixIcon: Icon(Icons.numbers_rounded),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submitQuantity(dialogContext, input, max),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => _submitQuantity(dialogContext, input, max),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    input.dispose();
    if (result != null) line.quantity.value = result;
  }

  void _submitQuantity(
    BuildContext dialogContext,
    TextEditingController input,
    int? max,
  ) {
    final value = int.tryParse(input.text);
    if (value == null || value < 1 || (max != null && value > max)) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text(max == null
              ? 'أدخل كمية صحيحة أكبر من صفر'
              : 'الكمية يجب أن تكون بين 1 و $max'),
        ),
      );
      return;
    }
    Navigator.of(dialogContext).pop(value);
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
