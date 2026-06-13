import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/get_shown_boxes_model.dart';

class BoxesWidget extends StatelessWidget {
  const BoxesWidget({Key? key, required this.box}) : super(key: key);

  final ShownBoxesModel box;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Row(
          children: [
            Expanded(
              child: Text(
                box.boxName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textStyle.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor3
                      : Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                "${NumberFormat('#,###').format(box.totalBalance)} ${box.currency}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: textStyle.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor3
                      : Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
