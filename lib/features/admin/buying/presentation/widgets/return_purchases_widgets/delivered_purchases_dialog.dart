import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/return_purchases_controller.dart';

class DeliveredPurchasesDialog extends GetView<ReturnPurchasesController> {
  const DeliveredPurchasesDialog({Key? key, required this.billId})
      : super(key: key);

  final String billId;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomCheckBox(
              title: 'moved_to_delivered',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                  ),
              value: controller.movedToDelivered,
              onChanged: (value) {
                controller.movedToDelivered.value = value!;
              },
            ),
            SizedBox(height: 20.h),
            AppButton(
              isLoading: controller.isLoading,
              isSafeArea: false,
              text: 'save',
              onPressed: () {
                controller.changeReturnToDelivered(
                  context: context,
                  returnPurchaseId: billId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
