// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import '../../../controller/auth/forgetpassword.controller.dart';
// import '../../../core/constants/dimensions.dart';
// import '../../../core/constants/styles.dart';
// import '../../../core/functions/theme_services.dart';
// import '../../../core/widget/custom_button.dart';
// import '../../../core/widget/custom_text_field.dart';

// class OtpPage extends StatelessWidget {
//   final TextEditingController email;
//   const OtpPage({super.key, required this.email});

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<ForgetPasswordControllerImp>(
//       builder: (forgetPasswordController) {
//         forgetPasswordController.email = email;
//         return Scaffold(
//           body: Form(
//             key: forgetPasswordController.formstate2,
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20.w),
//               child: Center(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       SizedBox(width: double.infinity, height: 70.h),
//                       SizedBox(height: 20.h),
//                       Text(
//                         "Let's get started".tr,
//                         textAlign: TextAlign.center,
//                         style: robotoBold.copyWith(
//                           fontSize: 26.sp,
//                           color: Theme.of(context).hoverColor,
//                         ),
//                       ),
//                       SizedBox(height: 20.h),
//                       SizedBox(
//                         width: MediaQuery.of(context).size.width * 0.85,
//                         child: Text(
//                           "We will send a verification code to your email for confirmation"
//                               .tr,
//                           textAlign: TextAlign.center,
//                           style: robotoRegular.copyWith(
//                             color: Theme.of(context).hintColor,
//                             fontSize: Dimensions.fontSizeExtraLarge,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 50.h),
//                       Align(
//                         alignment: AlignmentDirectional.centerStart,
//                         child: Text(
//                           "email".tr,
//                           textAlign: TextAlign.center,
//                           style: robotoRegular.copyWith(
//                             color: Theme.of(context).hintColor,
//                             fontSize: Dimensions.fontSizeLarge,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 8.h),
//                       CustomTextField(
//                         hintText: "email".tr,
//                         borderRadius: 15.r,
//                         isChange: true,
//                         isEnabled: true,
//                         inputType: TextInputType.emailAddress,
//                         controller: forgetPasswordController.email,
//                       ),
//                       SizedBox(height: 10.h),
//                       Padding(
//                         padding: const EdgeInsetsDirectional.symmetric(
//                           vertical: Dimensions.paddingSizeSmall,
//                         ),
//                         child: RichText(
//                           text: TextSpan(
//                             text: "message1".tr,
//                             style: robotoRegular.copyWith(
//                               color: Theme.of(context).hintColor,
//                               fontSize: Dimensions.fontSizeSmall,
//                             ),
//                             children: [
//                               TextSpan(
//                                 text: "  ${"message2".tr}",
//                                 style: robotoRegular.copyWith(
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: Dimensions.fontSizeSmall,
//                                   color: Theme.of(context).primaryColor,
//                                   decoration: TextDecoration.underline,
//                                 ),
//                                 recognizer:
//                                     TapGestureRecognizer()
//                                       ..onTap = () {
//                                         // Navigate to Terms and Conditions Page
//                                       },
//                               ),
//                               TextSpan(
//                                 text: " ${"message3".tr}",
//                                 style: robotoRegular.copyWith(
//                                   color: Theme.of(context).hintColor,
//                                   fontSize: Dimensions.fontSizeSmall,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       CustomButton(
//                         buttonText: "next".tr,
//                         textColor: Theme.of(context).scaffoldBackgroundColor,
//                         color:
//                             !ThemeServices().loadThemeFromBox()
//                                 ? Theme.of(context).hoverColor
//                                 : Theme.of(context).primaryColor,
//                         onPressed: () async {
//                           forgetPasswordController.startTimer();

//                           forgetPasswordController.checkEmail();
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
