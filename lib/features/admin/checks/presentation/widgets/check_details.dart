import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../employee_tasks/presentation/views/task_details_screen.dart';
import '../../data/models/check_model.dart';
import '../controllers/checks_controller.dart';

class CheckDetails extends GetView<ChecksController> {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox.shrink(),
                const SizedBox.shrink(),
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
                IconButton(
                  icon: const Icon(
                    Icons.edit_document,
                    color: AppColors.primaryColor,
                    size: 30,
                  ),
                  onPressed: () {
                    controller.isEdit.value = true;
                    controller.getCeckData(check: check, isOutgoing: type);
                  },
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
                                      imageUrl: check.frontImage ?? '',
                                    );
                                  },
                                );
                              },
                              child: CachedNetworkImage(
                                imageUrl: check.frontImage ?? '',
                                fit: BoxFit.fill,
                                height: 100.h,
                                width: 110.w,
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
                                      imageUrl: check.backImage ?? '',
                                    );
                                  },
                                );
                              },
                              child: CachedNetworkImage(
                                imageUrl: check.backImage ?? '',
                                fit: BoxFit.fill,
                                height: 100.h,
                                width: 110.w,
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
            if (check.notes != null && check.notes!.isNotEmpty)
              SupTextAndDiscr(
                titleColor: AppColors.primaryColor,
                title: 'notes',
                discription: check.notes ?? '',
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
