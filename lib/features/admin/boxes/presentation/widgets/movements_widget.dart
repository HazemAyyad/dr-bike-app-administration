import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../domain/entity/all_boxes_logs_entity.dart';

class MovementsWidget extends StatelessWidget {
  const MovementsWidget({Key? key, required this.box}) : super(key: key);

  final BoxLog box;

  String get _headline {
    final description = box.description.trim();
    if (description.isNotEmpty) {
      return description;
    }
    if (box.type == 'transfer') {
      return 'transferBalance'.tr;
    }
    if (box.type == 'add') {
      return 'addBalance'.tr;
    }
    return 'withdrawBalance'.tr;
  }

  String? get _subline {
    final note = (box.note ?? '').trim();
    final description = box.description.trim();
    if (note.isEmpty) {
      return null;
    }
    if (note == description) {
      return null;
    }
    return note;
  }

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor3
                        : Colors.black.withValues(alpha: 0.85),
                  ),
                ),
                // SizedBox(height: 2.h),
                box.fromBox != null
                    ? Text(
                        "${'from'.tr} : ${box.fromBox!.name} ${'to'.tr} : ${box.toBox?.name ?? ''}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400,
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor3
                              : Colors.black.withValues(alpha: 0.5),
                        ),
                      )
                    : const SizedBox.shrink(),
                if (_subline != null)
                  Text(
                    _subline!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor3
                          : Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(minWidth: 56.w, maxWidth: 72.w),
          height: 70.h,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: box.type == 'transfer'
                ? AppColors.customOrange3
                : box.type == 'add'
                    ? AppColors.customGreen1
                    : AppColors.redColor,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  NumberFormat('#,###').format(box.value),
                  textAlign: TextAlign.center,
                  style: textStyle.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
