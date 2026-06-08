import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../utils/app_colors.dart';

/// Shows device + server timestamps for fingerprint attendance; single time otherwise.
class AttendanceDualTimeText extends StatelessWidget {
  const AttendanceDualTimeText({
    Key? key,
    required this.deviceAt,
    this.serverAt,
    this.source,
    this.compact = false,
    this.textStyle,
    this.secondaryStyle,
    this.inline = false,
    this.fallback = '—',
  }) : super(key: key);

  final DateTime? deviceAt;
  final DateTime? serverAt;
  final String? source;
  final bool compact;
  final bool inline;
  final TextStyle? textStyle;
  final TextStyle? secondaryStyle;
  final String fallback;

  static bool showDual(String? source, DateTime? serverAt) =>
      source == 'fingerprint' && serverAt != null;

  static String formatHm(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final primary = textStyle ??
        TextStyle(
          fontSize: compact ? 10.5.sp : 11.sp,
          color: AppColors.operationalNavy,
          fontWeight: FontWeight.w600,
          height: 1.2,
        );
    final secondary = secondaryStyle ??
        TextStyle(
          fontSize: compact ? 9.5.sp : 10.sp,
          color: AppColors.customGreyColor5,
          height: 1.2,
        );

    if (deviceAt == null) {
      return Text(fallback, style: primary);
    }

    if (!showDual(source, serverAt)) {
      return Text(formatHm(deviceAt), style: primary);
    }

    if (inline) {
      return Text(
        '${'deviceTimeShort'.tr} ${formatHm(deviceAt)} · ${'serverTimeShort'.tr} ${formatHm(serverAt)}',
        style: primary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${'fingerprintDeviceTime'.tr}: ${formatHm(deviceAt)}',
          style: primary,
        ),
        SizedBox(height: compact ? 1.h : 2.h),
        Text(
          '${'fingerprintServerTime'.tr}: ${formatHm(serverAt)}',
          style: secondary,
        ),
      ],
    );
  }
}

/// Two-column chip row for check-in / check-out dual times inside cards.
class AttendanceDualTimeTile extends StatelessWidget {
  const AttendanceDualTimeTile({
    Key? key,
    required this.label,
    required this.deviceAt,
    this.serverAt,
    this.source,
    required this.accent,
    this.fallback,
  }) : super(key: key);

  final String label;
  final DateTime? deviceAt;
  final DateTime? serverAt;
  final String? source;
  final Color accent;
  final String? fallback;

  @override
  Widget build(BuildContext context) {
    final showDual = AttendanceDualTimeText.showDual(source, serverAt);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.sp,
              color: AppColors.customGreyColor5,
            ),
          ),
          SizedBox(height: 4.h),
          if (deviceAt == null)
            Text(
              fallback ?? '—',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.operationalNavy,
              ),
            )
          else if (!showDual)
            Text(
              AttendanceDualTimeText.formatHm(deviceAt),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.operationalNavy,
              ),
            )
          else ...[
            Text(
              '${'deviceTimeShort'.tr} ${AttendanceDualTimeText.formatHm(deviceAt)}',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.operationalNavy,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '${'serverTimeShort'.tr} ${AttendanceDualTimeText.formatHm(serverAt)}',
              style: TextStyle(
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.customGreyColor5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
