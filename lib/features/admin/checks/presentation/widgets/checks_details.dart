import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../--/presentation/dashbord/widgets/stat_card.dart';
import '../controllers/checks_controller.dart';

class ChecksDetails extends StatelessWidget {
  const ChecksDetails({
    Key? key,
    required this.controller,
    required this.numberOfChecks,
    required this.total,
    this.isOutComingChecks = false,
  }) : super(key: key);

  final ChecksController controller;
  final RxString numberOfChecks;
  final RxString total;
  final bool isOutComingChecks;

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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'numberOfChecks',
                  imageicon: AssetsManger.cashIcon,
                  value: numberOfChecks.value,
                  subtitle: '',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: StatCard(
                  title: 'total',
                  imageicon: AssetsManger.cashIcon,
                  value: total.value,
                  subtitle: '',
                ),
              ),
            ],
          ),
          isOutComingChecks
              ? Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'totalFunds',
                        imageicon: AssetsManger.moneyIcon,
                        value: controller.totalFunds.value,
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
                                    value: int.parse(controller
                                            .coveragePercentage.value) /
                                        100,
                                    strokeWidth: 4.w,
                                    backgroundColor: Colors.grey[500],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${controller.coveragePercentage.value}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 12.sp,
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
      ),
    );
  }
}
