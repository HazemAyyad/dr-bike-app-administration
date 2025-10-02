import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/user_transactions_data_model.dart';

class UserTransactionsWidget extends StatelessWidget {
  const UserTransactionsWidget({
    Key? key,
    required this.debt,
    required this.index,
  }) : super(key: key);

  final int index;
  final Debt debt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: index == 0 ? 5.h : 0.h),
        Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.customGreyColor6.withAlpha(100),
                radius: 25.r,
                child: SizedBox(
                  height: 30.h,
                  child: Icon(
                    debt.debtType == 'we owe'
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 30.h,
                    color:
                        debt.debtType == 'we owe' ? Colors.green : Colors.red,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(debt.dueDate),
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeService.isDark.value
                                        ? Colors.white
                                        : AppColors.secondaryColor,
                                  ),
                        ),
                        Text(
                          '${NumberFormat("#,###").format(double.parse(debt.total))} ${'currency'.tr}',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    decoration: TextDecoration.none,
                                    decorationColor: debt.debtType == 'we owe'
                                        ? Colors.green
                                        : Colors.red,
                                    decorationThickness: 1.5,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: debt.debtType == 'we owe'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            debt.notes!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.customGreyColor2,
                                ),
                          ),
                        ),
                        Text(
                          debt.debtType == 'we owe' ? 'took'.tr : 'gave'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.customGreyColor2,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    GestureDetector(
                      onTap: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: 'Dismiss',
                          barrierColor: Colors.black.withAlpha(128),
                          transitionDuration: const Duration(milliseconds: 300),
                          pageBuilder: (context, anim1, anim2) {
                            return FullScreenZoomImage(
                              imageUrl: debt.receiptImage,
                            );
                          },
                        );
                      },
                      child: CachedNetworkImage(
                        imageUrl: debt.receiptImage,
                        fit: BoxFit.cover,
                        height: 80.h,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryColor),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error,
                          size: 50,
                          color: Colors.red,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
