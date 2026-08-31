import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:flutter/foundation.dart';
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
import 'box_report_filter_sheet.dart';

class VeiwBoxes extends GetView<BoxesController> {
  const VeiwBoxes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BoxesController>(
      builder: (controller) {
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

              final shownBox = box is ShownBoxesModel ? box : null;
              return GestureDetector(
                onTap: controller.currentTab.value == 1
                    ? null
                    : () {
                        final boxArgument = box is ShownBoxesModel
                            ? box.boxId.toString()
                            : box is BoxLogModel
                                ? box.id.toString()
                                : '';
                        if (kDebugMode) {
                          debugPrint(
                            '[VeiwBoxes.onTap] tab=${controller.currentTab.value} '
                            'boxType=${box.runtimeType} argument=$boxArgument',
                          );
                        }
                        Get.toNamed(
                          AppRoutes.EDITBOXESSCREEN,
                          arguments: boxArgument,
                        );
                      },
                onLongPress: controller.currentTab.value == 0 ||
                        controller.currentTab.value == 2
                    ? () => Get.dialog(
                          OnLongPressInBox(box: box as ShownBoxesModel),
                        )
                    : null,
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: 6.h,
                    right: 16.w,
                    left: 16.w,
                  ),
                  constraints: BoxConstraints(minHeight: 60.h),
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2,
                    borderRadius: BorderRadius.circular(11.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(32),
                        blurRadius: 8.r,
                        offset: const Offset(0, 2),
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
                          ? Expanded(
                              child: BoxesWidget(
                                box: shownBox!,
                                lastMovement:
                                    controller.lastMovementFor(shownBox.boxId),
                                onReport: () => Get.bottomSheet(
                                  BoxReportFilterSheet(
                                    boxId: shownBox.boxId.toString(),
                                    boxName: shownBox.boxName,
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                ),
                              ),
                            )
                          : controller.currentTab.value == 1
                              ? Expanded(
                                  child: MovementsWidget(
                                    box: box as BoxLogModel,
                                    onTap: () => _openMovementBox(box),
                                    onDetails: () =>
                                        _showMovementDetails(context, box),
                                  ),
                                )
                              : Expanded(
                                  child: ArchiveWidget(
                                    box: shownBox!,
                                    onReport: () => Get.bottomSheet(
                                      BoxReportFilterSheet(
                                        boxId: shownBox.boxId.toString(),
                                        boxName: shownBox.boxName,
                                      ),
                                      isScrollControlled: true,
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                  ),
                                )
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

void _openMovementBox(BoxLogModel log) {
  final id = log.boxId ?? log.fromBoxId ?? log.toBoxId;
  if (id == null || id.isEmpty) {
    Get.snackbar('تنبيه', 'لا يوجد صندوق مرتبط بهذه الحركة');
    return;
  }
  Get.toNamed(AppRoutes.EDITBOXESSCREEN, arguments: id);
}

void _showMovementDetails(BuildContext context, BoxLogModel log) {
  final rows = <MapEntry<String, String>>[
    MapEntry('رقم الحركة', '${log.id}'),
    MapEntry('الوصف', log.description),
    MapEntry('النوع', log.type ?? '—'),
    MapEntry('القيمة', '${log.value}'),
    MapEntry('الصندوق', log.box?.name ?? '—'),
    MapEntry('من صندوق', log.fromBox?.name ?? '—'),
    MapEntry('إلى صندوق', log.toBox?.name ?? '—'),
    MapEntry('الملاحظة', log.note ?? '—'),
    MapEntry('طريقة الدفع', log.paymentMethod ?? '—'),
    MapEntry('رقم الفاتورة', log.invoiceNumber ?? '—'),
    MapEntry('رقم الصيانة', log.maintenanceId ?? '—'),
    MapEntry('الرصيد قبل الحركة', log.boxBalanceBefore?.toString() ?? '—'),
    MapEntry('الرصيد بعد الحركة', log.boxBalanceAfter?.toString() ?? '—'),
    MapEntry('تؤثر على الكاش', log.affectsCashBalance ? 'نعم' : 'لا'),
    MapEntry('التاريخ', log.createdAt.toLocal().toString()),
  ];
  Get.bottomSheet(
    SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تفاصيل الحركة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    )),
            SizedBox(height: 10.h),
            ...rows.map((row) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 115.w,
                        child: Text(row.key,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Expanded(child: Text(row.value)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  );
}
