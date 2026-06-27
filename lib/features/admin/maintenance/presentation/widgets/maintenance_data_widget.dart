import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/helpers/open_apps.dart';
import '../../../../../core/helpers/phone_format_helper.dart';
import '../../data/models/maintenances_model.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceDataWidget extends GetView<MaintenanceController> {
  const MaintenanceDataWidget({Key? key}) : super(key: key);

  String? _resolvePhone(MaintenanceDataModel item) {
    final fromApi = item.contactPhone?.trim();
    if (fromApi != null && fromApi.isNotEmpty) {
      return PhoneFormatHelper.forDialer(fromApi);
    }
    if (item.sellerId != null) {
      for (final s in controller.allSellersList) {
        if (s.id == item.sellerId && s.phone.isNotEmpty) {
          return PhoneFormatHelper.forDialer(s.phone);
        }
      }
    }
    if (item.customerId != null) {
      for (final c in controller.allCustomersList) {
        if (c.id == item.customerId && c.phone.isNotEmpty) {
          return PhoneFormatHelper.forDialer(c.phone);
        }
      }
    }
    return null;
  }

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
                  ? controller.maintenancesSearch.keys
                      .toList()
                      .reversed
                      .toList()[index]
                  : controller.currentTab.value == 1
                      ? controller.ongoingMaintenancesSearch.keys
                          .toList()
                          .reversed
                          .toList()[index]
                      : controller.currentTab.value == 2
                          ? controller.readyMaintenancesSearch.keys
                              .toList()
                              .reversed
                              .toList()[index]
                          : controller.archiveMaintenancesSearch.keys
                              .toList()
                              .reversed
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

              return Padding(
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
                      (item) {
                        final displayName =
                            (item.sellerName != null && item.sellerName!.isNotEmpty)
                                ? item.sellerName!
                                : item.customerName;

                        return GestureDetector(
                        onLongPress: () async {
                          controller.getAllCustomersAndSellers();
                          final phone = _resolvePhone(item);
                          if (phone == null || phone.isEmpty) {
                            Get.snackbar(
                              'error'.tr,
                              'noPhoneNumber'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }
                          await showModalBottomSheet<void>(
                            context: context,
                            builder: (ctx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.phone),
                                    title: Text('callCustomer'.tr),
                                    subtitle: Text(phone),
                                    onTap: () async {
                                      Navigator.pop(ctx);
                                      await launchDialer(phoneNumber: phone);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        onTap: () {
                          controller.getMaintenancesDetails(
                            maintenanceId: item.id.toString(),
                          );
                          Get.toNamed(AppRoutes.NEWMAINTENANCESCREEN);
                        },
                        child: Container(
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
                                            cacheManager: CacheManager(
                                              Config(
                                                'imagesCache',
                                                stalePeriod:
                                                    const Duration(days: 7),
                                                maxNrOfCacheObjects: 100,
                                              ),
                                            ),
                                            imageBuilder:
                                                (context, imageProvider) =>
                                                    Container(
                                              height: 50.h,
                                              width: 64.w,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.cover,
                                                  filterQuality:
                                                      FilterQuality.medium,
                                                ),
                                              ),
                                            ),
                                            imageUrl: item.mediaFiles,
                                            placeholder: (context, url) =>
                                                SizedBox(
                                              height: 50.h,
                                              width: 64.w,
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5.w),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
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
                                                  fontSize: 12.sp,
                                                  color: Colors.grey
                                                      .withAlpha(500),
                                                ),
                                          ),
                                          if (item.invoiceTotal > 0)
                                            Text(
                                              '${'total'.tr}: ${item.invoiceTotal.toStringAsFixed(2)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primaryColor,
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
                                  width: 58.w,
                                  height: 58.h,
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
                      );
                      },
                    ),
                  ],
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
