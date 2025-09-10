import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/multi_select_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_time_picker.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../controllers/maintenance_controller.dart';
import '../widgets/custom_line_steps_widget.dart';
import '../widgets/next_back_button.dart';

class NewMaintenanceScreen extends GetView<MaintenanceController> {
  const NewMaintenanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'createMaintenance',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            CustomLineSteps(
              timeLineSteps: controller.timeLineSteps,
              selectedStep: controller.selectedStep,
              changeSelected: controller.changeSelected,
            ),
            SizedBox(height: 20.h),
            CustomDropdownField(
              label: 'customerName',
              hint: 'customerNameExample',
              isRequired: true,
              items: controller.customersNameList,
              onChanged: (value) {
                controller.customerNameController.text = value!;
              },
            ),
            SizedBox(height: 15.h),
            MultiSelectDropdown(
              selectedDaysList: controller.selectedDaysList,
              isRecurrenceVisible: controller.isRecurrenceVisible,
              toggleRecurrence: controller.toggleRecurrence,
              label: 'deliveryDate',
              isRequired: true,
            ),
            SizedBox(height: 15.h),
            CustomTimePicker(
              label: 'deliveryTime',
              isRequired: true,
              isVisible: controller.isTimeVisible,
              onTap: () {
                controller.toggleTime();
              },
              selectedTime: controller.startTime,
            ),
            SizedBox(height: 15.h),
            CustomTextField(
              label: 'details',
              hintText: 'detailsExample',
              controller: controller.detailsController,
            ),
            SizedBox(height: 30.h),

            // UploadButton(
            //   selectedFile: controller.selectedImage,
            //   title: 'uploadMedia',
            // ),
            MediaUploadButton(
              height: 150.h,
              title: 'uploadMedia',
              allowedType: MediaType.both,
              onFilesChanged: (files) {
                if (files.isNotEmpty) controller.selectedMedia = [files.first];
                // يمكنك حفظ الملفات أو رفعها
                print(
                    'Selected: ${controller.selectedMedia.map((e) => e.path).toList()}');
              },
            ),
            SizedBox(height: 30.h),
            NextBackButton(controller: controller),
          ],
        ),
      ),
    );
  }
}
