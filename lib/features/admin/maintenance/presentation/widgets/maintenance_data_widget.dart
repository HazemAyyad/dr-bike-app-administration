import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceDataWidget extends GetView<MaintenanceController> {
  const MaintenanceDataWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MaintenanceController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (controller.currentTab.value == 0 &&
            controller.maintenancesSearch.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        if (controller.currentTab.value == 1 &&
            controller.ongoingMaintenancesSearch.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        if (controller.currentTab.value == 2 &&
            controller.readyMaintenancesSearch.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        if (controller.currentTab.value == 3 &&
            controller.archiveMaintenancesSearch.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final month = controller.currentTab.value == 0
                  ? controller.maintenancesSearch.keys.toList()[index]
                  : controller.currentTab.value == 1
                      ? controller.ongoingMaintenancesSearch.keys
                          .toList()[index]
                      : controller.currentTab.value == 2
                          ? controller.readyMaintenancesSearch.keys
                              .toList()[index]
                          : controller.archiveMaintenancesSearch.keys
                              .toList()[index];

              final assets = controller.currentTab.value == 0
                  ? controller.maintenancesSearch[month]!.reversed.toList()
                  : controller.currentTab.value == 1
                      ? controller.ongoingMaintenancesSearch[month]!.reversed
                          .toList()
                      : controller.currentTab.value == 2
                          ? controller.readyMaintenancesSearch[month]!.reversed
                              .toList()
                          : controller
                              .archiveMaintenancesSearch[month]!.reversed
                              .toList();

              return GestureDetector(
                onTap: () {
                  controller.getMaintenancesDetails(
                    maintenanceId: assets[index].id.toString(),
                  );
                  Get.toNamed(AppRoutes.NEWMAINTENANCESCREEN);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),

                      // separator عنوان الشهر
                      Row(
                        children: [
                          Text(
                            month,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.sp,
                                ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Container(
                        height: 1.h,
                        width: double.infinity,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(height: 10.h),
                      // عرض العناصر
                      ...assets.map(
                        (item) => Container(
                          margin: EdgeInsets.symmetric(vertical: 5.h),
                          decoration: BoxDecoration(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor4
                                : AppColors.whiteColor2,
                            borderRadius: BorderRadius.circular(4.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withAlpha(32),
                                blurRadius: 5.r,
                                spreadRadius: 2.r,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(5.r),
                                          child: CachedNetworkImage(
                                            imageUrl: item.mediaFiles,
                                            height: 60.h,
                                            width: 80.w,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Center(
                                                    child:
                                                        CircularProgressIndicator()),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 20.w),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.sellerName != null
                                                ? item.sellerName!
                                                : item.customerName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.grey
                                                      .withAlpha(500),
                                                ),
                                          ),
                                          SizedBox(height: 5.h),
                                          Text(
                                            showData(item.receiptDate),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.grey
                                                      .withAlpha(500),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Obx(
                                () => Container(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 5.w),
                                  width: 70.w,
                                  height: 70.h,
                                  decoration: BoxDecoration(
                                    color: getStatusColor(
                                      receiptDate: item.receiptDate,
                                      receiptTime: item.receiptTime,
                                      currentTab: controller.currentTab.value,
                                    ),
                                    borderRadius: Get.locale!.languageCode ==
                                            'en'
                                        ? BorderRadius.only(
                                            topRight: Radius.circular(4.r),
                                            bottomRight: Radius.circular(4.r),
                                          )
                                        : BorderRadius.only(
                                            topLeft: Radius.circular(4.r),
                                            bottomLeft: Radius.circular(4.r),
                                          ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      controller.currentTab.value == 3
                                          ? 'delivered'.tr
                                          : getStatusText(
                                              receiptDate: item.receiptDate,
                                              receiptTime: item.receiptTime,
                                            ),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontSize: 17.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: controller.currentTab.value == 0
                ? controller.maintenancesSearch.length
                : controller.currentTab.value == 1
                    ? controller.ongoingMaintenancesSearch.length
                    : controller.currentTab.value == 2
                        ? controller.readyMaintenancesSearch.length
                        : controller.archiveMaintenancesSearch.length,
          ),
        );
      },
    );
  }
}
