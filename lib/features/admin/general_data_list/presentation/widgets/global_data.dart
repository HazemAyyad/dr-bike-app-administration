import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:doctorbike/features/admin/general_data_list/data/models/employee_data_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
        // overlayColor: WidgetStateProperty.all(Colors.transparent),
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
                  ? AppColors.darckColor
                  : AppColors.whiteColor,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () {
                      launchDialer(employee.phone);
                    },
                    child: Row(
                      children: [
                        SizedBox(width: 5.h),
                        Icon(
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
                          AssetsManger.whatsapp,
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
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5.r),
                child: Image.asset(
                  AssetsManger.generalDataImage,
                  height: 70.h,
                  width: 70.w,
                ),
              ),
              SizedBox(width: 20.w),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.customGreyColor5,
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
