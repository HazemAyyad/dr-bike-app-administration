import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../admin_dashbord/presentation/widgets/stat_card.dart';
import '../controllers/checks_controller.dart';
import '../controllers/checks_serves.dart';

class ChecksInformaiton extends StatelessWidget {
  const ChecksInformaiton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9.r),
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
      ),
      child: GetBuilder<ChecksController>(
        builder: (controller) {
          return Column(
            children: [
              Text(
                'outgoingChecks'.tr,
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
                      title: 'didNotActOnIt',
                      imageicon: AssetsManager.cashIcon,
                      value: ChecksServes()
                              .generalChecksData
                              .value
                              ?.notCashedOutgoingChecksCount
                              .toString() ??
                          '0',
                      subtitle: '',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: StatCard(
                      title: 'actedOnIt',
                      imageicon: AssetsManager.cashIcon,
                      value: ChecksServes()
                              .generalChecksData
                              .value
                              ?.cashedOutgoingChecksCount
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
                      imageicon: AssetsManager.cashIcon,
                      value: NumberFormat('#,###').format(
                        double.parse(
                          ChecksServes()
                                  .generalChecksData
                                  .value
                                  ?.totalOutgoingChecksShekel
                                  .toString() ??
                              '0.0',
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
                          ChecksServes()
                                  .generalChecksData
                                  .value
                                  ?.totalOutgoingChecksDollar
                                  .toString() ??
                              '0.0',
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
                          ChecksServes()
                                  .generalChecksData
                                  .value
                                  ?.totalOutgoingChecksDinar
                                  .toString() ??
                              '0.0',
                        ),
                      ),
                      subtitle: '',
                    ),
                  ),
                ],
              ),
              Text(
                'incomingChecks'.tr,
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
                      title: 'didNotActOnIt',
                      imageicon: AssetsManager.moneyIcon,
                      value: NumberFormat('#,###').format(
                        double.parse(
                          ChecksServes()
                                  .generalChecksData
                                  .value
                                  ?.notCashedIncomingChecksCount
                                  .toString() ??
                              '0',
                        ),
                      ),
                      subtitle: '',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: StatCard(
                      show: true,
                      title: 'actedOnIt',
                      imageicon: AssetsManager.moneyIcon,
                      value: NumberFormat('#,###').format(
                        double.parse(
                          ChecksServes()
                                  .generalChecksData
                                  .value
                                  ?.cashedIncomingChecksCount
                                  .toString() ??
                              '0',
                        ),
                      ),
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
                      imageicon: AssetsManager.cashIcon,
                      value: NumberFormat('#,###').format(
                        double.parse(
                          ChecksServes()
                                  .generalChecksData
                                  .value
                                  ?.totalIncomingChecksShekel
                                  .toString() ??
                              '0.0',
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
                          ChecksServes()
                                  .generalChecksData
                                  .value
                                  ?.totalIncomingChecksDollar
                                  .toString() ??
                              '0.0',
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
                          ChecksServes()
                                  .generalChecksData
                                  .value
                                  ?.totalIncomingChecksDinar
                                  .toString() ??
                              '0.0',
                        ),
                      ),
                      subtitle: '',
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
