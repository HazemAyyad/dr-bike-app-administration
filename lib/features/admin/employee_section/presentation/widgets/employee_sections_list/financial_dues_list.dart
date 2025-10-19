import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/financial_dues_model.dart';
import '../../controllers/employee_section_controller.dart';
import '../employee_financial_details.dart';

class FinancialDuesList extends GetView<EmployeeSectionController> {
  const FinancialDuesList({Key? key, required this.employee}) : super(key: key);

  final FinancialDuesModel employee;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;

    return InkWell(
      onTap: () {
        controller.getFinancialDetails(employee.id.toString());
        Get.dialog(
          Obx(
            () => controller.financialDetailsList.value != null
                ? controller.isDialogLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : EmployeeFinancialDetails(controller: controller)
                : const Center(child: CircularProgressIndicator()),
          ),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.r),
                    child: CachedNetworkImage(
                      cacheManager: CacheManager(
                        Config(
                          'imagesCache',
                          stalePeriod: const Duration(days: 7),
                          maxNrOfCacheObjects: 100,
                        ),
                      ),
                      imageBuilder: (context, imageProvider) => Container(
                        height: 65.h,
                        width: 65.w,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                      imageUrl: employee.employeeImg,
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
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
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
                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child:
                      //     ),
                      //     SizedBox(width: 10.w),
                      //     Expanded(
                      //       child:
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60.w,
            height: 75.h,
            padding: EdgeInsets.symmetric(horizontal: 1.w),
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
                    fontSize: 14.sp,
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
