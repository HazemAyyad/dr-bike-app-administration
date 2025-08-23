import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/all_boxes_logs_model.dart';
import '../../data/models/get_shown_boxes_model.dart';
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
      () {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.currentTab.value == 0 ||
            controller.currentTab.value == 2) {
          if (controller.filteredshownBoxes.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'noData'.tr,
                  style: textStyle.copyWith(
                    color: AppColors.customGreyColor,
                  ),
                ),
              ),
            );
          }
        } else {
          if (controller.filteredallBoxesLogs.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'noData'.tr,
                  style: textStyle.copyWith(
                    color: AppColors.customGreyColor,
                  ),
                ),
              ),
            );
          }
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, section) {
              final box = controller.currentTab.value == 1
                  ? controller.filteredallBoxesLogs[section]
                  : controller.filteredshownBoxes[section];

              return GestureDetector(
                onTap: controller.currentTab.value == 1
                    ? null
                    : () {
                        controller.getboxDetails(
                          box is GetShownBoxesModel
                              ? box.boxId.toString()
                              : box is BoxLogModel
                                  ? box.id.toString()
                                  : '',
                        );
                        Get.toNamed(
                          AppRoutes.EDITBOXESSCREEN,
                          arguments: box is GetShownBoxesModel
                              ? box.boxId.toString()
                              : box is BoxLogModel
                                  ? box.id.toString()
                                  : '',
                        );
                      },
                onLongPress: controller.currentTab.value == 0
                    ? () => Get.dialog(
                          OnLongPressInBox(box: box as GetShownBoxesModel),
                        )
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
                        child: Image.asset(
                          AssetsManger.boxesImage,
                          height: 70.h,
                          width: 70.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      controller.currentTab.value == 0
                          ? BoxesWidget(box: box as GetShownBoxesModel)
                          : controller.currentTab.value == 1
                              ? MovementsWidget(box: box as BoxLogModel)
                              : ArchiveWidget(box: box as GetShownBoxesModel)
                    ],
                  ),
                ),
              );
            },
            childCount: controller.currentTab.value == 1
                ? controller.filteredallBoxesLogs.length
                : controller.filteredshownBoxes.length,
          ),
        );
      },
    );
  }
}
