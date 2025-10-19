// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';

// import '../../../../../core/utils/app_colors.dart';
// import '../../../../../routes/app_routes.dart';

// Expanded viewTargets(controller) {
//   return Expanded(
//     child: Obx(
//       () => AnimatedSwitcher(
//         duration: const Duration(milliseconds: 200),
//         child: ListView.builder(
//           key: ValueKey<int>(controller.currentTab.value),
//           itemCount: controller.targets.length,
//           itemBuilder: (context, index) {
//             final order = controller.targets[index];
//             return Column(
//               children: [
//                 InkWell(
//                   overlayColor: WidgetStateProperty.all(Colors.transparent),
//                   onTap: () {
//                     // Handle order card tap
//                     Get.toNamed(
//                       AppRoutes.TARGETDETAILSSCREEN,
//                       arguments: order,
//                     );
//                   },
//                   child: SizedBox(
//                     height: 35.h,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         Flexible(
//                           child: SizedBox(
//                             width: 70.w,
//                             child: Text(
//                               order['targetName'],
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               textAlign: TextAlign.center,
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodyMedium!
//                                   .copyWith(
//                                     fontSize: 11.sp,
//                                     fontWeight: FontWeight.w400,
//                                     color: AppColors.customGreyColor5,
//                                   ),
//                             ),
//                           ),
//                         ),
//                         if (Get.locale!.languageCode == 'en') const SizedBox(),
//                         if (controller.currentTab.value == 2)
//                           Text(
//                             order['targetType'],
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             textAlign: TextAlign.center,
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .bodyMedium!
//                                 .copyWith(
//                                   fontSize: 11.sp,
//                                   fontWeight: FontWeight.w400,
//                                   color: AppColors.customGreyColor5,
//                                 ),
//                           ),
//                         if (controller.currentTab.value == 2) const SizedBox(),
//                         Text(
//                           '${order['completionPercentage']}%',
//                           style:
//                               Theme.of(context).textTheme.bodyMedium!.copyWith(
//                                     fontSize: 11.sp,
//                                     fontWeight: FontWeight.w400,
//                                     color: AppColors.customGreyColor5,
//                                   ),
//                         ),
//                         const SizedBox(),
//                         Text(
//                           '${order['targetValue']} ${'currency'.tr}',
//                           style:
//                               Theme.of(context).textTheme.bodyMedium!.copyWith(
//                                     fontSize: 11.sp,
//                                     fontWeight: FontWeight.w400,
//                                     color: AppColors.customGreyColor5,
//                                   ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Divider(
//                     color: const Color.fromRGBO(217, 217, 217, 1),
//                     thickness: 1.h),
//               ],
//             );
//           },
//         ),
//       ),
//     ),
//   );
// }
