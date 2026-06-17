import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/sales_controller.dart';
import '../../utils/sales_amount_format.dart';

class DiscountWidget extends GetView<SalesController> {
  const DiscountWidget({
    Key? key,
    this.showNotes = true,
    this.showHints = true,
  }) : super(key: key);

  final bool showNotes;
  final bool showHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'discount',
                hintText: 'discountExample',
                controller: controller.discountController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  controller.calculateGrandTotal();
                },
                validator: (value) {
                  return null;
                },
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Obx(
                () => CustomTextField(
                  enabled: false,
                  label: 'totalBill',
                  hintText:
                      SalesAmountFormat.display(controller.totalCost.value),
                  controller: controller.totalController,
                  keyboardType: TextInputType.number,
                  validator: (p0) => null,
                  onChanged: (value) {
                    controller.calculateGrandTotal();
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        if (showNotes) ...[
          _InstantSaleNotesRepeater(),
          SizedBox(height: 20.h),
        ],
        if (showHints) ...[
          Row(
            children: [
              Text(
                'readItem'.tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
              )
            ],
          ),
          SizedBox(height: 7.h),
          Row(
            children: [
              Text(
                'readQuantity'.tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
              )
            ],
          ),
        ],
      ],
    );
  }
}

class _InstantSaleNotesRepeater extends GetView<SalesController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'notes'.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: ThemeService.isDark.value
                            ? AppColors.primaryColor
                            : AppColors.secondaryColor,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showNoteModal(context),
                icon: Icon(Icons.add, size: 18.sp),
                label: Text('addNote'.tr),
              ),
            ],
          ),
          if (controller.instantSaleNotes.isEmpty)
            OutlinedButton.icon(
              onPressed: () => _showNoteModal(context),
              icon: const Icon(Icons.note_add_outlined),
              label: Text('addNote'.tr),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.customGreyColor3),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor4
                        : AppColors.whiteColor2,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'notes'.tr,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'additionalPrice'.tr,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 80.w),
                      ],
                    ),
                  ),
                  ...List.generate(controller.instantSaleNotes.length, (index) {
                    final line = controller.instantSaleNotes[index];
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.customGreyColor3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              line.text.text.trim().isEmpty
                                  ? '-'
                                  : line.text.text.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              SalesAmountFormat.display(
                                SalesAmountFormat.parse(line.amount.text),
                              ),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80.w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'edit'.tr,
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(Icons.edit_outlined, size: 18.sp),
                                  color: AppColors.primaryColor,
                                  onPressed: () =>
                                      _showNoteModal(context, index: index),
                                ),
                                IconButton(
                                  tooltip: 'delete'.tr,
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(Icons.delete_outline, size: 18.sp),
                                  color: Colors.red.shade400,
                                  onPressed: () => controller
                                      .removeInstantSaleNoteLine(index),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          if (controller.instantSaleNotesTotal > 0)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${'notesTotal'.tr}: ${SalesAmountFormat.display(controller.instantSaleNotesTotal)} ${'currency'.tr}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showNoteModal(BuildContext context, {int? index}) async {
    final existing = index != null &&
            index >= 0 &&
            index < controller.instantSaleNotes.length
        ? controller.instantSaleNotes[index]
        : null;
    final textController =
        TextEditingController(text: existing?.text.text ?? '');
    final amountController =
        TextEditingController(text: existing?.amount.text ?? '');

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      index == null ? 'addNote'.tr : 'editNote'.tr,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    CustomTextField(
                      minLines: 4,
                      maxLines: 6,
                      label: 'notes',
                      hintText: 'detailsExample',
                      controller: textController,
                      validator: (_) => null,
                    ),
                    SizedBox(height: 10.h),
                    CustomTextField(
                      label: 'additionalPrice',
                      hintText: '0',
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      validator: (_) => null,
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: Text('cancel'.tr),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              controller.saveInstantSaleNoteLine(
                                index: index,
                                text: textController.text,
                                amount: amountController.text,
                              );
                              Navigator.pop(sheetContext);
                            },
                            child: Text('save'.tr),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      textController.dispose();
      amountController.dispose();
    }
  }
}
