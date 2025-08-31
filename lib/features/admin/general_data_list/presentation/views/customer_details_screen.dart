// import 'package:doctorbike/core/helpers/custom_app_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';

// import '../../../project_management/presentation/widgets/project_details/sup_text_and_dis.dart';
// import '../controllers/general_data_list_controller.dart';

// class GlobalCustomerDataScreen extends GetView<GeneralDataListController> {
//   const GlobalCustomerDataScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // var globalData = Get.arguments;
//     return Scaffold(
//       appBar: CustomAppBar(
//         title: 'customerDetails',
//         action: false,
//         actions: [
//           GestureDetector(
//             onTap: () {
//               // Handle cancel order action
//               print('Cancel ${'customerName'}');
//             },
//             child: Container(
//               margin: EdgeInsets.symmetric(horizontal: 20.w),
//               height: 32.h,
//               width: 104.w,
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: Colors.red,
//                   width: 1.w,
//                 ),
//                 borderRadius: BorderRadius.circular(18.r),
//               ),
//               child: Center(
//                 child: Text(
//                   'deleteCustomer'.tr,
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                         fontSize: 15.sp,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.red,
//                       ),
//                 ),
//               ),
//             ),
//           )
//         ],
//       ),
//       body: ListView(
//         padding: EdgeInsets.symmetric(horizontal: 24.w),
//         children: [
//           // target details view
//           supTextAndDis(context, 'customerName', 'customerName'),
//           supTextAndDis(context, 'customerType', 'customerType'),
//           supTextAndDis(context, 'customerPhoneNumber', 'customerPhoneNumber'),
//           supTextAndDis(context, 'facebookName', 'facebookName'),
//           supTextAndDis(context, 'facebookLink', 'facebookLink'),
//           supTextAndDis(context, 'instagramName', 'instagramName'),
//           supTextAndDis(context, 'instagramLink', 'instagramLink'),
//           supTextAndDis(context, 'closeContacts', 'closeContacts'),
//           supTextAndDis(context, 'homeLocation', 'homeLocation'),
//           supTextAndDis(context, 'job', 'job'),
//           supTextAndDis(context, 'workLocation', 'workLocation'),
//           supTextAndDis(context, 'closestPersonNumber', 'closestPersonNumber'),
//           supTextAndDis(context, 'closestPersonWork', 'closestPersonWork'),
//           SizedBox(height: 10.w),
//         ],
//       ),
//     );
//   }
// }
