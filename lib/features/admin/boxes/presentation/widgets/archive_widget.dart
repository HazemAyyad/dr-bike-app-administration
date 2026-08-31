import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/get_shown_boxes_model.dart';

class ArchiveWidget extends StatelessWidget {
  const ArchiveWidget({
    Key? key,
    required this.box,
    required this.onReport,
  }) : super(key: key);

  final ShownBoxesModel box;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Padding(
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
          Text(
            box.currency.trim().isEmpty ? 'بدون عملة' : box.currency,
            style: textStyle.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
            ),
          ),
          IconButton(
            tooltip: 'تقرير PDF',
            visualDensity: VisualDensity.compact,
            onPressed: onReport,
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Color(0xFFB42318),
            ),
          ),
        ],
      ),
    );
  }
}
