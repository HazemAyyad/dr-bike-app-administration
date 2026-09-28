import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../admin_dashbord/presentation/widgets/stat_card.dart';
import '../controllers/checks_controller.dart';
import '../controllers/checks_serves.dart';

class ChecksDataDetails extends StatelessWidget {
  const ChecksDataDetails({Key? key, this.isOutGoing = false})
      : super(key: key);

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
          if (controller.isLoading.value ||
              controller.inComingChecksList.value == null ||
              (!controller.isInComing &&
                  controller.partiallyPaidData.value == null) ||
              controller.cashedToPerson.value == null ||
              controller.archiveData.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              if (isOutGoing)
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'count',
                        icon: Icons.receipt_long_outlined,
                        value: controller.activeFilteredCount,
                        subtitle: '',
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'scheduledChecks',
                        icon: Icons.event_repeat_rounded,
                        value: ChecksServes()
                                .generalChecksData
                                .value
                                ?.scheduledOutgoingChecksCount
                                .toString() ??
                            '0',
                        subtitle: '',
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'partiallyPaidChecks',
                        icon: Icons.pie_chart_outline_rounded,
                        value: ChecksServes()
                                .generalChecksData
                                .value
                                ?.partiallyPaidOutgoingChecksCount
                                .toString() ??
                            '0',
                        subtitle: '',
                      ),
                    ),
                  ],
                ),
              if (!isOutGoing)
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'numberOfChecks',
                        icon: Icons.receipt_long_outlined,
                        value: controller.activeFilteredCount,
                        subtitle: '',
                      ),
                    ),
                  ],
                ),
              if (isOutGoing) ...[
                Text(
                  'paidOutgoingChecks'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: ThemeService.isDark.value
                            ? Colors.white
                            : AppColors.secondaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'count',
                        icon: Icons.task_alt_rounded,
                        value: ChecksServes()
                                .generalChecksData
                                .value
                                ?.paidOutgoingChecksCount
                                .toString() ??
                            '0',
                        subtitle: '',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'currency',
                        icon: Icons.payments_outlined,
                        value: NumberFormat('#,###').format(double.tryParse(
                                ChecksServes()
                                        .generalChecksData
                                        .value
                                        ?.paidOutgoingChecksShekel ??
                                    '0') ??
                            0),
                        subtitle: '',
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'currency1',
                        icon: Icons.attach_money_rounded,
                        value: NumberFormat('#,###').format(double.tryParse(
                                ChecksServes()
                                        .generalChecksData
                                        .value
                                        ?.paidOutgoingChecksDollar ??
                                    '0') ??
                            0),
                        subtitle: '',
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'currency2',
                        icon: Icons.account_balance_outlined,
                        value: NumberFormat('#,###').format(double.tryParse(
                                ChecksServes()
                                        .generalChecksData
                                        .value
                                        ?.paidOutgoingChecksDinar ??
                                    '0') ??
                            0),
                        subtitle: '',
                      ),
                    ),
                  ],
                ),
              ],
              if (controller.isInComing)
                Text(
                  'total'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: ThemeService.isDark.value
                            ? Colors.white
                            : AppColors.secondaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              if (controller.isInComing)
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'currency',
                        icon: Icons.payments_outlined,
                        value: NumberFormat('#,###').format(
                          double.parse(
                            controller.activeFilteredTotalShekel,
                          ),
                        ),
                        subtitle: '',
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'currency1',
                        icon: Icons.attach_money_rounded,
                        value: NumberFormat('#,###').format(
                          double.parse(
                            controller.activeFilteredTotalDollar,
                          ),
                        ),
                        subtitle: '',
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'currency2',
                        icon: Icons.account_balance_outlined,
                        value: NumberFormat('#,###').format(
                          double.parse(
                            controller.activeFilteredTotalDinar,
                          ),
                        ),
                        subtitle: '',
                      ),
                    ),
                  ],
                ),
              Row(
                children: [
                  if (!controller.isInComing)
                    Flexible(
                      child: Column(
                        children: [
                          Text(
                            'total'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: ThemeService.isDark.value
                                      ? Colors.white
                                      : AppColors.secondaryColor,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          StatCard(
                            show: true,
                            title: 'currency1',
                            icon: Icons.attach_money_rounded,
                            value: NumberFormat('#,###').format(
                              double.parse(
                                controller.activeFilteredTotalDollar,
                              ),
                            ),
                            subtitle: '',
                          ),
                          StatCard(
                            show: true,
                            title: 'currency2',
                            icon: Icons.account_balance_outlined,
                            value: NumberFormat('#,###').format(
                              double.parse(
                                controller.activeFilteredTotalDinar,
                              ),
                            ),
                            subtitle: '',
                          ),
                          StatCard(
                            show: true,
                            title: 'currency',
                            icon: Icons.payments_outlined,
                            value: NumberFormat('#,###').format(
                              double.parse(
                                controller.activeFilteredTotalShekel,
                              ),
                            ),
                            subtitle: '',
                          ),
                        ],
                      ),
                    ),
                  if (isOutGoing)
                    Column(
                      children: [
                        Text(
                          'coveragePercentage'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: ThemeService.isDark.value
                                        ? Colors.white
                                        : AppColors.secondaryColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        ...List.generate(
                          controller
                                  .activeChecksData?.coverPercentage?.length ??
                              0,
                          (index) {
                            final coverPercentage = controller
                                    .activeChecksData?.coverPercentage?.values
                                    .toList()[index] ??
                                0;

                            return Container(
                              margin: EdgeInsets.all(5.r),
                              padding: EdgeInsets.all(5.r),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: CircularProgressIndicator(
                                      value: (coverPercentage ?? 0) / 100,
                                      strokeWidth: 4.w,
                                      backgroundColor: Colors.grey[500],
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${coverPercentage.toStringAsFixed(0)}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeService.isDark.value
                                              ? AppColors.whiteColor2
                                              : AppColors.blackColor,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  if (isOutGoing)
                    Flexible(
                      child: Column(
                        children: [
                          Text(
                            'boxes'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: ThemeService.isDark.value
                                      ? Colors.white
                                      : AppColors.secondaryColor,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          StatCard(
                            show: true,
                            title: 'currency1',
                            icon: Icons.attach_money_rounded,
                            value: NumberFormat('#,###').format(
                              double.tryParse(controller
                                          .activeChecksData?.boxesTotalDollar ??
                                      '0.0') ??
                                  0.0,
                            ),
                            subtitle: '',
                          ),
                          StatCard(
                            show: true,
                            title: 'currency2',
                            icon: Icons.account_balance_outlined,
                            value: NumberFormat('#,###').format(
                              double.tryParse(controller
                                          .activeChecksData?.boxesTotalDinar ??
                                      '0.0') ??
                                  0.0,
                            ),
                            subtitle: '',
                          ),
                          StatCard(
                            show: true,
                            title: 'currency',
                            icon: Icons.payments_outlined,
                            value: NumberFormat('#,###').format(
                              double.tryParse(controller
                                          .activeChecksData?.boxesTotalShekel ??
                                      '0.0') ??
                                  0.0,
                            ),
                            subtitle: '',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
