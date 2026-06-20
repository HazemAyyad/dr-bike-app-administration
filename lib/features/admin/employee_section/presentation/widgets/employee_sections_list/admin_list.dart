import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../data/models/admin_user_model.dart';
import '../../controllers/employee_section_controller.dart';

class AdminList extends GetView<EmployeeSectionController> {
  const AdminList({Key? key, required this.admin}) : super(key: key);

  final AdminUserModel admin;

  Future<void> _showActions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminActionsSheet(
        admin: admin,
        onEdit: () {
          Navigator.of(ctx).pop();
          Get.toNamed(
            AppRoutes.ADDEDITADMINSCREEN,
            arguments: {'isEdit': true, 'admin': admin},
          );
        },
        onToggleBlock: () async {
          Navigator.of(ctx).pop();
          await controller.toggleAdminBlock(admin.id.toString());
        },
        onDelete: () async {
          Navigator.of(ctx).pop();
          final confirmed = await _confirmDelete(context);
          if (confirmed) {
            await controller.deleteAdmin(admin.id.toString());
          }
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final isDark = ThemeService.isDark.value;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor:
                isDark ? AppColors.customGreyColor : AppColors.whiteColor,
            title: Text('areYouSure'.tr),
            content: Text('deleteAdminConfirm'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'delete'.tr,
                  style: const TextStyle(color: AppColors.redColor),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;

    return InkWell(
      onLongPress: () => _showActions(context),
      onTap: () => Get.toNamed(
        AppRoutes.ADDEDITADMINSCREEN,
        arguments: {'isEdit': true, 'admin': admin},
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
          children: [
            _StatusDot(isOnline: admin.isOnline, isBlocked: admin.isBlocked),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.whiteColor
                          : AppColors.operationalNavy,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    admin.email,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Badge(
                  label: admin.isBlocked
                      ? 'blocked'.tr
                      : admin.isOnline
                          ? 'online'.tr
                          : 'offline'.tr,
                  color: admin.isBlocked
                      ? AppColors.redColor
                      : admin.isOnline
                          ? AppColors.customGreen1
                          : AppColors.customGreyColor5,
                ),
                if (admin.activeSessionsCount > 0) ...[
                  SizedBox(height: 4.h),
                  Text(
                    '${admin.activeSessionsCount} ${'sessions'.tr}',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isOnline, required this.isBlocked});

  final bool isOnline;
  final bool isBlocked;

  @override
  Widget build(BuildContext context) {
    final color = isBlocked
        ? AppColors.redColor
        : isOnline
            ? AppColors.customGreen1
            : AppColors.customGreyColor5;

    return Container(
      width: 10.r,
      height: 10.r,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _AdminActionsSheet extends StatelessWidget {
  const _AdminActionsSheet({
    required this.admin,
    required this.onEdit,
    required this.onToggleBlock,
    required this.onDelete,
  });

  final AdminUserModel admin;
  final VoidCallback onEdit;
  final VoidCallback onToggleBlock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text('edit'.tr),
            onTap: onEdit,
          ),
          ListTile(
            leading: Icon(
              admin.isBlocked ? Icons.lock_open_outlined : Icons.block_outlined,
              color: admin.isBlocked ? AppColors.customGreen1 : AppColors.redColor,
            ),
            title: Text(admin.isBlocked ? 'unblock'.tr : 'block'.tr),
            onTap: onToggleBlock,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.redColor),
            title: Text('delete'.tr, style: const TextStyle(color: AppColors.redColor)),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
