import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/services/theme_service.dart';
import 'dashboard_design_tokens.dart';

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    Key? key,
    required this.title,
    required this.icon,
    this.action,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final dark = ThemeService.isDark.value;
    return Row(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: DashboardDesignTokens.primary,
        ),
        SizedBox(width: 7.w),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DashboardDesignTokens.textPrimaryFor(dark),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        if (action != null) ...[
          SizedBox(width: 8.w),
          action!,
        ],
      ],
    );
  }
}
