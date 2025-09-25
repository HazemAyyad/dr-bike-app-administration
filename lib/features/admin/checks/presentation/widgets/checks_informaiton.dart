import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
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
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'youOwe',
                      imageicon: AssetsManager.cashIcon,
                      value: ChecksServes()
                              .generalChecksData
                              .value
                              ?.outgoingChecksCount
                              .toString() ??
                          '0',
                      subtitle: '',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: StatCard(
                      title: 'forYou',
                      imageicon: AssetsManager.cashIcon,
                      value: ChecksServes()
                              .generalChecksData
                              .value
                              ?.incomingChecksCount
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
                      title: 'all',
                      imageicon: AssetsManager.productIcon,
                      value: (int.parse(ChecksServes()
                                      .generalChecksData
                                      .value
                                      ?.incomingChecksCount
                                      .toString() ??
                                  '0') +
                              int.parse(ChecksServes()
                                      .generalChecksData
                                      .value
                                      ?.outgoingChecksCount
                                      .toString() ??
                                  '0'))
                          .toString(),
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
                      title: 'totalDebts',
                      imageicon: AssetsManager.moneyIcon,
                      value: NumberFormat('#,###').format(
                        double.parse(
                          ChecksServes()
                                  .generalChecksData
                                  .value
                                  ?.totalOutgoingChecks ??
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
                      title: 'totalOwed',
                      imageicon: AssetsManager.moneyIcon,
                      value: NumberFormat('#,###').format(
                        double.parse(
                          ChecksServes()
                                  .generalChecksData
                                  .value
                                  ?.totalIncomingChecks ??
                              '0',
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
