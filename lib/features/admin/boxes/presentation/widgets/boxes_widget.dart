import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/all_boxes_logs_model.dart';
import '../../data/models/get_shown_boxes_model.dart';

class BoxesWidget extends StatelessWidget {
  const BoxesWidget({
    Key? key,
    required this.box,
    required this.lastMovement,
    required this.onReport,
  }) : super(key: key);

  final ShownBoxesModel box;
  final BoxLogModel? lastMovement;
  final VoidCallback onReport;

  String _movementText() {
    final log = lastMovement;
    if (log == null) return 'لا توجد حركات بعد';
    final description = log.description.trim();
    final label = description.isEmpty ? _typeLabel(log.type) : description;
    final date = DateFormat('d/M · HH:mm').format(log.createdAt.toLocal());
    return '$label  •  $date';
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'add':
        return 'إضافة رصيد';
      case 'minus':
        return 'سحب رصيد';
      case 'transfer':
        return 'تحويل رصيد';
      case 'maintenance':
        return 'حركة صيانة';
      default:
        return 'حركة صندوق';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeService.isDark.value;
    final titleColor = dark ? AppColors.whiteColor : const Color(0xFF172033);
    final muted = dark ? AppColors.graywhiteColor : const Color(0xFF6B7280);
    final currency = box.currency.trim().isEmpty ? 'بدون عملة' : box.currency;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(10.w, 8.h, 6.w, 8.h),
      child: Row(
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 19,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        box.boxName.trim().isEmpty
                            ? 'صندوق بدون اسم'
                            : box.boxName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      NumberFormat('#,##0.##').format(box.totalBalance),
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: Text(
                        currency,
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.history_rounded, size: 13.sp, color: muted),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        _movementText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: muted,
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints.tightFor(width: 36.w, height: 36.h),
            padding: EdgeInsets.zero,
            tooltip: 'تقرير PDF',
            onPressed: onReport,
            icon: Icon(
              Icons.picture_as_pdf_outlined,
              size: 20.sp,
              color: const Color(0xFFB42318),
            ),
          ),
          Icon(Icons.chevron_left_rounded, size: 19.sp, color: muted),
        ],
      ),
    );
  }
}
