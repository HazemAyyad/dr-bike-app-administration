import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/full_screen_image_viewer.dart';
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
      arguments: employee.points,
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
        onDelete: () async {
          Navigator.of(ctx).pop();
          final confirmed = await _confirmDelete(context);
          if (confirmed) {
            await controller.deleteEmployee(employee.id.toString());
          }
        },
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
          'impersonateConfirmBody'
              .trParams({'name': employee.employeeName}),
          style: TextStyle(
            fontSize: 13.sp,
            color: isDark ? AppColors.customGreyColor5 : const Color(0xFF4B5563),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'cancel'.tr,
              style: TextStyle(
                color: isDark ? AppColors.customGreyColor5 : const Color(0xFF6B7280),
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
          'deleteEmployeeConfirmBody'
              .trParams({'name': employee.employeeName}),
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
                      child: Container(
                        height: 80.h,
                        width: 80.w,
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
                          fadeInDuration: const Duration(milliseconds: 200),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
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
          Obx(() {
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

class _EmployeeActionsSheet extends StatelessWidget {
  const _EmployeeActionsSheet({
    required this.employee,
    required this.onView,
    required this.onDelete,
  });

  final EmployeeEntity employee;
  final VoidCallback onView;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final sheetColor =
        isDark ? AppColors.customGreyColor : Colors.white;
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
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.person),
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
              color: isDark
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
              onTap: onView,
            ),
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
    if (net == null) return '${employee.points} ${'point'.tr}';
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
