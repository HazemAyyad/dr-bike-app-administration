import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../admin_dashbord/presentation/widgets/stat_card.dart';
import '../controllers/checks_controller.dart';
import 'totals_currency_dialog.dart';

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
                      value: isOutGoing
                          ? controller.generalOutgoing.value == null
                              ? '0'
                              : controller
                                  .generalOutgoing.value!.outgoingChecksCount
                                  .toString()
                          : controller.generalIncoming.value == null
                              ? '0'
                              : controller
                                  .generalIncoming.value!.incomingChecksCount
                                  .toString(),
                      subtitle: '',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.dialog(const TotalsCurrencyDialog()),
                      child: StatCard(
                        show: true,
                        title: 'total',
                        imageicon: AssetsManager.cashIcon,
                        value: isOutGoing
                            ? controller.generalOutgoing.value == null
                                ? '0.0'
                                : NumberFormat('#,###').format(
                                    double.tryParse(
                                          controller.generalOutgoing.value!
                                              .totalOutgoingChecks
                                              .toString(),
                                        ) ??
                                        0.0,
                                  )
                            : controller.generalIncoming.value == null
                                ? '0.0'
                                : NumberFormat('#,###').format(
                                    double.tryParse(
                                          controller.generalIncoming.value!
                                              .totalIncomingChecks
                                              .toString(),
                                        ) ??
                                        0.0,
                                  ),
                        subtitle: '',
                      ),
                    ),
                  ),
                ],
              ),
              isOutGoing
                  ? Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            show: true,
                            title: 'totalFunds',
                            imageicon: AssetsManager.moneyIcon,
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
