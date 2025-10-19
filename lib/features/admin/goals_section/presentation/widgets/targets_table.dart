// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';

// import '../../../../../core/services/theme_service.dart';
// import '../../../../../core/utils/app_colors.dart';
// import '../../../../my_orders/widgets/row_text.dart';

// Container targetsTable(BuildContext context, controller) {
//   return Container(
//     height: 32.h,
//     decoration: BoxDecoration(
//       color: ThemeService.isDark.value
//           ? AppColors.secondaryColor
//           : AppColors.primaryColor,
//       borderRadius: BorderRadius.circular(6.r),
//     ),
//     child: Obx(
//       () => Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           // SizedBox(),
//           rowText(context, 'targetName'),
//           // SizedBox(),
//           if (controller.currentTab.value == 2) rowText(context, 'targetType'),
//           rowText(context, 'completionPercentage'),
//           rowText(context, 'targetValue'),
//         ],
//       ),
//     ),
//   );
// }
