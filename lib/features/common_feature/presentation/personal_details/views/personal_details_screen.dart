import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/personal_details_controller.dart';
import '../widgets/personal_details.dart';

class PersonalDetailsScreen extends GetView<PersonalDetailsController> {
  const PersonalDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: buildPersonalDetails(controller, context),
          ),
        ),
      ),
    );
  }
}
