import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/services/impersonation_service.dart';
import '../../../../../../core/services/initial_bindings.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../domain/entities/employee_entity.dart';
import '../../controllers/employee_section_controller.dart';

class EmployeeList extends GetView<EmployeeSectionController> {
  const EmployeeList({Key? key, required this.employee}) : super(key: key);

  final EmployeeEntity employee;

  void _openDetails() {
    controller.getEmployeeDetails(employee.id.toString());
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
        return FullScreenZoomImage(imageUrl: employee.employeeImg);
      },
    );
  }

  Future<void> _showActionsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _EmployeeActionsSheet(
        employee: employee,
        onView: () {
          Navigator.of(ctx).pop();
          _openDetails();
        },
        onWhatsApp: () async {
          Navigator.of(ctx).pop();
          await _openWhatsApp(context);
        },
        onDelete: () async {
          Navigator.of(ctx).pop();
          final confirmed = await _confirmDelete(context);
          if (confirmed) {
            await controller.deleteEmployee(employee.id.toString());
          }
        },
        onSuspend: () async {
          Navigator.of(ctx).pop();
          final confirmed = await _confirmSuspend(context);
          if (confirmed) {
            await controller.suspendEmployee(employee.id.toString());
          }
        },
        onRestore: () async {
          Navigator.of(ctx).pop();
          final confirmed = await _confirmRestore(context);
          if (confirmed) {
            await controller.restoreSuspendedEmployee(employee.id.toString());
          }
        },
        onChangePassword: () {
          Navigator.of(ctx).pop();
          _showChangePasswordDialog(context);
        },
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    await controller.getEmployeeDetails(employee.id.toString());
    final details = controller.employeeService.employeeDetails.value;
    if (details == null || details.id != employee.id) return;

    final primaryPhone = details.phone.replaceAll(' ', '');
    final alternatePhone = details.subPhone.replaceAll(' ', '');
    final rawPhone = primaryPhone.isNotEmpty ? primaryPhone : alternatePhone;
    var digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = '972${digits.substring(1)}';

    final isSupportedNumber =
        (digits.startsWith('970') || digits.startsWith('972')) &&
            digits.length >= 11;
    if (!isSupportedNumber) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الموظف غير صالح للتواصل عبر واتساب')),
      );
      return;
    }

    final opened = await launchUrl(
      Uri.https('wa.me', '/$digits'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح واتساب على هذا الجهاز')),
      );
    }
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
          Obx(
            () {
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
                          employee.id.toString(),
                        );
                        if (ok && ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
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
            },
          ),
        ],
      ),
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
          'impersonateConfirmBody'.trParams({'name': employee.employeeName}),
          style: TextStyle(
            fontSize: 13.sp,
            color:
                isDark ? AppColors.customGreyColor5 : const Color(0xFF4B5563),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'cancel'.tr,
              style: TextStyle(
                color: isDark
                    ? AppColors.customGreyColor5
                    : const Color(0xFF6B7280),
              ),
            ),
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
      await controller.impersonateEmployee(context, employee);
    }
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
          'deleteEmployeeConfirmBody'.trParams({'name': employee.employeeName}),
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

  Future<bool> _confirmSuspend(BuildContext context) async {
    return _confirmStatusChange(
      context,
      title: 'suspendEmployeeConfirmTitle'.tr,
      body: 'suspendEmployeeConfirmBody'.trParams({
        'name': employee.employeeName,
      }),
      action: 'suspendEmployeeAction'.tr,
      color: const Color(0xFFF97316),
    );
  }

  Future<bool> _confirmRestore(BuildContext context) async {
    return _confirmStatusChange(
      context,
      title: 'restoreEmployeeConfirmTitle'.tr,
      body: 'restoreEmployeeConfirmBody'.trParams({
        'name': employee.employeeName,
      }),
      action: 'restoreEmployeeAction'.tr,
      color: const Color(0xFF16A34A),
    );
  }

  Future<bool> _confirmStatusChange(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    required Color color,
  }) async {
    final isDark = ThemeService.isDark.value;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: isDark ? AppColors.customGreyColor : Colors.white,
        title: Text(
          title,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
        ),
        content: Text(body, style: TextStyle(fontSize: 13.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return InkWell(
      onTap: _openDetails,
      onLongPress: () => _showActionsSheet(context),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: GestureDetector(
                      onTap: () => _openImageViewer(context),
                      child: SizedBox(
                        height: 80.h,
                        width: 80.w,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  cacheManager: CacheManager(
                                    Config(
                                      'imagesCache',
                                      stalePeriod: const Duration(days: 7),
                                      maxNrOfCacheObjects: 100,
                                    ),
                                  ),
                                  imageUrl: employee.employeeImg,
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
                              end: 3.w,
                              bottom: 5.h,
                              child: _WifiStatusDot(employee: employee),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              employee.employeeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.customGreyColor5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${'hourlyRate'.tr} : ${employee.hourWorkPrice} ${'currency'.tr}',
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
          if (ImpersonationService.canImpersonateEmployees)
            Obx(() {
              if (!controller.canShowImpersonateFor(employee.id)) {
                return const SizedBox.shrink();
              }
              final busy =
                  controller.impersonatingEmployeeId.value == employee.id;
              return IconButton(
                tooltip: 'impersonateEmployee'.tr,
                onPressed: busy ? null : () => _confirmImpersonate(context),
                icon: busy
                    ? SizedBox(
                        width: 22.sp,
                        height: 22.sp,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.switch_account_rounded,
                        color: AppColors.operationalPurple,
                        size: 22.sp,
                      ),
              );
            }),
          _PointsBadge(employee: employee),
        ],
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
    final connected = state == 'green';
    final otherNetwork = state == 'orange';
    final color = connected
        ? const Color(0xFF16A34A)
        : otherNetwork
            ? const Color(0xFFF59E0B)
            : const Color(0xFFDC2626);
    final ssid = employee.wifiSsid?.trim();
    final message = connected
        ? (ssid == null || ssid.isEmpty
            ? 'متصل بشبكة العمل'
            : 'متصل بشبكة العمل: $ssid')
        : otherNetwork
            ? (ssid == null || ssid.isEmpty
                ? 'متصل بشبكة أخرى'
                : 'متصل بشبكة أخرى: $ssid')
            : 'غير متصل بالإنترنت الآن';

    return Tooltip(
      message: message,
      child: Container(
        width: 16.w,
        height: 16.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 4.r,
              offset: Offset(0, 1.h),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeActionsSheet extends StatelessWidget {
  const _EmployeeActionsSheet({
    required this.employee,
    required this.onView,
    required this.onWhatsApp,
    required this.onDelete,
    required this.onSuspend,
    required this.onRestore,
    required this.onChangePassword,
  });

  final EmployeeEntity employee;
  final VoidCallback onView;
  final VoidCallback onWhatsApp;
  final VoidCallback onDelete;
  final VoidCallback onSuspend;
  final VoidCallback onRestore;
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
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: subColor,
                          ),
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
            _ActionTile(
              icon: Icons.chat_rounded,
              label: 'تواصل واتساب',
              color: const Color(0xFF25D366),
              onTap: onWhatsApp,
            ),
            if (canManageEmployeesPasswords)
              _ActionTile(
                icon: Icons.lock_reset_rounded,
                label: 'changeEmployeePassword'.tr,
                color: AppColors.operationalPurple,
                onTap: onChangePassword,
              ),
            if (canDeleteEmployees && !employee.isSuspended)
              _ActionTile(
                icon: Icons.pause_circle_outline_rounded,
                label: 'suspendEmployeeAction'.tr,
                color: const Color(0xFFF97316),
                onTap: onSuspend,
              ),
            if (canDeleteEmployees && employee.isSuspended)
              _ActionTile(
                icon: Icons.play_circle_outline_rounded,
                label: 'restoreEmployeeAction'.tr,
                color: const Color(0xFF16A34A),
                onTap: onRestore,
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

/// Renders the live monthly net points + reward status colour for an
/// employee. Falls back to grey when the backend did not include a
/// `points_summary` (older API), or red/grey for negative/zero values.
class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.employee});

  final EmployeeEntity employee;

  Color _resolveColor() {
    final color = _parseHex(employee.pointsSummary?.rewardStatusColor);
    if (color != null) return color;
    final net = employee.pointsSummary?.netPoints;
    if (net == null) return AppColors.customGreen1;
    if (net < 0) return const Color(0xFFDC2626);
    if (net == 0) return const Color(0xFF9CA3AF);
    return AppColors.customGreen1;
  }

  String _label() {
    final net = employee.pointsSummary?.netPoints;
    if (net == null) return 'employeeNoPoints'.tr;
    return '$net ${'employeePointsBadgeUnit'.tr}';
  }

  String? _tooltip() {
    final s = employee.pointsSummary;
    if (s == null) return null;
    return [
      '${'totalNet'.tr}: ${s.netPoints}',
      '${'totalReward'.tr}: ${s.rewardAmount} ${'currency'.tr}',
      if (s.rewardStatusLabel != null && s.rewardStatusLabel!.isNotEmpty)
        '${'rewardStatus'.tr}: ${s.rewardStatusLabel}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();
    final tooltip = _tooltip();

    final badge = Container(
      width: 78.w,
      height: 85.h,
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadiusDirectional.only(
          topEnd: Radius.circular(4.r),
          bottomEnd: Radius.circular(4.r),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _label(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          if (employee.pointsSummary?.rewardStatusLabel != null &&
              employee.pointsSummary!.rewardStatusLabel!.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              employee.pointsSummary!.rewardStatusLabel!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ],
        ],
      ),
    );

    if (tooltip == null) return badge;
    return Tooltip(message: tooltip, child: badge);
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
