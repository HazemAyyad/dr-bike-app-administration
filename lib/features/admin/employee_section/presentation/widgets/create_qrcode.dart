import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_section_controller.dart';
import '../../../../../routes/app_routes.dart';

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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Get.toNamed(AppRoutes.QRHISTORYSCREEN),
                  icon: Icon(
                    Icons.history,
                    size: 26.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'addBarCode'.tr,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: Get.isDarkMode
                                ? AppColors.primaryColor
                                : AppColors.secondaryColor,
                          ),
                    ),
                  ),
                ),
                SizedBox(width: 48.w), // keep title centered
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Obx(
              () {
                if (controller.isDialogLoading.value) {
                  return SizedBox(
                    height: 200.h,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                final gen = controller.employeeService.qrGeneration.value;
                final createdAt = gen?.createdAt;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(5.r),
                  child: Center(
                    child: RepaintBoundary(
                      key: controller.qrKey,
                      child: ColoredBox(
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.all(8.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              QrImageView(
                                data: gen?.codeText ?? '446fasfasga4846',
                                version: QrVersions.auto,
                                size: 200.sp,
                                backgroundColor: Colors.white,
                              ),
                              if (createdAt != null) ...[
                                SizedBox(height: 10.h),
                                Text(
                                  '${'qrCreatedAt'.tr}: ${DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toLocal())}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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
