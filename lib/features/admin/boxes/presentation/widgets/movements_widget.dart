import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../domain/entity/all_boxes_logs_entity.dart';

class MovementsWidget extends StatelessWidget {
  const MovementsWidget({Key? key, required this.box}) : super(key: key);
  final BoxLog box;
  bool get _outgoing => box.type == 'minus' || box.value < 0;
  String get _title => box.description.trim().isNotEmpty
      ? box.description.trim()
      : box.type == 'transfer'
          ? 'تحويل رصيد'
          : _outgoing
              ? 'سحب رصيد'
              : 'إضافة رصيد';
  String get _boxLabel => box.type == 'transfer'
      ? '${box.fromBox?.name ?? 'صندوق'} ← ${box.toBox?.name ?? 'صندوق'}'
      : box.box?.name ??
          box.fromBox?.name ??
          box.toBox?.name ??
          'صندوق غير محدد';

  @override
  Widget build(BuildContext context) {
    final color = box.type == 'transfer'
        ? AppColors.customOrange3
        : _outgoing
            ? AppColors.redColor
            : AppColors.customGreen1;
    final muted = ThemeService.isDark.value
        ? AppColors.graywhiteColor
        : AppColors.customGreyColor5;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Row(children: [
        Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(9.r)),
            child: Icon(
                box.type == 'transfer'
                    ? Icons.swap_horiz_rounded
                    : _outgoing
                        ? Icons.north_east_rounded
                        : Icons.south_west_rounded,
                color: color,
                size: 18.sp)),
        SizedBox(width: 9.w),
        Expanded(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(_title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5.sp, fontWeight: FontWeight.w800)),
              SizedBox(height: 3.h),
              Row(children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 12.sp, color: AppColors.primaryColor),
                SizedBox(width: 3.w),
                Expanded(
                    child: Text(_boxLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700)))
              ]),
              Text(
                  DateFormat('d/M/yyyy · HH:mm')
                      .format(box.createdAt.toLocal()),
                  style: TextStyle(color: muted, fontSize: 9.5.sp)),
            ])),
        SizedBox(width: 7.w),
        Text(
            '${box.type == 'transfer' ? '' : _outgoing ? '-' : '+'}${NumberFormat('#,##0.##').format(box.value.abs())}',
            style: TextStyle(
                color: color, fontSize: 14.sp, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}
