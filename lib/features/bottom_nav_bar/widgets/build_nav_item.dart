import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/theme_service.dart';
import '../../../core/utils/app_colors.dart';

class BuildNavItem extends StatelessWidget {
  const BuildNavItem({
    Key? key,
    required this.isSelected,
    required this.onTap,
    this.assetImage,
    this.icon,
    required this.label,
  })  : assert(assetImage != null || icon != null),
        super(key: key);

  final bool isSelected;
  final void Function() onTap;
  final String? assetImage;
  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final iconSize = 22.w;
    final isDark = ThemeService.isDark.value;
    final iconColor = isSelected
        ? (isDark ? const Color(0xFFC7C2FF) : AppColors.operationalPurple)
        : (isDark ? const Color(0xFFE4E4EC) : const Color(0xFF667085));

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 5.h),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.operationalPurple.withValues(
                        alpha: isDark ? .28 : .10,
                      )
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: icon != null
                        ? Icon(icon, size: iconSize, color: iconColor)
                        : Image.asset(
                            assetImage!,
                            width: iconSize,
                            height: iconSize,
                            fit: BoxFit.contain,
                            color: iconColor,
                            filterQuality: FilterQuality.medium,
                          ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: iconColor,
                          fontSize: 9.sp,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
