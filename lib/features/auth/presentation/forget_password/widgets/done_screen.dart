// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';

// import '../../../core/constants/images.dart';
// import '../../../core/constants/styles.dart';
// import '../../../core/functions/theme_services.dart';
// import '../../../core/helper/route_helper.dart';
// import '../../../core/widget/custom_button.dart';

// class DoneScreen extends StatelessWidget {
//   const DoneScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 20.w),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const SizedBox(width: double.infinity),
//             Image.asset(Images.done),
//             SizedBox(height: 30.h),
//             SizedBox(
//               width: 270.w,
//               child: Text(
//                 "Verified successfully".tr,
//                 textAlign: TextAlign.center,
//                 style: robotoBlack.copyWith(
//                   fontWeight: FontWeight.w800,
//                   fontSize: 29.sp,
//                   color: Theme.of(context).hoverColor,
//                 ),
//               ),
//             ),
//             SizedBox(height: 50.h),
//             CustomButton(
//               buttonText: "next".tr,
//               textColor: Theme.of(context).scaffoldBackgroundColor,
//               color:
//                   !ThemeServices().loadThemeFromBox()
//                       ? Color(0xff0f0f31)
//                       : Theme.of(context).primaryColor,
//               fontSize: 22.sp,
//               radius: 11.r,
//               onPressed: () {
//                 Get.offAndToNamed(RouteHelper.signIn);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
