import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:doctorbike/core/helpers/custom_upload_button.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/show_image_or_video.dart';
import '../../controllers/assets_controller.dart';
import '../../widgets/assets_widget/asset_logs.dart';

class AddNewAssetsScreen extends GetView<AssetsController> {
  const AddNewAssetsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: controller.isEditing.value ? 'editAsset' : 'addNewAsset',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
            key: controller.formKey,
            child: GetBuilder<AssetsController>(
              builder: (controller) {
                if (controller.isLoadingDepreciate.value) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 50.h),
                      const CircularProgressIndicator(),
                    ],
                  );
                }
                return Column(
                  children: [
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Flexible(
                          child: CustomTextField(
                            controller: controller.assetNameController,
                            label: 'assetName',
                            hintText: 'assetNameExample',
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: CustomTextField(
                            controller: controller.priceController,
                            label: 'assetValue',
                            hintText: 'assetValueExample',
                            keyboardType: TextInputType.number,
                            enabled: !controller.isEditing.value,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    CustomTextField(
                      controller: controller.noteController,
                      label: 'notes',
                      hintText: 'notesExample',
                      validator: (value) => null,
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Flexible(
                          child: CustomTextField(
                            controller: controller.depreciationRateController,
                            label: 'averageConsumptionRatio',
                            hintText: 'partnerPercentageExample',
                            keyboardType: TextInputType.number,
                            onChanged: controller.onDepreciationChanged,
                            enabled: !controller.isEditing.value,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        controller.isEditing.value
                            ? const SizedBox.shrink()
                            : Flexible(
                                child: CustomTextField(
                                  controller: controller.monthsNumberController,
                                  label: 'numberOfMonths',
                                  hintText: 'numberOfMonths',
                                  keyboardType: TextInputType.number,
                                  onChanged: controller.onMonthsChanged,
                                ),
                              ),
                      ],
                    ),
                    const EditImagesWidget(),
                    SizedBox(height: 10.h),
                    MediaUploadButton(
                      isShowPreview: controller.isEditing.value ? false : true,
                      onFilesChanged: (files) {
                        final uniqueNewFiles = files.where((file) {
                          return !controller.selectedFile.any(
                            (existingFile) =>
                                existingFile!.path.trim() == file.path.trim(),
                          );
                        }).toList();
                        controller.selectedFile.addAll(uniqueNewFiles);
                        controller.update();
                      },
                      title: 'uploadMedia',
                    ),
                    SizedBox(height: 10.h),
                    if (controller.isEditing.value) const AssetLogs(),
                    SizedBox(height: 20.h),
                    AppButton(
                      isLoading: controller.isLoading,
                      onPressed: () {
                        controller.addNewAssets(context);
                      },
                      text: controller.isEditing.value
                          ? 'editAsset'
                          : 'addNewAsset',
                    ),
                  ],
                );
              },
            )),
      ),
    );
  }
}

class EditImagesWidget extends StatelessWidget {
  const EditImagesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssetsController>(
      builder: (controller) {
        return controller.isEditing.value
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    SizedBox(height: 30.h),
                    controller.assetDetails.value == null
                        ? const SizedBox.shrink()
                        : Row(
                            children: [
                              ...controller.selectedFile.asMap().entries.map(
                                (entry) {
                                  final index = entry.key;
                                  final file = entry.value;
                                  return Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 5.w),
                                    child: Stack(
                                      children: [
                                        ShowImageOrVideo(path: file!.path),
                                        // زرار فوق الصورة
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () {
                                              controller.selectedFile
                                                  .removeAt(index);
                                              controller.update();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                  ],
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }
}
