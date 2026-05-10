import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../domain/entities/working_times_entity.dart';

// حالات الدوام
enum _ShiftStatus {
  beforeShift,        // قبل بداية الدوام
  workingOnTime,      // مداوم في وقته
  absentDuringShift,  // معطل = لم يأتِ أصلاً خلال الدوام
  leftEarly,          // أتى وغادر قبل انتهاء الدوام
  overtime,           // أوفر تايم (بعد انتهاء الدوام ولا يزال شغال)
  leftWork,           // غادر بعد انتهاء الدوام
  neverCame,          // لم يأتِ أصلاً وانتهى وقت الدوام
}

class WorkHoursList extends StatefulWidget {
  const WorkHoursList({Key? key, required this.employee}) : super(key: key);
  final WorkingTimesEntity employee;

  @override
  State<WorkHoursList> createState() => _WorkHoursListState();
}

class _WorkHoursListState extends State<WorkHoursList> {
  Timer? _timer;
  Duration _timerDuration = Duration.zero;
  _ShiftStatus _status = _ShiftStatus.beforeShift;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _update();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// تحويل نص الوقت القادم من الـ API (مثل "2:00 PM" أو "14:00") إلى DateTime لليوم الحالي
  DateTime _parseTimeToday(String timeStr) {
    final now = DateTime.now();
    late DateFormat fmt;
    final upper = timeStr.toUpperCase();
    if (upper.contains('AM') || upper.contains('PM')) {
      // صيغة 12 ساعة مثل "2:00 PM"
      fmt = DateFormat('h:mm a', 'en_US');
    } else if (timeStr.split(':').length == 3) {
      fmt = DateFormat('HH:mm:ss');
    } else {
      fmt = DateFormat('HH:mm');
    }
    final parsed = fmt.parse(timeStr);
    return DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute, parsed.second);
  }

  void _update() {
    try {
      final now = DateTime.now();
      final startTime = _parseTimeToday(widget.employee.startWorkTime);
      final endTime   = _parseTimeToday(widget.employee.endWorkTime);
      final isWorking = widget.employee.isWorkingNow;

      _ShiftStatus newStatus;
      Duration newDuration;

      if (now.isBefore(startTime)) {
        // ─── قبل بداية الدوام ───
        newStatus   = _ShiftStatus.beforeShift;
        newDuration = startTime.difference(now);

      } else if (now.isBefore(endTime)) {
        // ─── خلال فترة الدوام ───
        if (isWorking) {
          newStatus = _ShiftStatus.workingOnTime;
        } else if (widget.employee.hasAttendedToday) {
          // أتى لكن غادر قبل انتهاء الدوام
          newStatus = _ShiftStatus.leftEarly;
        } else {
          // لم يأتِ أصلاً
          newStatus = _ShiftStatus.absentDuringShift;
        }
        newDuration = endTime.difference(now);

      } else {
        // ─── بعد انتهاء وقت الدوام ───
        if (isWorking) {
          newStatus   = _ShiftStatus.overtime;
          newDuration = now.difference(endTime); // عداد تصاعدي
        } else if (widget.employee.hasAttendedToday) {
          newStatus   = _ShiftStatus.leftWork;
          newDuration = Duration.zero;
        } else {
          newStatus   = _ShiftStatus.neverCame;
          newDuration = Duration.zero;
        }
      }

      setState(() {
        _status       = newStatus;
        _timerDuration = newDuration;
      });
    } catch (_) {
      setState(() => _timerDuration = Duration.zero);
    }
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  // ─── ألوان وعناوين كل حالة ───

  Color get _boxColor {
    switch (_status) {
      case _ShiftStatus.beforeShift:
        return Colors.blueGrey;
      case _ShiftStatus.workingOnTime:
        return AppColors.customGreen1;
      case _ShiftStatus.absentDuringShift:
        return Colors.red.shade600;
      case _ShiftStatus.leftEarly:
        return Colors.teal.shade600;
      case _ShiftStatus.overtime:
        return Colors.orange.shade700;
      case _ShiftStatus.leftWork:
        return AppColors.customGreyColor3;
      case _ShiftStatus.neverCame:
        return Colors.red.shade900;
    }
  }

  Color get _timerColor {
    switch (_status) {
      case _ShiftStatus.overtime:
        return Colors.yellow.shade200;
      default:
        return Colors.white;
    }
  }

  bool get _showTimer {
    return _status != _ShiftStatus.leftWork && _status != _ShiftStatus.neverCame;
  }

  String get _statusLabel {
    switch (_status) {
      case _ShiftStatus.beforeShift:
        return 'قبل الدوام';
      case _ShiftStatus.workingOnTime:
        return 'مداوم';
      case _ShiftStatus.absentDuringShift:
        return 'معطل';
      case _ShiftStatus.leftEarly:
        return 'غادر مبكراً';
      case _ShiftStatus.overtime:
        return 'أوفر تايم';
      case _ShiftStatus.leftWork:
        return 'غادر';
      case _ShiftStatus.neverCame:
        return 'لم يحضر';
    }
  }

  String get _timerLabel {
    switch (_status) {
      case _ShiftStatus.beforeShift:
        return 'لبداية الدوام';
      case _ShiftStatus.workingOnTime:
        return 'متبقي';
      case _ShiftStatus.absentDuringShift:
        return 'لانتهاء الدوام';
      case _ShiftStatus.leftEarly:
        return 'لانتهاء الدوام';
      case _ShiftStatus.overtime:
        return 'وقت إضافي';
      case _ShiftStatus.leftWork:
        return '';
      case _ShiftStatus.neverCame:
        return '';
    }
  }

  // ─── نص بادج حالة الموظف (العمود الأوسط) ───
  String get _employeeStatusText {
    switch (_status) {
      case _ShiftStatus.beforeShift:
        return 'قبل بداية دوامه';
      case _ShiftStatus.workingOnTime:
        return 'مداوم في وقته';
      case _ShiftStatus.absentDuringShift:
        return 'معطل لحد الان';
      case _ShiftStatus.leftEarly:
        return 'غادر العمل مبكراً';
      case _ShiftStatus.overtime:
        return 'شغال أوفر تايم';
      case _ShiftStatus.leftWork:
        return 'غادر العمل';
      case _ShiftStatus.neverCame:
        return 'لم يحضر اليوم';
    }
  }

  Color get _employeeStatusColor {
    switch (_status) {
      case _ShiftStatus.beforeShift:
        return Colors.blueGrey;
      case _ShiftStatus.workingOnTime:
        return Colors.green;
      case _ShiftStatus.absentDuringShift:
        return Colors.red;
      case _ShiftStatus.leftEarly:
        return Colors.teal;
      case _ShiftStatus.overtime:
        return Colors.orange;
      case _ShiftStatus.leftWork:
        return Colors.grey;
      case _ShiftStatus.neverCame:
        return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return Row(
      children: [
        // ─── صورة الموظف ───
        Expanded(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: GestureDetector(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Dismiss',
                      barrierColor: Colors.black.withAlpha(128),
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) {
                        return FullScreenZoomImage(
                          imageUrl: widget.employee.employeeImg,
                        );
                      },
                    );
                  },
                  child: Container(
                    height: 80.h,
                    width: 80.w,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      cacheManager: CacheManager(
                        Config(
                          'imagesCache',
                          stalePeriod: const Duration(days: 7),
                          maxNrOfCacheObjects: 100,
                        ),
                      ),
                      imageUrl: widget.employee.employeeImg,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 200),
                      fadeOutDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم الموظف + النجمة
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.employee.employeeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.customGreyColor5,
                            ),
                          ),
                        ),
                        if (widget.employee.isCameOnTime)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Icon(Icons.star,
                                color: Colors.amber, size: 18.sp),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    // بادج حالة الموظف
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _employeeStatusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(
                            color: _employeeStatusColor, width: 0.5),
                      ),
                      child: Text(
                        _employeeStatusText,
                        style: textStyle.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: _employeeStatusColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${'workStartTime'.tr} : ${widget.employee.startWorkTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '${'workEndTime'.tr} : ${widget.employee.endWorkTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ─── زر التاريخ ───
        IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 36.w, minHeight: 48.h),
          onPressed: () => Get.toNamed(
            AppRoutes.EMPLOYEEATTENDANCEHISTORY,
            arguments: {
              'employeeId': widget.employee.id.toString(),
              'employeeName': widget.employee.employeeName,
            },
          ),
          icon: Icon(Icons.history,
              color: AppColors.primaryColor, size: 22.sp),
          tooltip: 'employeeAttendanceHistory'.tr,
        ),

        // ─── مربع العداد التنازلي ───
        Container(
          width: 80.w,
          height: 85.h,
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _boxColor,
            borderRadius: BorderRadiusDirectional.only(
              topEnd: Radius.circular(4.r),
              bottomEnd: Radius.circular(4.r),
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة الحالة
              Icon(
                _status == _ShiftStatus.leftWork
                    ? Icons.logout
                    : _status == _ShiftStatus.beforeShift
                        ? Icons.access_time
                        : _status == _ShiftStatus.overtime
                            ? Icons.alarm_add
                            : _status == _ShiftStatus.absentDuringShift
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle,
                color: _timerColor,
                size: 14.sp,
              ),
              SizedBox(height: 2.h),
              // اسم الحالة
              Text(
                _statusLabel,
                textAlign: TextAlign.center,
                style: textStyle.copyWith(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                  color: _timerColor,
                ),
              ),
              SizedBox(height: 2.h),
              // العداد
              if (_showTimer)
                Text(
                  _formatDuration(_timerDuration),
                  textAlign: TextAlign.center,
                  style: textStyle.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: _timerColor,
                  ),
                ),
              // وصف العداد
              if (_timerLabel.isNotEmpty && _showTimer)
                Text(
                  _timerLabel,
                  textAlign: TextAlign.center,
                  style: textStyle.copyWith(
                    fontSize: 8.sp,
                    color: _timerColor.withValues(alpha: 0.85),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
