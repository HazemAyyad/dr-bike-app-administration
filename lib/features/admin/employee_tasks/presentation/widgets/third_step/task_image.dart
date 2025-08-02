import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../../core/helpers/custom_upload_button.dart';
import '../../controllers/create_task_controller.dart';

Widget taskImage(BuildContext context, CreateTaskController controller) {
  return Column(
    children: [
      MediaUploadButton(
        title: 'uploadImage',
        allowedType: MediaType.image,
        onFilesChanged: (files) {
          controller.selectedFile = [files.first];
        },
      ),
      // UploadButton(
      //   title: 'uploadImage',
      //   textColor: Colors.black,
      //   selectedFile: controller.selectedFile,
      // ),
      SizedBox(height: 10.h),
      CustomChechbox(
        titale: 'requireImage',
        value: controller.requireImage,
        onChanged: (value) {
          controller.requireImage.value = value!;
        },
      ),
    ],
  );
}
