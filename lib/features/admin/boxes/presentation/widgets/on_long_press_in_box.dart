import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/get_shown_boxes_model.dart';
import '../controllers/boxes_controller.dart';
import 'add_balance_widget.dart';
import 'transfer_balance_widget.dart';

class OnLongPressInBox extends GetView<BoxesController> {
  const OnLongPressInBox({Key? key, required this.box}) : super(key: key);

  final GetShownBoxesModel box;
  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Dialog(
      backgroundColor:
          ThemeService.isDark.value ? AppColors.darkColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(5.r),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.dialog(AddBalanceWidget(boxId: box.boxId));
                  },
                  label: Text(
                    'addBalance'.tr,
                    style: textStyle.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: Icon(
                    Icons.add,
                    size: 25.h,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 10.h),
                TextButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.dialog(TransferBalanceWidget(boxId: box.boxId));
                  },
                  label: Text(
                    'transferBalance'.tr,
                    style: textStyle.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: Icon(
                    Icons.swap_horiz,
                    size: 25.h,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
