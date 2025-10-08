// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';

// import '../../../../../core/services/theme_service.dart';
// import '../../../../../core/utils/app_colors.dart';
// import '../controller/forget_password_controller.dart';

// class SendOtpScreen extends StatelessWidget {
//   const SendOtpScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<ForgetPasswordController>(
//       builder: (controller) {
//         return Scaffold(
//           body: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Title
//                   Text(
//                     "Verify OTP".tr,
//                     textAlign: TextAlign.center,
//                     style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                           color: ThemeService.isDark.value
//                               ? AppColors.secondaryColor
//                               : AppColors.whiteColor,
//                           fontSize: 20.sp,
//                           fontWeight: FontWeight.w700,
//                         ),
//                   ),
//                   SizedBox(height: 15.h),
//                   SizedBox(
//                     width: 270.w,
//                     child: Text(
//                       "Please enter the verification code".tr,
//                       textAlign: TextAlign.center,
//                       style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                             color: ThemeService.isDark.value
//                                 ? AppColors.secondaryColor
//                                 : AppColors.whiteColor,
//                             fontSize: 20.sp,
//                             fontWeight: FontWeight.w700,
//                           ),
//                     ),
//                   ),

//                   SizedBox(height: 60.h),

//                   // OTP Input Fields
//                   Directionality(
//                     textDirection: TextDirection.ltr,
//                     child: PinCodeTextField(
//                       appContext: context,
//                       textStyle: TextStyle(color: Theme.of(context).hintColor),
//                       length: 4,
//                       // controller: controller.otpController,
//                       keyboardType: TextInputType.number,
//                       obscureText: false,
//                       animationType: AnimationType.fade,
//                       pinTheme: PinTheme(
//                         shape: PinCodeFieldShape.box,
//                         // borderRadius: BorderRadius.circular(
//                         //   Dimensions.paddingSizeLarge,
//                         // ),
//                         fieldHeight: 60.h,
//                         fieldWidth: 60.w,
//                         activeColor: Colors.blue,
//                         selectedColor: ThemeService.isDark.value
//                             ? AppColors.secondaryColor
//                             : AppColors.whiteColor,
//                         inactiveColor: Colors.grey,
//                       ),
//                       animationDuration: const Duration(milliseconds: 300),
//                       onChanged: (value) {},
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   // Verify Button
//                   SizedBox(
//                     width: double.infinity,
//                     height: 40.h,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         // controller.checkOTP();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: ThemeService.isDark.value
//                             ? AppColors.secondaryColor
//                             : AppColors.whiteColor,
//                         shape: const RoundedRectangleBorder(
//                             // borderRadius: BorderRadius.circular(
//                             //   Dimensions.radiusDefault,
//                             // ),
//                             ),
//                       ),
//                       child: Text(
//                         "verification".tr,
//                         style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                               color: ThemeService.isDark.value
//                                   ? AppColors.secondaryColor
//                                   : AppColors.whiteColor,
//                               fontSize: 20.sp,
//                               fontWeight: FontWeight.w700,
//                             ),
//                       ),
//                     ),
//                   ),

//                   SizedBox(height: 25.h),

//                   // Resend OTP Section
//                   Text(
//                     "verification code".tr,
//                     style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                           color: ThemeService.isDark.value
//                               ? AppColors.secondaryColor
//                               : AppColors.whiteColor,
//                           fontSize: 20.sp,
//                           fontWeight: FontWeight.w700,
//                         ),
//                   ),
//                   TextButton(
//                     onPressed: () {},
//                     // controller.canResend ? controller.resendOTP : null,
//                     child: Text(
//                       // controller.canResend
//                       // ?
//                       "Resend".tr,
//                       // :
//                       // "${"Resend during".tr} 00:${controller.countdown.toString().padLeft(2, '0')}",
//                       style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                             color: ThemeService.isDark.value
//                                 ? AppColors.secondaryColor
//                                 : AppColors.whiteColor,
//                             fontSize: 20.sp,
//                             fontWeight: FontWeight.w700,
//                           ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
