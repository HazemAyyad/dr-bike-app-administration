import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';

class StockProductSelectionBar extends GetView<StockController> {
  const StockProductSelectionBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.productSelectionActive) {
        return const SizedBox.shrink();
      }
      final deleteMode = controller.deleteSelectionActive.value;
      final countA = controller.swapGroupAIds.length;
      final countB = controller.swapGroupBIds.length;
      final total =
          deleteMode ? controller.selectedProductIds.length : countA + countB;
      final busy = deleteMode
          ? controller.isProductDeleteBusy.value
          : controller.isLocationActionBusy.value;
      final pickingB = controller.pickingSwapGroupB.value;

      return Material(
        elevation: 8,
        color: AppColors.whiteColor,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pickingB && !deleteMode)
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  color: AppColors.customOrange3.withValues(alpha: 0.12),
                  child: Text(
                    'swapPickGroupB'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.customOrange3,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 8.h),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: busy
                          ? null
                          : deleteMode
                              ? controller.exitDeleteSelection
                              : controller.exitLocationSelection,
                      icon: const Icon(Icons.close),
                      tooltip: 'cancelSelection'.tr,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'productsSelectedCount'.tr.replaceAll(
                                  '@count',
                                  total.toString(),
                                ),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.operationalNavy,
                            ),
                          ),
                          if (deleteMode) ...[
                            SizedBox(height: 2.h),
                            Text(
                              'deleteSelectionHint'.tr,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.customGreyColor5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else ...[
                            SizedBox(height: 2.h),
                            Text(
                              '${'swapGroupA'.tr}: $countA  •  ${'swapGroupB'.tr}: $countB',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.customGreyColor5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (busy)
                      SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (deleteMode) ...[
                      TextButton.icon(
                        onPressed: total == 0
                            ? null
                            : () => controller.confirmDeleteSelectedProducts(
                                  context,
                                ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(
                          'deleteSelectedProducts'.tr,
                          style: TextStyle(fontSize: 11.sp),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ] else ...[
                      if (!pickingB && countA > 0)
                        TextButton(
                          onPressed: controller.startSwapGroupBPicking,
                          child: Text(
                            'swapGroupB'.tr,
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: total == 0
                            ? null
                            : () => controller.openMoveSelectedDialog(context),
                        icon:
                            const Icon(Icons.drive_file_move_outline, size: 16),
                        label: Text(
                          'moveProductLocation'.tr,
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: !controller.canExecuteSwap
                            ? null
                            : () => controller.executeSwapSelectedProducts(
                                  context: context,
                                ),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: Text(
                          'swapProductLocation'.tr,
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
