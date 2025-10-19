import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/show_no_data.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/assets_controller.dart';
import '../../controllers/finacial_service.dart';

class AssetsLogScreen extends GetView<AssetsController> {
  const AssetsLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'log',
        actions: [
          IconButton(
            onPressed: () {
              controller.downloadReport();
            },
            icon: Icon(
              Icons.downloading_rounded,
              color: AppColors.primaryColor,
              size: 30.sp,
            ),
          ),
          SizedBox(width: 20.w),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          GetBuilder<AssetsController>(
            builder: (controller) {
              if (controller.isLoadingDepreciate.value) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (FinacialService().assetsLogs.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: ShowNoData(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final assetLog =
                        FinacialService().assetsLogs.reversed.toList()[index];

                    return Container(
                      margin:
                          EdgeInsets.symmetric(vertical: 5.h, horizontal: 24.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9.r),
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : AppColors.whiteColor2,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.all(8.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    assetLog.type == 'create'
                                        ? '${'createDate'.tr}: ${showData(assetLog.depreciationDate)}'
                                        : '${'consumptionDate'.tr}: ${showData(assetLog.depreciationDate)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          color: AppColors.greyColor,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    '${'averageConsumptionRatio'.tr}: ${assetLog.depreciationRate}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          color: AppColors.greyColor,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(5.r),
                            decoration: BoxDecoration(
                              borderRadius: Get.locale!.languageCode == 'ar'
                                  ? BorderRadius.only(
                                      bottomLeft: Radius.circular(4.r),
                                      topLeft: Radius.circular(4.r),
                                    )
                                  : BorderRadius.only(
                                      bottomRight: Radius.circular(4.r),
                                      topRight: Radius.circular(4.r),
                                    ),
                              color: AppColors.graywhiteColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  spreadRadius: 1,
                                  blurRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            height: 60.h,
                            width: 60.w,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Flexible(
                                  child: Text(
                                    'total'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          color: AppColors.customGreyColor4,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    NumberFormat('#,###')
                                        .format(double.parse(assetLog.total)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          color: AppColors.customGreyColor4,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: FinacialService().assetsLogs.take(200).length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 50.h)),
        ],
      ),
    );
  }
}
