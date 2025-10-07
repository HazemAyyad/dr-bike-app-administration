// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';

// import '../../../../../../core/helpers/custom_dropdown_field.dart';
// import '../../../../../../core/helpers/custom_text_field.dart';
// import '../../controllers/project_controller.dart';

// class SecondStep extends GetView<ProjectController> {
//   const SecondStep({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Flexible(
//               child: CustomDropdownField(
//                 label: 'paymentMethod',
//                 hint: 'paymentMethodExample',
//                 items: controller.paymentMethodList,
//                 value: controller.paymentMethodController.text.isEmpty
//                     ? null
//                     : controller.paymentMethodController.text,
//                 onChanged: (value) {
//                   controller.paymentMethodController.text = value!;
//                 },
//                 validator: (value) => null,
//               ),
//             ),
//             SizedBox(width: 10.w),
//             Flexible(
//               child: CustomTextField(
//                 label: 'notes',
//                 hintText: 'notesExample',
//                 controller: controller.paymentNoteController,
//                 validator: (value) => null,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }
