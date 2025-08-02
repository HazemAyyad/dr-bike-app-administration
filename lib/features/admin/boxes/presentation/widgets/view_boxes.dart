import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/boxes_controller.dart';
import 'archive_widget.dart';
import 'boxes_widget.dart';
import 'movements_widget.dart';
import 'on_long_press_in_box.dart';

class VeiwBoxes extends GetView<BoxesController> {
  const VeiwBoxes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;
    return Obx(
      () => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : controller.boxes.isEmpty
              ? Center(
                  child: Text(
                    'noData'.tr,
                    style: textStyle.copyWith(
                      color: AppColors.customGreyColor,
                    ),
                  ),
                )
              : SliverList.builder(
                  itemCount: controller.boxes.length,
                  itemBuilder: (context, section) {
                    final box = controller.boxes[section];
                    return GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.EDITBOXESSCREEN),
                      onLongPress: () => controller.currentTab.value == 0
                          ? {
                              Get.dialog(
                                OnLongPressInBox(),
                                // isDismissible: true,
                                // enableDrag: true,
                              ),
                            }
                          : null,
                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: 10.h,
                          right: 24.w,
                          left: 24.w,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor
                              : AppColors.whiteColor2,
                          borderRadius: BorderRadius.circular(4.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(32),
                              blurRadius: 2.r,
                              spreadRadius: 1.r,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5.r),
                              child: CachedNetworkImage(
                                imageUrl: box['image'],
                                height: 70.h,
                                width: 70.w,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: const CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            controller.currentTab.value == 0
                                ? BoxesWidget(box: box)
                                : controller.currentTab.value == 1
                                    ? MovementsWidget(box: box)
                                    : ArchiveWidget(box: box)
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
