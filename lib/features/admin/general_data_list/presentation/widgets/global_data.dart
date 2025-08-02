import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/open_apps.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/general_data_list_controller.dart';

class GlobalData extends StatelessWidget {
  const GlobalData({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final GeneralDataListController controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(
        () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: ListView.builder(
            key: ValueKey<int>(controller.currentTab.value),
            itemCount: controller.generalDatalist.length,
            itemBuilder: (context, index) {
              final generalData = controller.generalDatalist[index];
              return GestureDetector(
                // overlayColor: WidgetStateProperty.all(Colors.transparent),
                onTap: () {
                  // Handle order card tap
                  Get.toNamed(
                    AppRoutes.GLOBALCUSTOMERDATASCREEN,
                    arguments: generalData,
                  );
                },
                onLongPress: () {
                  Get.dialog(
                    AlertDialog(
                      backgroundColor: ThemeService.isDark.value
                          ? AppColors.darckColor
                          : AppColors.whiteColor,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.h),
                          GestureDetector(
                            onTap: () {
                              launchDialer(
                                  '${generalData['customerPhoneNumber']}');
                            },
                            child: Row(
                              children: [
                                SizedBox(width: 5.h),
                                Icon(
                                  Icons.phone_outlined,
                                  color: AppColors.primaryColor,
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  'directContact'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.blackColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          GestureDetector(
                            onTap: () {
                              launchWhatsApp(
                                  phoneNumber:
                                      '${generalData['customerPhoneNumber']}');
                            },
                            child: Row(
                              children: [
                                Image.asset(
                                  AssetsManger.whatsapp,
                                  height: 30.h,
                                  width: 30.w,
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  'directContact'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.blackColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor4
                        : AppColors.whiteColor2,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(32),
                        blurRadius: 5.r,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5.r),
                        child: CachedNetworkImage(
                          imageUrl: generalData['image'],
                          height: 70.h,
                          width: 70.w,
                          imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  generalData['customerName'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.customGreyColor5,
                                      ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  generalData['job'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.customGreyColor5,
                                      ),
                                ),
                              ],
                            ),
                            Text(
                              generalData['customerPhoneNumber'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.customGreyColor5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
