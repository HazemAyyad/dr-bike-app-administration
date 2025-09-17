import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_section_controller.dart';

class CreateQrcode extends GetView<EmployeeSectionController> {
  const CreateQrcode({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20.h),
          Text(
            'addBarCode'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Get.isDarkMode
                      ? AppColors.primaryColor
                      : AppColors.secondaryColor,
                ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Obx(
              () => controller.isDialogLoading.value
                  ? SizedBox(
                      height: 200.h,
                      child: const Center(child: CircularProgressIndicator()))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(5.r),
                      child: Center(
                        child: RepaintBoundary(
                          key: controller.qrKey,
                          child: QrImageView(
                            data:
                                controller.employeeService.qrGeneration.value !=
                                        null
                                    ? controller.employeeService.qrGeneration
                                        .value!.codeText
                                    : '446fasfasga4846',
                            version: QrVersions.auto,
                            size: 200.sp,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          IconButton(
            onPressed: () => controller.downloadQr(),
            icon: Icon(
              Icons.file_download_outlined,
              size: 30.sp,
              color: AppColors.primaryColor,
            ),
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   crossAxisAlignment: CrossAxisAlignment.center,
          //   children: [
          //     IconButton(
          //       onPressed: () => ,
          //       icon: const Icon(
          //         Icons.refresh,
          //         color: AppColors.primaryColor,
          //       ),
          //     ),
          //     IconButton(
          //       onPressed: () => controller.downloadQr(),
          //       icon: const Icon(
          //         Icons.file_download_outlined,
          //         color: AppColors.primaryColor,
          //       ),
          //     ),
          //   ],
          // ),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: AppButton(
              text: 'createBarNewCode',
              onPressed: () => controller.generateQrCode(true),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}
