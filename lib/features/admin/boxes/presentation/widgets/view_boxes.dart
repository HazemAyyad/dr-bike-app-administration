import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
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
    return Obx(
      () {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.currentTab.value == 0 &&
            controller.filteredShownBoxes.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        if (controller.currentTab.value == 1 &&
            controller.filteredAllBoxesLogs.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        if (controller.currentTab.value == 2 &&
            controller.filteredShownBoxesArchive.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, section) {
              final box = controller.currentTab.value == 0
                  ? controller.filteredShownBoxes.reversed.toList()[section]
                  : controller.currentTab.value == 1
                      ? controller.filteredAllBoxesLogs.reversed
                          .toList()[section]
                      : controller.filteredShownBoxesArchive.reversed
                          .toList()[section];

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
                  height: 70.h,
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
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ClipRRect(
                      //   borderRadius: BorderRadius.circular(5.r),
                      //   child: Image.asset(
                      //     AssetsManager.boxesImage,
                      //     height: 70.h,
                      //     width: 70.w,
                      //     fit: BoxFit.cover,
                      //   ),
                      // ),
                      // SizedBox(width: 10.w),
                      controller.currentTab.value == 0
                          ? BoxesWidget(box: box as GetShownBoxesModel)
                          : controller.currentTab.value == 1
                              ? Flexible(
                                  child:
                                      MovementsWidget(box: box as BoxLogModel),
                                )
                              : ArchiveWidget(box: box as GetShownBoxesModel)
                    ],
                  ),
                ),
              );
            },
            childCount: controller.currentTab.value == 0
                ? controller.filteredShownBoxes.length
                : controller.currentTab.value == 1
                    ? controller.filteredAllBoxesLogs.length
                    : controller.filteredShownBoxesArchive.length,
          ),
        );
      },
    );
  }
}
