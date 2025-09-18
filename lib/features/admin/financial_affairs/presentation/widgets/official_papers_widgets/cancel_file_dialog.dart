import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/official_papers_controller.dart';

class CancelFileDialog extends GetView<OfficialPapersController> {
  const CancelFileDialog({
    Key? key,
    this.fileId,
    this.fileBoxId,
    this.treasuryId,
    required this.fileName,
  }) : super(key: key);

  final String? fileId;
  final String? fileBoxId;
  final String? treasuryId;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'clear'.tr} $fileName',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.whiteColor
                        : AppColors.secondaryColor,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: AppButton(
                    isSafeArea: false,
                    text: 'cancel'.tr,
                    onPressed: () {
                      Get.back();
                    },
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppButton(
                    isLoading: controller.isLoading,
                    isSafeArea: false,
                    color: Colors.red,
                    text: 'clear'.tr,
                    onPressed: () {
                      controller.deleteFiles(
                        fileId: fileId,
                        fileBoxId: fileBoxId,
                        treasuryId: treasuryId,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
