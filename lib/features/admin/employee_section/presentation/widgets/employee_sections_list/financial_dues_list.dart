import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/financial_dues_model.dart';
import '../../controllers/employee_section_controller.dart';
import '../employee_advances_bottom_sheet.dart';
import '../employee_financial_details.dart';

class FinancialDuesList extends GetView<EmployeeSectionController> {
  const FinancialDuesList({Key? key, required this.employee}) : super(key: key);

  final FinancialDuesModel employee;

  void _openFinancialDetails(BuildContext context) {
    controller.openFinancialDetails(employee.id.toString());
    Get.dialog(
      Obx(
        () => controller.financialDetailsList.value != null
            ? controller.isDialogLoading.value
                ? const Center(child: CircularProgressIndicator())
                : EmployeeFinancialDetails(controller: controller)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _openAdvances(BuildContext context) {
    showEmployeeAdvancesBottomSheet(
      context,
      controller: controller,
      employeeId: employee.id,
      employeeName: employee.employeeName,
    );
  }

  void _openImageViewer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withAlpha(128),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return FullScreenZoomImage(imageUrl: employee.employeeImg);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;

    // ارتفاع الصف يتسع لصورة دائرية 80 مثل تبويب قائمة الموظفين
    const rowHeight = 90.0;
    return SizedBox(
      height: rowHeight.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _openFinancialDetails(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: GestureDetector(
                      onTap: () => _openImageViewer(context),
                      child: Container(
                        height: 80.h,
                        width: 80.w,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(
                          cacheManager: CacheManager(
                            Config(
                              'imagesCache',
                              stalePeriod: const Duration(days: 7),
                              maxNrOfCacheObjects: 100,
                            ),
                          ),
                          imageUrl: employee.employeeImg,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.employeeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          '${'salary'.tr} : ${employee.salary} ${'currency'.tr}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '${'debt'.tr} : ${employee.debts}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: 48.w,
              minHeight: rowHeight.h,
            ),
            onPressed: () => _openAdvances(context),
            icon: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primaryColor,
              size: 26.sp,
            ),
            tooltip: 'advances'.tr,
          ),
          Container(
            width: 72.w,
            constraints: BoxConstraints(minHeight: rowHeight.h),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.customGreen1,
              borderRadius: BorderRadiusDirectional.only(
                topEnd: Radius.circular(4.r),
                bottomEnd: Radius.circular(4.r),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${(double.parse(employee.salary) - double.parse(employee.debts)).toString()} ${'currency'.tr}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
