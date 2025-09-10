import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceDataWidget extends GetView<MaintenanceController> {
  const MaintenanceDataWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final grouped =
        groupBy(controller.maintenanceList, (Map v) => v['days'] as String);
    final months = grouped.keys.toList();
    return Obx(
      () {
        return controller.maintenanceList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : controller.maintenanceList.isEmpty
                ? Center(
                    child: Text(
                      'noData'.tr,
                      style:
                          Theme.of(context).textTheme.headlineMedium!.copyWith(
                                color: AppColors.customGreyColor,
                              ),
                    ),
                  )
                : SliverList.builder(
                    itemCount: months.length,
                    itemBuilder: (context, section) {
                      final month = months[section];
                      final items = grouped[month]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            ...items.map(
                              (item) => Container(
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
                                              borderRadius:
                                                  BorderRadius.circular(5.r),
                                              child: CachedNetworkImage(
                                                imageUrl: item['image'],
                                                height: 65.h,
                                                width: 65.w,
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
                                            SizedBox(width: 20.w),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name'],
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: Colors.grey
                                                            .withAlpha(500),
                                                      ),
                                                ),
                                                SizedBox(height: 5.h),
                                                Text(
                                                  item['date'],
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w400,
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
                                        width: 60.w,
                                        height: 75.h,
                                        decoration: BoxDecoration(
                                          color: controller.currentTab.value ==
                                                  3
                                              ? AppColors.customGreen1
                                              : int.parse(item['time']) > 1
                                                  ? AppColors.customGreen1
                                                  : int.parse(item['time']) > 0
                                                      ? AppColors.customOrange3
                                                      : AppColors.redColor,
                                          borderRadius:
                                              Get.locale!.languageCode == 'en'
                                                  ? BorderRadius.only(
                                                      topRight:
                                                          Radius.circular(4.r),
                                                      bottomRight:
                                                          Radius.circular(4.r),
                                                    )
                                                  : BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(4.r),
                                                      bottomLeft:
                                                          Radius.circular(4.r),
                                                    ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              controller.currentTab.value == 3
                                                  ? item['archive']
                                                  : item['time'] ?? '0',
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                    fontSize: controller
                                                                .currentTab
                                                                .value ==
                                                            3
                                                        ? 13.sp
                                                        : 17.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                            SizedBox(height: 5.h),
                                            controller.currentTab.value == 3
                                                ? const SizedBox()
                                                : Text(
                                                    int.parse(item['time']) >
                                                                10 ||
                                                            int.parse(item[
                                                                    'time']) <
                                                                -10
                                                        ? 'hour'.tr
                                                        : 'hours'.tr,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontSize: 12.sp,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
      },
    );
  }
}
