import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/services/impersonation_service.dart';
import '../../../../../../core/services/initial_bindings.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../domain/entities/employee_entity.dart';
import '../../../domain/entities/working_times_entity.dart';
import '../../controllers/employee_section_controller.dart';

enum _ShiftStatus {
  beforeShift,
  workingOnTime,
  absentDuringShift,
  leftEarly,
  overtime,
  leftWork,
  neverCame,
}

class EmployeeWorkHoursList extends StatefulWidget {
  const EmployeeWorkHoursList({
    Key? key,
    required this.employee,
    this.workingTimes,
  }) : super(key: key);

  final EmployeeEntity employee;
  final WorkingTimesEntity? workingTimes;

  @override
  State<EmployeeWorkHoursList> createState() => _EmployeeWorkHoursListState();
}

class _EmployeeWorkHoursListState extends State<EmployeeWorkHoursList> {
  final EmployeeSectionController controller =
      Get.find<EmployeeSectionController>();
  Timer? _timer;
  Duration _timerDuration = Duration.zero;
  _ShiftStatus _status = _ShiftStatus.beforeShift;

  WorkingTimesEntity? get _work => widget.workingTimes;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _update();
    });
  }

  @override
  void didUpdateWidget(covariant EmployeeWorkHoursList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workingTimes?.id != widget.workingTimes?.id ||
        oldWidget.workingTimes?.startWorkTime != _work?.startWorkTime ||
        oldWidget.workingTimes?.endWorkTime != _work?.endWorkTime) {
      _update();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime _parseTimeToday(String timeStr) {
    final now = DateTime.now();
    late DateFormat fmt;
    final upper = timeStr.toUpperCase();
    if (upper.contains('AM') || upper.contains('PM')) {
      fmt = DateFormat('h:mm a', 'en_US');
    } else if (timeStr.split(':').length == 3) {
      fmt = DateFormat('HH:mm:ss');
    } else {
      fmt = DateFormat('HH:mm');
    }
    final parsed = fmt.parse(timeStr);
    return DateTime(
      now.year,
      now.month,
      now.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    );
  }

  void _update() {
    final work = _work;
    if (work == null) return;
    try {
      final now = DateTime.now();
      final startTime = _parseTimeToday(work.startWorkTime);
      final endTime = _parseTimeToday(work.endWorkTime);
      final isWorking = work.isWorkingNow;

      late _ShiftStatus newStatus;
      late Duration newDuration;

      if (now.isBefore(startTime)) {
        newStatus = _ShiftStatus.beforeShift;
        newDuration = startTime.difference(now);
      } else if (now.isBefore(endTime)) {
        if (isWorking) {
          newStatus = _ShiftStatus.workingOnTime;
        } else if (work.hasAttendedToday) {
          newStatus = _ShiftStatus.leftEarly;
        } else {
          newStatus = _ShiftStatus.absentDuringShift;
        }
        newDuration = endTime.difference(now);
      } else {
        if (isWorking) {
          newStatus = _ShiftStatus.overtime;
          newDuration = now.difference(endTime);
        } else if (work.hasAttendedToday) {
          newStatus = _ShiftStatus.leftWork;
          newDuration = Duration.zero;
        } else {
          newStatus = _ShiftStatus.neverCame;
          newDuration = Duration.zero;
        }
      }

      setState(() {
        _status = newStatus;
        _timerDuration = newDuration;
      });
    } catch (_) {
      setState(() => _timerDuration = Duration.zero);
    }
  }

  void _openDetails() {
    controller.getEmployeeDetails(widget.employee.id.toString());
    Get.toNamed(
      AppRoutes.EMPLOYEEDETAILSSCREEN,
    );
  }

  void _openImageViewer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withAlpha(128),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return FullScreenZoomImage(imageUrl: widget.employee.employeeImg);
      },
    );
  }

  Future<void> _confirmImpersonate(BuildContext context) async {
    final isDark = ThemeService.isDark.value;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor:
            isDark ? AppColors.customGreyColor : const Color(0xFFF3F4F6),
        title: Text(
          'impersonateConfirmTitle'.tr,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        content: Text(
          'impersonateConfirmBody'.trParams({
            'name': widget.employee.employeeName,
          }),
          style: TextStyle(
            fontSize: 13.sp,
            color:
                isDark ? AppColors.customGreyColor5 : const Color(0xFF4B5563),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.operationalPurple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('impersonateConfirmAction'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await controller.impersonateEmployee(context, widget.employee);
    }
  }

  Future<void> _showActionsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _EmployeeActionsSheet(
        employee: widget.employee,
        onView: () {
          Navigator.of(ctx).pop();
          _openDetails();
        },
        onDelete: () async {
          Navigator.of(ctx).pop();
          final confirmed = await _confirmDelete(context);
          if (confirmed) {
            await controller.deleteEmployee(widget.employee.id.toString());
          }
        },
        onChangePassword: () {
          Navigator.of(ctx).pop();
          _showChangePasswordDialog(context);
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final isDark = ThemeService.isDark.value;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: isDark ? AppColors.customGreyColor : Colors.white,
        title: Text(
          'deleteEmployeeConfirmTitle'.tr,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'deleteEmployeeConfirmBody'.trParams({
            'name': widget.employee.employeeName,
          }),
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final isDark = ThemeService.isDark.value;
    controller.employeePasswordController.clear();
    controller.employeePasswordConfirmationController.clear();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: isDark ? AppColors.customGreyColor : Colors.white,
        title: Text(
          'changeEmployeePassword'.tr,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller.employeePasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'newPassword'.tr,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'requiredField'.tr;
                  if (text.length < 8) return 'passwordMinLength'.tr;
                  return null;
                },
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: controller.employeePasswordConfirmationController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'passwordConfirmation'.tr,
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'requiredField'.tr;
                  if (text != controller.employeePasswordController.text) {
                    return 'passwordMismatch'.tr;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          Obx(() {
            final busy = controller.isChangingEmployeePassword.value;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.operationalPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: busy
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      final ok = await controller.changeEmployeePassword(
                        widget.employee.id.toString(),
                      );
                      if (ok && ctx.mounted) Navigator.of(ctx).pop();
                    },
              child: busy
                  ? SizedBox(
                      width: 18.sp,
                      height: 18.sp,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('save'.tr),
            );
          }),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

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

  Color get _timerColor =>
      _status == _ShiftStatus.overtime ? Colors.yellow.shade200 : Colors.white;

  bool get _showTimer =>
      _status != _ShiftStatus.leftWork && _status != _ShiftStatus.neverCame;

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
      case _ShiftStatus.leftEarly:
        return 'لانتهاء الدوام';
      case _ShiftStatus.overtime:
        return 'وقت إضافي';
      case _ShiftStatus.leftWork:
      case _ShiftStatus.neverCame:
        return '';
    }
  }

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

  IconData get _employeeStatusIcon {
    switch (_status) {
      case _ShiftStatus.beforeShift:
        return Icons.schedule_rounded;
      case _ShiftStatus.workingOnTime:
        return Icons.login_rounded;
      case _ShiftStatus.absentDuringShift:
        return Icons.warning_amber_rounded;
      case _ShiftStatus.leftEarly:
        return Icons.directions_walk_rounded;
      case _ShiftStatus.overtime:
        return Icons.alarm_add_rounded;
      case _ShiftStatus.leftWork:
        return Icons.logout_rounded;
      case _ShiftStatus.neverCame:
        return Icons.person_off_rounded;
    }
  }

  String _pointsLabel() {
    final summary = widget.employee.pointsSummary;
    if (summary == null) return 'employeeNoPoints'.tr;
    return '${summary.netPoints} ${'employeePointsBadgeUnit'.tr}';
  }

  String? _rewardStatusLabel() {
    final label = widget.employee.pointsSummary?.rewardStatusLabel;
    if (label == null || label.isEmpty) return null;
    return label;
  }

  Color _pointsColor() {
    final color = _parseHex(widget.employee.pointsSummary?.rewardStatusColor);
    if (color != null) return color;
    final net = widget.employee.pointsSummary?.netPoints;
    if (net == null || net > 0) return AppColors.customGreen1;
    if (net < 0) return const Color(0xFFDC2626);
    return const Color(0xFF9CA3AF);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    final work = _work;
    return InkWell(
      onTap: _openDetails,
      onLongPress: () => _showActionsSheet(context),
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: work == null ? 0 : 72.w),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context),
                    child: SizedBox(
                      height: 58.h,
                      width: 58.w,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration:
                                  const BoxDecoration(shape: BoxShape.circle),
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
                                fadeInDuration:
                                    const Duration(milliseconds: 200),
                                fadeOutDuration:
                                    const Duration(milliseconds: 200),
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            end: -1.w,
                            bottom: 1.h,
                            child: _WifiStatusDot(
                              employee: widget.employee,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                          if (work?.isCameOnTime ??
                              widget.employee.isCameOnTime)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18.sp,
                              ),
                            ),
                        ],
                      ),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 3.h,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _InlineChip(
                            label: _pointsLabel(),
                            color: _pointsColor(),
                            icon: Icons.stars_rounded,
                          ),
                          if (_rewardStatusLabel() != null)
                            _IconChip(
                              tooltip: _rewardStatusLabel()!,
                              color: _pointsColor(),
                              icon: Icons.redeem_rounded,
                            ),
                          if (work != null)
                            _IconChip(
                              tooltip: _employeeStatusText,
                              color: _employeeStatusColor,
                              icon: _employeeStatusIcon,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (ImpersonationService.canImpersonateEmployees)
                  Obx(() {
                    if (!controller.canShowImpersonateFor(widget.employee.id)) {
                      return const SizedBox.shrink();
                    }
                    final busy = controller.impersonatingEmployeeId.value ==
                        widget.employee.id;
                    return Padding(
                      padding: EdgeInsets.only(top: 24.h),
                      child: Tooltip(
                        message: 'impersonateEmployee'.tr,
                        child: InkResponse(
                          onTap:
                              busy ? null : () => _confirmImpersonate(context),
                          radius: 15.r,
                          child: SizedBox(
                            width: 28.w,
                            height: 28.h,
                            child: Center(
                              child: busy
                                  ? SizedBox(
                                      width: 16.sp,
                                      height: 16.sp,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.switch_account_rounded,
                                      color: AppColors.operationalPurple,
                                      size: 17.sp,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
            if (work != null) ...[
              PositionedDirectional(
                top: 0,
                end: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MiniActionButton(
                        icon: Icons.history,
                        tooltip: 'employeeAttendanceHistory'.tr,
                        onTap: () => Get.toNamed(
                          AppRoutes.EMPLOYEEATTENDANCEHISTORY,
                          arguments: {
                            'employeeId': work.id.toString(),
                            'employeeName': work.employeeName,
                          },
                        ),
                      ),
                      _MiniActionButton(
                        icon: Icons.assignment_outlined,
                        tooltip: 'attendanceReportAction'.tr,
                        onTap: () => Get.toNamed(
                          AppRoutes.EMPLOYEEATTENDANCEHISTORY,
                          arguments: {
                            'employeeId': work.id.toString(),
                            'employeeName': work.employeeName,
                            'reportMode': true,
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: -72.w,
                child: _ShiftTimerBox(
                  boxColor: _boxColor,
                  timerColor: _timerColor,
                  statusLabel: _statusLabel,
                  showTimer: _showTimer,
                  timerText: _formatDuration(_timerDuration),
                  timerLabel: _timerLabel,
                  status: _status,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineChip extends StatelessWidget {
  const _InlineChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: color),
          SizedBox(width: 3.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.tooltip,
    required this.color,
    required this.icon,
  });

  final String tooltip;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 22.w,
        height: 22.h,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(color: color, width: 0.5),
        ),
        child: Icon(icon, size: 13.sp, color: color),
      ),
    );
  }
}

class _WifiStatusDot extends StatelessWidget {
  const _WifiStatusDot({required this.employee});

  final EmployeeEntity employee;

  @override
  Widget build(BuildContext context) {
    final state = employee.wifiPresenceState;
    final color = state == 'green'
        ? const Color(0xFF16A34A)
        : state == 'orange'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFDC2626);
    final ssid = employee.wifiSsid?.trim();
    final message = state == 'green'
        ? (ssid == null || ssid.isEmpty
            ? 'متصل بشبكة العمل'
            : 'متصل بشبكة العمل: $ssid')
        : state == 'orange'
            ? (ssid == null || ssid.isEmpty
                ? 'متصل بشبكة أخرى'
                : 'متصل بشبكة أخرى: $ssid')
            : 'غير متصل بالإنترنت الآن';

    return Tooltip(
      message: message,
      child: Container(
        width: 17.w,
        height: 17.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4.r,
              offset: Offset(0, 1.h),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftTimerBox extends StatelessWidget {
  const _ShiftTimerBox({
    required this.boxColor,
    required this.timerColor,
    required this.statusLabel,
    required this.showTimer,
    required this.timerText,
    required this.timerLabel,
    required this.status,
  });

  final Color boxColor;
  final Color timerColor;
  final String statusLabel;
  final bool showTimer;
  final String timerText;
  final String timerLabel;
  final _ShiftStatus status;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return Container(
      width: 72.w,
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadiusDirectional.only(
          topEnd: Radius.circular(4.r),
          bottomEnd: Radius.circular(4.r),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == _ShiftStatus.leftWork
                ? Icons.logout
                : status == _ShiftStatus.beforeShift
                    ? Icons.access_time
                    : status == _ShiftStatus.overtime
                        ? Icons.alarm_add
                        : status == _ShiftStatus.absentDuringShift
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
            color: timerColor,
            size: 12.sp,
          ),
          SizedBox(height: 1.h),
          Text(
            statusLabel,
            textAlign: TextAlign.center,
            style: textStyle.copyWith(
              fontSize: 7.sp,
              fontWeight: FontWeight.bold,
              color: timerColor,
            ),
          ),
          SizedBox(height: 1.h),
          if (showTimer)
            Text(
              timerText,
              textAlign: TextAlign.center,
              style: textStyle.copyWith(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: timerColor,
              ),
            ),
          if (timerLabel.isNotEmpty && showTimer)
            Text(
              timerLabel,
              textAlign: TextAlign.center,
              style: textStyle.copyWith(
                fontSize: 7.sp,
                color: timerColor.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmployeeActionsSheet extends StatelessWidget {
  const _EmployeeActionsSheet({
    required this.employee,
    required this.onView,
    required this.onDelete,
    required this.onChangePassword,
  });

  final EmployeeEntity employee;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final sheetColor = isDark ? AppColors.customGreyColor : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 46.w,
                      height: 46.w,
                      child: CachedNetworkImage(
                        imageUrl: employee.employeeImg,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(Icons.person),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.employeeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'employeeActionsHint'.tr,
                          style: TextStyle(fontSize: 11.sp, color: subColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Divider(
              height: 1.h,
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
            ),
            _ActionTile(
              icon: Icons.person_outline_rounded,
              label: 'viewEmployee'.tr,
              color: isDark ? AppColors.primaryColor : AppColors.secondaryColor,
              onTap: onView,
            ),
            if (canManageEmployeesPasswords)
              _ActionTile(
                icon: Icons.lock_reset_rounded,
                label: 'changeEmployeePassword'.tr,
                color: AppColors.operationalPurple,
                onTap: onChangePassword,
              ),
            if (canDeleteEmployees)
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                label: 'deleteEmployeeAction'.tr,
                color: const Color(0xFFDC2626),
                onTap: onDelete,
              ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: Icon(icon, color: color, size: 20.sp),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: color.withValues(alpha: 0.6),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 16.r,
        child: SizedBox(
          width: 26.w,
          height: 28.h,
          child: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 16.sp,
          ),
        ),
      ),
    );
  }
}

Color? _parseHex(String? input) {
  if (input == null) return null;
  var s = input.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final value = int.tryParse(s, radix: 16);
  if (value == null) return null;
  return Color(value);
}
