import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';

class BuildActionButtons extends StatelessWidget {
  const BuildActionButtons({
    Key? key,
    required this.buttons,
    this.employeePermissions,
    this.badges = const {},
  }) : super(key: key);

  final List<Map<String, dynamic>> buttons;
  final List<int>? employeePermissions;
  final Map<String, int> badges;
  @override
  Widget build(BuildContext context) {
    final filteredButtons = userType == 'admin'
        ? buttons
        : buttons
            .where((x) => _canShowButton(x, employeePermissions ?? const []))
            .toList();

    return Column(
      children: [
        SizedBox(height: 5.h),
        Row(
          children: [
            Text(
              'permissions'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.secondaryColor,
                  ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.h,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 13.h,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredButtons.length,
          itemBuilder: (context, index) {
            final button = filteredButtons[index];
            final badgeDescriptors = (button['badgeDescriptors'] as List?)
                    ?.whereType<Map>()
                    .map((item) => _ActionBadge.fromMap(item, badges))
                    .where((item) => item.count > 0)
                    .toList(growable: false) ??
                const <_ActionBadge>[];

            return _buildActionButton(
              button['title'],
              button['route'],
              badges[button['badgeKey']?.toString() ?? ''] ?? 0,
              badgeDescriptors,
            );
          },
        ),

        // زر المصاريف والأمور المالية (عرض كامل)
        // Container(
        //   height: 45.h,
        //   decoration: BoxDecoration(
        //     color: AppColors.primaryColor,
        //     borderRadius: BorderRadius.circular(10.r),
        //   ),
        //   child: Center(
        //     child: Text(
        //       'financialMatters'.tr,
        //       style: Theme.of(context).textTheme.bodyMedium!.copyWith(
        //             color: Colors.white,
        //             fontSize: 14.sp,
        //             fontWeight: FontWeight.w700,
        //           ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  bool _canShowButton(Map<String, dynamic> button, List<int> permissions) {
    final route = button['route'];
    if (route == AppRoutes.GENERALSETTINGSSCREEN) {
      return canManageStockInventorySettings;
    }
    if (route == AppRoutes.MYEMPLOYEESUGGESTIONSSCREEN) {
      return true;
    }
    if (route == AppRoutes.TECHNICALSUPPORT) {
      return true;
    }

    final id = int.tryParse(button['id']?.toString() ?? '');
    return id != null && permissions.contains(id);
  }
}

class _ActionBadge {
  const _ActionBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  factory _ActionBadge.fromMap(Map item, Map<String, int> badges) {
    final key = item['key']?.toString() ?? '';
    final colorName = item['color']?.toString() ?? '';

    return _ActionBadge(
      label: item['label']?.toString() ?? '',
      count: badges[key] ?? 0,
      color:
          colorName == 'yellow' ? AppColors.customOrange3 : AppColors.redColor,
    );
  }
}

// بناء زر وظيفة واحد
Widget _buildActionButton(
  String title,
  String route,
  int badge,
  List<_ActionBadge> badgeDescriptors,
) {
  return GestureDetector(
    onTap: () {
      // print(route);
      route == '' ? null : Get.toNamed(route);
    },
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (badgeDescriptors.isNotEmpty)
          PositionedDirectional(
            top: -8.h,
            end: -6.w,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showBadgeDetails(title, badgeDescriptors),
              child: _buildBadgeDetailsButton(badgeDescriptors),
            ),
          ),
        if (badge > 0)
          PositionedDirectional(
            top: -7.h,
            end: -7.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              constraints: BoxConstraints(minWidth: 20.w, minHeight: 20.w),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildBadgeDetailsButton(List<_ActionBadge> badges) {
  final total = badges.fold<int>(0, (sum, item) => sum + item.count);

  return Container(
    height: 22.h,
    padding: EdgeInsets.symmetric(horizontal: 7.w),
    constraints: BoxConstraints(minWidth: 28.w),
    decoration: BoxDecoration(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white, width: 1.4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Center(
      child: Text(
        total > 99 ? '+99' : '+$total',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    ),
  );
}

void _showBadgeDetails(String title, List<_ActionBadge> badges) {
  Get.dialog(
    Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title.tr,
              textAlign: TextAlign.center,
              style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryColor,
                  ),
            ),
            SizedBox(height: 12.h),
            ...badges.map(_buildBadgeDetailsRow),
            SizedBox(height: 8.h),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: Get.back,
                child: Text(
                  'close'.tr,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildBadgeDetailsRow(_ActionBadge badge) {
  final textColor = badge.color == AppColors.customOrange3
      ? AppColors.secondaryColor
      : Colors.white;

  return Padding(
    padding: EdgeInsets.only(bottom: 7.h),
    child: Row(
      children: [
        Container(
          constraints: BoxConstraints(minWidth: 42.w),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: badge.color,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badge.count > 99 ? '99+' : '${badge.count}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: Text(
            badge.label,
            style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.secondaryColor,
                ),
          ),
        ),
      ],
    ),
  );
}
