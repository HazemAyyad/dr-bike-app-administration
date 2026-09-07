import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/theme_service.dart';
import '../../../core/utils/app_colors.dart';

class BuildNavItem extends StatelessWidget {
  const BuildNavItem({
    Key? key,
    required this.isSelected,
    required this.onTap,
    required this.assetImage,
    required this.label,
  }) : super(key: key);

  final bool isSelected;
  final void Function() onTap;
  final String assetImage;
  final String label;

  @override
  Widget build(BuildContext context) {
    final iconSize = 24.w;
    final iconColor = isSelected
        ? AppColors.operationalPurple
        : ThemeService.isDark.value
            ? AppColors.whiteColor2
            : const Color(0xFF8792AD);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: Image.asset(
                assetImage,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                color: iconColor,
                filterQuality: FilterQuality.medium,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: iconColor,
                    fontSize: 10.sp,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
