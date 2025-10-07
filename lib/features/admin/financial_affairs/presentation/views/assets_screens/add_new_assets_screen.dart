import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:doctorbike/core/helpers/custom_upload_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/assets_controller.dart';
import '../../../../../../core/helpers/video_view.dart';

class AddNewAssetsScreen extends GetView<AssetsController> {
  const AddNewAssetsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: controller.isEditing.value ? 'editAsset' : 'addNewAsset',
          action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
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
              SizedBox(height: 20.h),
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
              SizedBox(height: 30.h),
              MediaUploadButton(
                onFilesChanged: (files) {
                  controller.selectedFile = files;
                },
                title: 'uploadMedia',
              ),
              SizedBox(height: 50.h),
              AppButton(
                isLoading: controller.isLoading,
                onPressed: () {
                  controller.addNewAssets(context);
                },
                text: controller.isEditing.value ? 'editAsset' : 'addNewAsset',
              ),
            ],
          ),
        ),
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
                              ...controller.selectedFile.map(
                                (e) => controller.isLoadingDepreciate.value
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 5.w),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(5.r),
                                          child: GestureDetector(
                                            onTap: () {
                                              e!.path.contains('mp4')
                                                  ? showGeneralDialog(
                                                      context: context,
                                                      barrierDismissible: true,
                                                      barrierLabel: 'Dismiss',
                                                      barrierColor: Colors.black
                                                          .withAlpha(128),
                                                      transitionDuration:
                                                          const Duration(
                                                              milliseconds:
                                                                  300),
                                                      pageBuilder: (context,
                                                          anim1, anim2) {
                                                        return VideoView(
                                                            videoPath: e.path);
                                                      },
                                                    )
                                                  : showGeneralDialog(
                                                      context: context,
                                                      barrierDismissible: true,
                                                      barrierLabel: 'Dismiss',
                                                      barrierColor: Colors.black
                                                          .withAlpha(128),
                                                      transitionDuration:
                                                          const Duration(
                                                              milliseconds:
                                                                  300),
                                                      pageBuilder: (context,
                                                          anim1, anim2) {
                                                        return FullScreenZoomImage(
                                                            imageUrl: e.path);
                                                      },
                                                    );
                                            },
                                            child: e!.path.contains('.mp4')
                                                ? Icon(
                                                    Icons
                                                        .play_circle_outline_rounded,
                                                    size: 150.sp,
                                                    color:
                                                        AppColors.primaryColor,
                                                  )
                                                : CachedNetworkImage(
                                                    imageUrl: e.path,
                                                    height: 200.h,
                                                    width: 200.w,
                                                    fit: BoxFit.fill,
                                                    fadeInDuration:
                                                        const Duration(
                                                            milliseconds: 200),
                                                    fadeOutDuration:
                                                        const Duration(
                                                            milliseconds: 200),
                                                    placeholder:
                                                        (context, url) =>
                                                            const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                    errorWidget: (context, url,
                                                            error) =>
                                                        const Icon(Icons.error),
                                                  ),
                                          ),
                                        ),
                                      ),
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
