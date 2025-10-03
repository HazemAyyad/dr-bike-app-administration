import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../admin_dashbord/presentation/widgets/stat_card.dart';
import '../controllers/checks_controller.dart';

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
              controller.cashedToPerson.value == null ||
              controller.archiveData.value == null) {
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
                          ? controller.inComingChecksList.value?.checksCount ??
                              '0'
                          : controller.currentTab.value == 1
                              ? controller.cashedToPerson.value?.checksCount ??
                                  '0'
                              : controller.archiveData.value?.checksCount ??
                                  '0',
                      subtitle: '',
                    ),
                  ),
                ],
              ),
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
                        imageicon: AssetsManager.cashIcon,
                        value: NumberFormat('#,###').format(
                          double.parse(
                            controller.currentTab.value == 0
                                ? controller
                                    .inComingChecksList.value!.checksTotalShekel
                                : controller.currentTab.value == 1
                                    ? controller
                                        .cashedToPerson.value!.checksTotalShekel
                                    : controller
                                        .archiveData.value!.checksTotalShekel,
                          ),
                        ),
                        subtitle: '',
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'currency1',
                        imageicon: AssetsManager.cashIcon,
                        value: NumberFormat('#,###').format(
                          double.parse(
                            controller.currentTab.value == 0
                                ? controller
                                    .inComingChecksList.value!.checksTotalDollar
                                : controller.currentTab.value == 1
                                    ? controller
                                        .cashedToPerson.value!.checksTotalDollar
                                    : controller
                                        .archiveData.value!.checksTotalDollar,
                          ),
                        ),
                        subtitle: '',
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        show: true,
                        title: 'currency2',
                        imageicon: AssetsManager.cashIcon,
                        value: NumberFormat('#,###').format(
                          double.parse(
                            controller.currentTab.value == 0
                                ? controller
                                    .inComingChecksList.value!.checksTotalDinar
                                : controller.currentTab.value == 1
                                    ? controller
                                        .cashedToPerson.value!.checksTotalDinar
                                    : controller
                                        .archiveData.value!.checksTotalDinar,
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
                            title: 'currency',
                            imageicon: AssetsManager.cashIcon,
                            value: NumberFormat('#,###').format(
                              double.parse(
                                controller.currentTab.value == 0
                                    ? controller.inComingChecksList.value!
                                        .checksTotalShekel
                                    : controller.currentTab.value == 1
                                        ? controller.cashedToPerson.value!
                                            .checksTotalShekel
                                        : controller.archiveData.value!
                                            .checksTotalShekel,
                              ),
                            ),
                            subtitle: '',
                          ),
                          StatCard(
                            show: true,
                            title: 'currency1',
                            imageicon: AssetsManager.cashIcon,
                            value: NumberFormat('#,###').format(
                              double.parse(
                                controller.currentTab.value == 0
                                    ? controller.inComingChecksList.value!
                                        .checksTotalDollar
                                    : controller.currentTab.value == 1
                                        ? controller.cashedToPerson.value!
                                            .checksTotalDollar
                                        : controller.archiveData.value!
                                            .checksTotalDollar,
                              ),
                            ),
                            subtitle: '',
                          ),
                          StatCard(
                            show: true,
                            title: 'currency2',
                            imageicon: AssetsManager.cashIcon,
                            value: NumberFormat('#,###').format(
                              double.parse(
                                controller.currentTab.value == 0
                                    ? controller.inComingChecksList.value!
                                        .checksTotalDinar
                                    : controller.currentTab.value == 1
                                        ? controller.cashedToPerson.value!
                                            .checksTotalDinar
                                        : controller.archiveData.value!
                                            .checksTotalDinar,
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
                          controller.currentTab.value == 0
                              ? controller.inComingChecksList.value
                                      ?.coverPercentage?.length ??
                                  0
                              : controller.currentTab.value == 1
                                  ? controller.cashedToPerson.value
                                          ?.coverPercentage?.length ??
                                      0
                                  : controller.archiveData.value
                                          ?.coverPercentage?.length ??
                                      0,
                          (index) {
                            final coverPercentage =
                                controller.currentTab.value == 0
                                    ? (controller.inComingChecksList.value
                                            ?.coverPercentage?.values
                                            .toList()[index] ??
                                        0)
                                    : controller.currentTab.value == 1
                                        ? (controller.cashedToPerson.value
                                                ?.coverPercentage?.values
                                                .toList()[index] ??
                                            0)
                                        : (controller.archiveData.value
                                                ?.coverPercentage?.values
                                                .toList()[index] ??
                                            0);

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
                            title: 'currency',
                            imageicon: AssetsManager.cashIcon,
                            value: NumberFormat('#,###').format(
                              double.tryParse(
                                    controller.currentTab.value == 0
                                        ? controller.inComingChecksList.value
                                                ?.boxesTotalShekel ??
                                            '0.0'
                                        : controller.currentTab.value == 1
                                            ? controller.cashedToPerson.value
                                                    ?.boxesTotalShekel ??
                                                '0.0'
                                            : controller.archiveData.value
                                                    ?.boxesTotalShekel ??
                                                '0.0',
                                  ) ??
                                  0.0,
                            ),
                            subtitle: '',
                          ),
                          StatCard(
                            show: true,
                            title: 'currency1',
                            imageicon: AssetsManager.cashIcon,
                            value: NumberFormat('#,###').format(
                              double.tryParse(
                                    controller.currentTab.value == 0
                                        ? controller.inComingChecksList.value
                                                ?.boxesTotalDollar ??
                                            '0.0'
                                        : controller.currentTab.value == 1
                                            ? controller.cashedToPerson.value
                                                    ?.boxesTotalDollar ??
                                                '0.0'
                                            : controller.archiveData.value
                                                    ?.boxesTotalDollar ??
                                                '0.0',
                                  ) ??
                                  0.0,
                            ),
                            subtitle: '',
                          ),
                          StatCard(
                            show: true,
                            title: 'currency2',
                            imageicon: AssetsManager.cashIcon,
                            value: NumberFormat('#,###').format(
                              double.tryParse(
                                    controller.currentTab.value == 0
                                        ? controller.inComingChecksList.value
                                                ?.boxesTotalDinar ??
                                            '0.0'
                                        : controller.currentTab.value == 1
                                            ? controller.cashedToPerson.value
                                                    ?.boxesTotalDinar ??
                                                '0.0'
                                            : controller.archiveData.value
                                                    ?.boxesTotalDinar ??
                                                '0.0',
                                  ) ??
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
