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
  }) : super(key: key);

  final List<Map<String, dynamic>> buttons;
  final List<int>? employeePermissions;
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
            return _buildActionButton(
              filteredButtons[index]['title'],
              filteredButtons[index]['route'],
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

    final id = int.tryParse(button['id']?.toString() ?? '');
    return id != null && permissions.contains(id);
  }
}

// بناء زر وظيفة واحد
Widget _buildActionButton(String title, String route) {
  return GestureDetector(
    onTap: () {
      // print(route);
      route == '' ? null : Get.toNamed(route);
    },
    child: Container(
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
  );
}
