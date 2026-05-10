import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../domain/entities/employee_entity.dart';
import '../../controllers/employee_section_controller.dart';

class EmployeeList extends GetView<EmployeeSectionController> {
  const EmployeeList({Key? key, required this.employee}) : super(key: key);

  final EmployeeEntity employee;

  String _getStatusText() {
    if (!employee.hasAttendedToday) {
      return 'معطل لحد الان';
    } else if (employee.isWorkingNow) {
      return 'شغال حاليا';
    } else {
      return 'غادر العمل';
    }
  }

  Color _getStatusColor() {
    if (!employee.hasAttendedToday) {
      return Colors.grey;
    } else if (employee.isWorkingNow) {
      return Colors.green;
    } else {
      return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              controller.getEmployeeDetails(employee.id.toString());
              Get.toNamed(
                AppRoutes.EMPLOYEEDETAILSSCREEN,
                arguments: employee.points,
              );
            },
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
                          transitionDuration:
                              const Duration(milliseconds: 300),
                          pageBuilder: (context, anim1, anim2) {
                            return FullScreenZoomImage(
                              imageUrl: employee.employeeImg,
                            );
                          },
                        );
                      },
                      child: Container(
                        height: 80.h,
                        width: 80.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              employee.employeeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.customGreyColor5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4.h),
                      Text(
                        '${'hourlyRate'.tr} : ${employee.hourWorkPrice} ${'currency'.tr}',
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
        ),
        Container(
          width: 70.w,
          height: 85.h,
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          decoration: BoxDecoration(
          color: AppColors.customGreen1,
            borderRadius: BorderRadiusDirectional.only(
              topEnd: Radius.circular(4.r),
              bottomEnd: Radius.circular(4.r),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${employee.points} ${'point'.tr}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
