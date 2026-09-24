import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/boxes_controller.dart';

class AddBalanceWidget extends GetView<BoxesController> {
  const AddBalanceWidget({Key? key, required this.boxId}) : super(key: key);

  final int boxId;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(15.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: 25.h,
                  color: AppColors.primaryColor,
                ),
                SizedBox(width: 5.w),
                Text(
                  'addBalance'.tr,
                  style: textStyle.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Form(
              key: controller.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () => Wrap(
                      spacing: 8.w,
                      children: [
                        ChoiceChip(
                          label: const Text('إضافة رصيد'),
                          selected:
                              controller.balanceAdjustmentDirection.value ==
                                  'add',
                          onSelected: (_) {
                            controller.balanceAdjustmentDirection.value = 'add';
                            controller.balanceAdjustmentReason.value = '';
                          },
                        ),
                        ChoiceChip(
                          label: const Text('سحب رصيد'),
                          selected:
                              controller.balanceAdjustmentDirection.value ==
                                  'subtract',
                          onSelected: (_) {
                            controller.balanceAdjustmentDirection.value =
                                'subtract';
                            controller.balanceAdjustmentReason.value = '';
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  CustomTextField(
                    isRequired: true,
                    label: 'value'.tr,
                    labelTextstyle:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: AppColors.primaryColor,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                    hintText: 'totalExample',
                    controller: controller.addBalanceValueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      key: ValueKey(
                        controller.balanceAdjustmentDirection.value,
                      ),
                      initialValue:
                          controller.balanceAdjustmentReason.value.isEmpty
                              ? null
                              : controller.balanceAdjustmentReason.value,
                      decoration: const InputDecoration(
                        labelText: 'سبب الحركة',
                        border: OutlineInputBorder(),
                      ),
                      items: controller.availableBalanceReasons.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => controller
                          .balanceAdjustmentReason.value = value ?? '',
                      validator: (value) => value == null || value.isEmpty
                          ? 'اختر سبب حركة الصندوق'
                          : null,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  CustomTextField(
                    label: 'note'.tr,
                    hintText: 'noteHint'.tr,
                    controller: controller.addBalanceNoteController,
                    minLines: 3,
                    maxLines: 5,
                    validator: (_) => null,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            AppButton(
              isSafeArea: false,
              isLoading: controller.isAddBoxLoading,
              text: 'apply',
              textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.whiteColor,
                  ),
              onPressed: () {
                controller.addBoxBalance(
                  context,
                  boxId.toString(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
