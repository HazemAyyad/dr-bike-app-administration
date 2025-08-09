import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';

class WorkHoursList extends StatelessWidget {
  const WorkHoursList({Key? key, required this.employee}) : super(key: key);
  final Map<String, dynamic> employee;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5.r),
                  child: CachedNetworkImage(
                    imageUrl: employee['image'],
                    height: 65.h,
                    width: 65.w,
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
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee['employeeName'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${'workStartTime'.tr} : ${employee['workStartTime']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle.copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            '${'workEndTime'.tr} : ${employee['workEndTime']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle.copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 50.w,
          height: 75.h,
          decoration: BoxDecoration(
            color: AppColors.customGreen1,
            borderRadius: BorderRadiusDirectional.only(
              topEnd: Radius.circular(4.r),
              bottomEnd: Radius.circular(4.r),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '${employee['workHoursOfDay']} ${'hours'.tr}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
        ),
      ],
    );
  }
}
