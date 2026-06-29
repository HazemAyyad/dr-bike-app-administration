import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/overtime_and_loan_model.dart';
import '../../controllers/employee_section_controller.dart';
import '../../utils/overtime_duration_format.dart';
import '../requests_details.dart';

class LoansList extends GetView<EmployeeSectionController> {
  const LoansList({
    Key? key,
    required this.employee,
    required this.isOvertime,
  }) : super(key: key);

  final OvertimeAndLoanModel employee;
  final bool isOvertime;
  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return InkWell(
      onTap: () => isOvertime
          ? Get.dialog(
              RequestsDetails(
                employee: employee,
                controller: controller,
                isOvertime: true,
              ),
            )
          : Get.dialog(
              RequestsDetails(employee: employee, controller: controller),
            ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
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
                              imageUrl: employee.employeeImg,
                            );
                          },
                        );
                      },
                      child: Container(
                        height: 44.w,
                        width: 44.w,
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
                ),
                SizedBox(width: 8.w),
                Flexible(
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
                      SizedBox(height: 2.h),
                      isOvertime
                          ? Text(
                              '${'overtimeValue'.tr}: ${formatOvertimeDecimalHours(
                                employee.overtimeValue!.isEmpty
                                    ? employee.extraWorkHoursValue
                                    : employee.overtimeValue,
                              )}',
                              style: textStyle.copyWith(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.withValues(alpha: 0.7),
                              ),
                            )
                          : Text(
                              '${'debtValue'.tr} : ${employee.loanValue} ${'currency'.tr}',
                              style: textStyle.copyWith(
                                fontSize: 12.sp,
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
          Container(
            margin: EdgeInsetsDirectional.only(end: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: employee.orderStatus == 'approved'
                  ? AppColors.customGreen1
                  : employee.orderStatus == 'pending'
                      ? AppColors.customOrange
                      : AppColors.redColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                employee.orderStatus.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
