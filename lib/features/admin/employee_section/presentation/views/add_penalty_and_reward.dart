import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:doctorbike/features/admin/employee_section/presentation/controllers/add_employee_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class AddPenaltyAndRewardScreen extends GetView<AddEmployeeController> {
  const AddPenaltyAndRewardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = Get.arguments['isPenaltyTitle'];
    return Scaffold(
      appBar: CustomAppBar(
        title: title == 'penalty' ? 'addPenalty' : 'addReward',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              SizedBox(height: 10.h),
              CustomDropdownField(
                label: 'employeeName',
                hint: 'employeeNameExample',
                dropdownField: controller.employeeService.employeeList.map((e) {
                  return DropdownMenuItem<String>(
                    value: e.id.toString(),
                    child: Text(e.employeeName),
                  );
                }).toList(),
                value: controller.employeeService.employeeList.any((e) =>
                        e.id.toString() == controller.employeeConroller.text)
                    ? controller.employeeConroller.text
                    : null,
                onChanged: (value) {
                  controller.employeeConroller.text = value!;
                },
              ),
              SizedBox(height: 20.h),
              CustomTextField(
                label: 'points',
                hintText: 'taskPointsExample',
                keyboardType: TextInputType.number,
                controller: controller.pointsConroller,
              ),
              SizedBox(height: 30.h),
              AppButton(
                isLoading: controller.isLoading,
                text: title == 'penalty' ? 'addPenalty' : 'addReward',
                onPressed: () => controller.isLoading.value
                    ? null
                    : controller.addOrMinusPoints(
                        context,
                        title == 'penalty' ? false : true,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
