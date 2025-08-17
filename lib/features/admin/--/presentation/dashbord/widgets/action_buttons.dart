import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/initial_bindings.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../controllers/dashboard_controller.dart';

class BuildActionButtons extends StatelessWidget {
  const BuildActionButtons({Key? key, required this.controller})
      : super(key: key);

  final DashboardController controller;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.3.h,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 13.h,
          ),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: test == 'admin'
              ? controller.buttons.length
              : controller.buttons
                  .where(
                      (x) => employeePermissions.contains(int.parse(x['id'])))
                  .length,
          itemBuilder: (context, index) {
            final filteredButtons = test == 'admin'
                ? controller.buttons
                : controller.buttons
                    .where(
                        (x) => employeePermissions.contains(int.parse(x['id'])))
                    .toList();

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
}

// بناء زر وظيفة واحد
Widget _buildActionButton(String title, String route) {
  return GestureDetector(
    onTap: () {
      // print(route);
      route == '' ? null : Get.toNamed(route);
    },
    child: Container(
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
