import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:doctorbike/features/admin/general_data_list/data/models/employee_data_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/open_apps.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/general_data_list_controller.dart';

class GlobalData extends GetView<GeneralDataListController> {
  const GlobalData({Key? key, required this.employee}) : super(key: key);

  final GeneralDataModel employee;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: GestureDetector(
        onTap: () {
          controller.clearForm();
          controller.isEdit.value = true;
          controller.getPersonData(
            customerId: controller.currentTab.value == 1
                ? employee.id.toString()
                : employee.type == 'customer'
                    ? employee.id.toString()
                    : '',
            sellerId: controller.currentTab.value == 0
                ? employee.id.toString()
                : employee.type == 'seller'
                    ? employee.id.toString()
                    : '',
          );
          Get.toNamed(
            AppRoutes.ADDNEWCUSTOMERSCREEN,
            arguments: {
              'employeeType': employee.type,
              'employeeId': employee.id.toString(),
              'sellerId': employee.id.toString(),
            },
          );
        },
        onLongPress: () {
          Get.dialog(
            AlertDialog(
              backgroundColor: ThemeService.isDark.value
                  ? AppColors.darkColor
                  : AppColors.whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      launchDialer(phoneNumber: employee.phone);
                    },
                    child: Row(
                      children: [
                        SizedBox(width: 5.h),
                        const Icon(
                          Icons.phone_outlined,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'directContact'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blackColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () {
                      launchWhatsApp(phoneNumber: employee.phone);
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          AssetsManager.whatsapp,
                          height: 30.h,
                          width: 30.w,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'directContact'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blackColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  InkWell(
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    onTap: () {
                      Get.back();
                      Get.dialog(
                        Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          backgroundColor: ThemeService.isDark.value
                              ? AppColors.darkColor
                              : AppColors.whiteColor,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'areYouSure'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: Colors.red,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  SizedBox(height: 20.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppButton(
                                          isSafeArea: false,
                                          text: 'cancel'.tr,
                                          color: Colors.red,
                                          onPressed: () => Get.back(),
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: AppButton(
                                            isSafeArea: false,
                                            text: 'delete'.tr,
                                            color: Colors.transparent,
                                            textColor: Colors.red,
                                            borderColor: Colors.red,
                                            onPressed: () {
                                              controller.deletePerson(
                                                customerId: controller
                                                            .currentTab.value ==
                                                        1
                                                    ? employee.id.toString()
                                                    : employee.type ==
                                                            'customer'
                                                        ? employee.id.toString()
                                                        : '',
                                                sellerId: controller
                                                            .currentTab.value ==
                                                        0
                                                    ? employee.id.toString()
                                                    : employee.type == 'seller'
                                                        ? employee.id.toString()
                                                        : '',
                                              );
                                              Get.back();
                                            }),
                                      ),
                                    ],
                                  )
                                ]),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        SizedBox(width: 5.h),
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'delete'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor4
                : AppColors.whiteColor2,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(32),
                blurRadius: 5.r,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5.r),
                child: GestureDetector(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Dismiss',
                      barrierColor: Colors.black.withAlpha(128),
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) {
                        return FullScreenZoomImage(
                          imageUrl: employee.idImage!,
                        );
                      },
                    );
                  },
                  child: CachedNetworkImage(
                    cacheManager: CacheManager(
                      Config(
                        'imagesCache',
                        stalePeriod: const Duration(days: 7),
                        maxNrOfCacheObjects: 100,
                      ),
                    ),
                    imageBuilder: (context, imageProvider) => Container(
                      height: 70.h,
                      width: 70.w,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                    imageUrl: employee.idImage!,
                    filterQuality: FilterQuality.medium,
                    fadeInDuration: const Duration(milliseconds: 200),
                    fadeOutDuration: const Duration(milliseconds: 200),
                    placeholder: (context, url) => SizedBox(
                      height: 70.h,
                      width: 70.w,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
              // SizedBox(width: 20.w),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: 100.w,
                          child: Text(
                            employee.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.customGreyColor5,
                                ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          employee.jobTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.customGreyColor5,
                                  ),
                        ),
                      ],
                    ),
                    Text(
                      employee.phone,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.customGreyColor5,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
