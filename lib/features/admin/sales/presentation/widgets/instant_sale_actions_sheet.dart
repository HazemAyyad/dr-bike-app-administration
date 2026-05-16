import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/instant_sales_model.dart';

class InstantSaleActionsSheet extends StatelessWidget {
  const InstantSaleActionsSheet({
    Key? key,
    required this.sale,
    required this.onViewInvoice,
    required this.onEdit,
    required this.onCancel,
  }) : super(key: key);

  final InstantSalesModel sale;
  final VoidCallback onViewInvoice;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final sheetBg = isDark ? const Color(0xFF1F1F23) : const Color(0xFFF5F6F8);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Text(
              sale.product,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '${'total'.tr}: ${sale.totalCost} ${'currency'.tr}',
              style: TextStyle(fontSize: 12.sp, color: subColor),
            ),
            SizedBox(height: 12.h),
            Divider(
              height: 1.h,
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
            ),
            _ActionTile(
              icon: Icons.receipt_long_outlined,
              label: 'billDetails'.tr,
              color: isDark ? AppColors.primaryColor : AppColors.secondaryColor,
              onTap: onViewInvoice,
            ),
            if (!sale.isCancelled) ...[
              _ActionTile(
                icon: Icons.edit_outlined,
                label: 'editInstantSale'.tr,
                color: AppColors.primaryColor,
                onTap: onEdit,
              ),
              _ActionTile(
                icon: Icons.undo_rounded,
                label: 'cancelInstantSale'.tr,
                color: const Color(0xFFDC2626),
                onTap: onCancel,
              ),
            ],
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
    final isDark = ThemeService.isDark.value;

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
          color: isDark ? Colors.white : color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: (isDark ? Colors.white54 : color.withValues(alpha: 0.6)),
      ),
    );
  }
}
