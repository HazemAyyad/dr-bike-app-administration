import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/get_shown_boxes_model.dart';

class ArchiveWidget extends StatelessWidget {
  const ArchiveWidget({Key? key, required this.box}) : super(key: key);

  final GetShownBoxesModel box;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          box.boxName,
          style: textStyle.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor3
                : Colors.black.withValues(alpha: 0.5),
          ),
        ),
        Text(
          'غير ظاهر',
          style: textStyle.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}
