import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
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
            controller.maintenancesList.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        if (controller.currentTab.value == 1 &&
            controller.ongoingMaintenancesList.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        if (controller.currentTab.value == 2 &&
            controller.readyMaintenancesList.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        if (controller.currentTab.value == 3 &&
            controller.archiveMaintenancesList.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = controller.currentTab.value == 0
                  ? controller.maintenancesList[index]
                  : controller.currentTab.value == 1
                      ? controller.ongoingMaintenancesList[index]
                      : controller.currentTab.value == 2
                          ? controller.readyMaintenancesList[index]
                          : controller.archiveMaintenancesList[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // separator عنوان الشهر
                    // Row(
                    //   children: [
                    //     Text(
                    //       'month',
                    //       style: Theme.of(context)
                    //           .textTheme
                    //           .headlineMedium!
                    //           .copyWith(
                    //             color: AppColors.primaryColor,
                    //             fontWeight: FontWeight.w700,
                    //             fontSize: 15.sp,
                    //           ),
                    //     ),
                    //   ],
                    // ),
                    // SizedBox(height: 5.h),
                    // Container(
                    //   height: 1.h,
                    //   width: double.infinity,
                    //   color: AppColors.primaryColor,
                    // ),
                    SizedBox(height: 10.h),
                    // عرض العناصر
                    // ...items.map(
                    //   (item) =>
                    Container(
                      margin: EdgeInsets.only(bottom: 10.h),
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5.w, vertical: 5.h),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(5.r),
                                    child: CachedNetworkImage(
                                      imageUrl: item.mediaFiles,
                                      height: 65.h,
                                      width: 65.w,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.sellerName == null
                                            ? 'No Name'
                                            : item.sellerName!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.grey.withAlpha(500),
                                            ),
                                      ),
                                      SizedBox(height: 5.h),
                                      Text(
                                        showData(item.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.grey.withAlpha(500),
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
                              width: 60.w,
                              height: 75.h,
                              decoration: BoxDecoration(
                                color: getStatusColor(
                                  receiptDate: item.createdAt,
                                  receiptTime: item.receiptTime,
                                  currentTab: controller.currentTab.value,
                                ),
                                borderRadius: Get.locale!.languageCode == 'en'
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
                                      ? 'تم التسليم'
                                      : getStatusText(
                                          receiptDate: item.createdAt,
                                          receiptTime: item.receiptTime,
                                        ),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize:
                                            controller.currentTab.value == 3
                                                ? 13.sp
                                                : 17.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // ),
                    ),
                  ],
                ),
              );
            },
            childCount: controller.currentTab.value == 0
                ? controller.maintenancesList.length
                : controller.currentTab.value == 1
                    ? controller.ongoingMaintenancesList.length
                    : controller.currentTab.value == 2
                        ? controller.readyMaintenancesList.length
                        : controller.archiveMaintenancesList.length,
          ),
        );
      },
    );
  }
}
