import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../employee_tasks/presentation/views/task_details_screen.dart';
import '../../data/models/check_model.dart';

class CheckDetails extends StatelessWidget {
  const CheckDetails({
    Key? key,
    required this.check,
    required this.type,
  }) : super(key: key);

  final CheckModel check;
  final bool type;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 20.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'details'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: ThemeService.isDark.value
                            ? AppColors.whiteColor
                            : AppColors.secondaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 20.sp,
                      ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: SupTextAndDiscr(
                    titleColor: AppColors.primaryColor,
                    title: 'checkNumber',
                    discription: check.checkId,
                  ),
                ),
                Flexible(
                  child: SupTextAndDiscr(
                    titleColor: AppColors.primaryColor,
                    title: 'bankName',
                    discription: check.bankName,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (check.fromCustomer != null)
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'from',
                      discription: check.fromCustomer?.name ?? '',
                    ),
                  ),
                if (check.fromSeller != null)
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'from',
                      discription: check.fromSeller?.name ?? '',
                    ),
                  ),
                if (check.toCustomer != null)
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'to',
                      discription: check.toCustomer?.name ?? '',
                    ),
                  ),
                if (check.toSeller != null)
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'to',
                      discription: check.toSeller?.name ?? '',
                    ),
                  ),
              ],
            ),
            SupTextAndDiscr(
              titleColor: AppColors.primaryColor,
              title: 'due_date',
              discription: showData(check.dueDate),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (check.frontImage != null)
                  Flexible(
                    child: Column(
                      children: [
                        const SupTextAndDiscr(
                          titleColor: AppColors.primaryColor,
                          title: 'checkFrontImage',
                          discription: '',
                        ),
                        SizedBox(height: 5.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
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
                                      imageUrl: type
                                          ? '${EndPoints.baserUrlForImage}public/IncomingCheckImages/front/${check.frontImage}'
                                          : '${EndPoints.baserUrlForImage}public/OutgoingChecksImages/${check.frontImage}',
                                    );
                                  },
                                );
                              },
                              child: CachedNetworkImage(
                                imageUrl: type
                                    ? '${EndPoints.baserUrlForImage}public/IncomingCheckImages/front/${check.frontImage}'
                                    : '${EndPoints.baserUrlForImage}public/OutgoingChecksImages/${check.frontImage}',
                                fit: BoxFit.cover,
                                height: 150.h,
                                width: 150.w,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primaryColor),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                  Icons.error,
                                  size: 50,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (check.backImage != null)
                  Flexible(
                    child: Column(
                      children: [
                        const SupTextAndDiscr(
                          titleColor: AppColors.primaryColor,
                          title: 'checkBackImage',
                          discription: '',
                        ),
                        SizedBox(height: 5.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
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
                                      imageUrl:
                                          '${EndPoints.baserUrlForImage}public/IncomingCheckImages/back/${check.backImage}',
                                    );
                                  },
                                );
                              },
                              child: CachedNetworkImage(
                                imageUrl:
                                    '${EndPoints.baserUrlForImage}public/IncomingCheckImages/back/${check.backImage}',
                                fit: BoxFit.cover,
                                height: 150.h,
                                width: 150.w,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primaryColor),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                  Icons.error,
                                  size: 50,
                                  color: Colors.red,
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
            SupTextAndDiscr(
              titleColor: AppColors.primaryColor,
              title: 'total',
              discription:
                  "${NumberFormat('#,###').format(double.parse(check.total))} ${check.currency}",
            ),
          ],
        ),
      ),
    );
  }
}
