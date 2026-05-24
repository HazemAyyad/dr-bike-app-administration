import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/impersonation_service.dart';
import '../../../../../core/utils/app_colors.dart';

/// Shown on employee dashboard when admin is viewing as employee.
class ImpersonationExitButton extends StatefulWidget {
  const ImpersonationExitButton({Key? key}) : super(key: key);

  @override
  State<ImpersonationExitButton> createState() => _ImpersonationExitButtonState();
}

class _ImpersonationExitButtonState extends State<ImpersonationExitButton> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final active = await ImpersonationService.isActive;
    if (mounted) setState(() => _visible = active);
    if (active) await ImpersonationService.loadAdminNameIfImpersonating();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Material(
        color: AppColors.operationalPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: () async {
            await ImpersonationService.exitToAdmin();
          },
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.operationalPurple,
                  size: 20.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  'exitImpersonation'.tr,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.operationalPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
