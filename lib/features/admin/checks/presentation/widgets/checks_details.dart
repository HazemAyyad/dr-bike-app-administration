import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../admin_dashbord/presentation/widgets/stat_card.dart';
import '../controllers/checks_controller.dart';

class ChecksDetails extends StatelessWidget {
  const ChecksDetails({Key? key, this.isOutGoing = false}) : super(key: key);

  final bool isOutGoing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9.r),
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
      ),
      child: GetBuilder<ChecksController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      show: true,
                      title: 'numberOfChecks',
                      imageicon: AssetsManager.cashIcon,
                      value: controller.currentTab.value == 0
                          ? controller.inComingChecksList.value!.checksCount
                              .toString()
                          : controller.currentTab.value == 1
                              ? controller.cashedToPerson.value!.checksCount
                                  .toString()
                              : controller.archiveData.value!.checksCount
                                  .toString(),
                      subtitle: '',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: StatCard(
                      show: true,
                      title: 'total',
                      imageicon: AssetsManager.cashIcon,
                      value: controller.currentTab.value == 0
                          ? NumberFormat('#,###').format(
                              double.tryParse(controller
                                      .inComingChecksList.value!.checksTotal
                                      .toString()) ??
                                  0.0,
                            )
                          : controller.currentTab.value == 1
                              ? NumberFormat('#,###').format(
                                  double.tryParse(controller
                                          .cashedToPerson.value!.checksTotal
                                          .toString()) ??
                                      0.0,
                                )
                              : NumberFormat('#,###').format(
                                  double.tryParse(controller
                                          .archiveData.value!.checksTotal
                                          .toString()) ??
                                      0.0,
                                ),
                      subtitle: '',
                    ),
                  ),
                ],
              ),
              Row(
                children: List.generate(
                  controller.currentTab.value == 0
                      ? controller.totalNotCashedByCurrency.entries.length
                      : controller.currentTab.value == 1
                          ? controller
                              .totalCashedToPersonByCurrency.entries.length
                          : controller.totalArchiveByCurrency.entries.length,
                  (index) {
                    final entry = controller.currentTab.value == 0
                        ? controller.totalNotCashedByCurrency.entries
                            .toList()[index]
                        : controller.currentTab.value == 1
                            ? controller.totalCashedToPersonByCurrency.entries
                                .toList()[index]
                            : controller.totalArchiveByCurrency.entries
                                .toList()[index];
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 5.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor4
                              : Colors.white,
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: 5.h, horizontal: 5.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  AssetsManager.moneyIcon,
                                  height: 20.h,
                                  width: 20.w,
                                  scale: 0.5,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  entry.key.tr,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: ThemeService.isDark.value
                                            ? Colors.white
                                            : AppColors.secondaryColor,
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              NumberFormat('#,###').format(entry.value),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              isOutGoing
                  ? Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            show: true,
                            title: 'totalFunds',
                            imageicon: AssetsManager.cashIcon,
                            value: NumberFormat('#,###').format(
                              double.parse(
                                controller.generalOutgoing.value?.totalBoxes
                                        .toString() ??
                                    '0',
                              ),
                            ),
                            subtitle: '',
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor4
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(5.r),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: 12.h,
                              horizontal: 15.w,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    'coveragePercentage'.tr,
                                    // overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: ThemeService.isDark.value
                                              ? Colors.white
                                              : AppColors.secondaryColor,
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      height: 35.h,
                                      width: 35.w,
                                      child: CircularProgressIndicator(
                                        value: (controller.generalOutgoing.value
                                                    ?.coveragePercentage ??
                                                0) /
                                            100,
                                        strokeWidth: 4.w,
                                        backgroundColor: Colors.grey[500],
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(controller.generalOutgoing.value?.coveragePercentage ?? 0).toStringAsFixed(0)}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700,
                                            color: ThemeService.isDark.value
                                                ? AppColors.whiteColor2
                                                : AppColors.blackColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ],
          );
        },
      ),
    );
  }
}
