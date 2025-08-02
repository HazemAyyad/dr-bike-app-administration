import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../controllers/checks_controller.dart';
import 'on_long_press.dart';
import 'view_checks_widget.dart';

class CustomListVeiwBuilder extends StatelessWidget {
  const CustomListVeiwBuilder({
    Key? key,
    required this.list,
    required this.controller,
  }) : super(key: key);

  final RxList<Map<String, dynamic>> list;
  final ChecksController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final grouped = groupBy(list, (Map v) => v['month'] as String);
        final months = grouped.keys.toList();
        return list.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : list.isEmpty
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
                              (item) => GestureDetector(
                                onLongPress: listEquals(
                                  list,
                                  controller.inComingChecksList,
                                )
                                    ? () {
                                        onLongPress(
                                          item,
                                          context,
                                          controller,
                                          controller
                                              .incomingChecksDidNotActOnIt,
                                          controller.incomingChecksActedOnIt,
                                          controller.archive,
                                        );
                                      }
                                    : () {
                                        controller.currentTab.value == 2
                                            ? null
                                            : onLongPress(
                                                item,
                                                context,
                                                controller,
                                                controller
                                                    .outgoingChecksDidNotActOnIt,
                                                controller
                                                    .outgoingChecksActedOnIt,
                                                null,
                                              );
                                      },
                                child: ViewChecksWidget(
                                  check: item,
                                  currentTab: controller.currentTab.value,
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
