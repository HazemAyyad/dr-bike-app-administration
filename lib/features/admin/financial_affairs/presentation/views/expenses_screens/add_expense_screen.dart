import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_upload_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/helpers/video_view.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../controllers/expenses_controller.dart';

class AddExpenseScreen extends GetView<ExpensesController> {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: controller.isEditing.value ? 'editExpense' : 'addExpense',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: GetBuilder<ExpensesController>(
          builder: (controller) {
            if (controller.isLoadingGet.value) {
              return Column(
                children: [
                  SizedBox(height: 300.h),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              );
            }
            return Form(
              key: controller.formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: CustomTextField(
                          label: 'expenseName',
                          hintText: 'expenseName',
                          controller: controller.expenseNameController,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Flexible(
                        child: CustomTextField(
                          label: 'price',
                          hintText: 'price',
                          keyboardType: TextInputType.number,
                          controller: controller.expensePriceController,
                          enabled: !controller.isEditing.value,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: CustomDropdownFieldWithSearch(
                          tital: 'box',
                          hint: 'box',
                          titalTextStyle:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                          items: controller.shownBoxesList,
                          onChanged: (value) {
                            if (value != null) {
                              controller.boxIdController.text =
                                  value.boxId.toString();
                            }
                          },
                          value: controller.shownBoxesList.firstWhereOrNull(
                            (element) =>
                                element.boxId.toString() ==
                                controller.boxIdController.text,
                          ),
                          itemAsString: (item) =>
                              '${item.boxName} - (${item.totalBalance} ${item.currency})',
                          compareFn: (a, b) => a.boxId == b.boxId,
                          isEnabled: !controller.isEditing.value,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Get.toNamed(AppRoutes.CREATEBOXESSCREEN)
                                ?.then((value) {
                          controller.getShowBoxes();
                        }),
                        icon: Icon(
                          Icons.add_circle_sharp,
                          color: AppColors.primaryColor,
                          size: 35.sp,
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 20.h),
                  if (controller.isEditing.value &&
                      controller.invoiceFile.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: 'Dismiss',
                          barrierColor: Colors.black.withAlpha(128),
                          transitionDuration: const Duration(milliseconds: 300),
                          pageBuilder: (context, anim1, anim2) {
                            return FullScreenZoomImage(
                              imageUrl: controller.invoiceFile.first.path,
                            );
                          },
                        );
                      },
                      child: CachedNetworkImage(
                        cacheManager: CacheManager(
                          Config(
                            'imagesCache',
                            stalePeriod: const Duration(days: 7),
                            maxNrOfCacheObjects: 100,
                          ),
                        ),
                        imageBuilder: (context, imageProvider) => Container(
                          height: 200.h,
                          width: 200.w,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                        imageUrl: controller.invoiceFile.isNotEmpty
                            ? controller.invoiceFile.first.path
                            : '',
                        fadeInDuration: const Duration(milliseconds: 200),
                        fadeOutDuration: const Duration(milliseconds: 200),
                        placeholder: (context, url) => SizedBox(
                          height: 200.h,
                          width: 200.w,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  SizedBox(height: 20.h),
                  MediaUploadButton(
                    allowedType: MediaType.image,
                    onFilesChanged: (files) {
                      controller.invoiceFile = files;
                    },
                    title: 'invoiceImage',
                  ),
                  SizedBox(height: 20.h),
                  CustomTextField(
                    controller: controller.expenseNoteController,
                    label: 'notes',
                    hintText: 'notes',
                    validator: (p0) => null,
                  ),
                  SizedBox(height: 20.h),
                  const EditImagesWidget(),
                  MediaUploadButton(
                    onFilesChanged: (files) {
                      controller.expensesFile = files;
                    },
                    title: 'uploadMedia',
                  ),
                  SizedBox(height: 50.h),
                  AppButton(
                    isLoading: controller.isAddLoading,
                    text: controller.isEditing.value
                        ? 'editExpense'
                        : 'submitExpense',
                    onPressed: () {
                      controller.addExpense(context);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class EditImagesWidget extends StatelessWidget {
  const EditImagesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExpensesController>(
      builder: (controller) {
        return controller.isEditing.value
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    controller.expensesFile.isEmpty
                        ? const SizedBox.shrink()
                        : Row(
                            children: [
                              ...controller.expensesFile.map(
                                (e) => controller.isLoadingGet.value
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
                                              e.path.contains('mp4')
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
                                            child: e.path.contains('.mp4')
                                                ? Icon(
                                                    Icons
                                                        .play_circle_outline_rounded,
                                                    size: 150.sp,
                                                    color:
                                                        AppColors.primaryColor,
                                                  )
                                                : CachedNetworkImage(
                                                    cacheManager: CacheManager(
                                                      Config(
                                                        'imagesCache',
                                                        stalePeriod:
                                                            const Duration(
                                                                days: 7),
                                                        maxNrOfCacheObjects:
                                                            100,
                                                      ),
                                                    ),
                                                    imageBuilder: (context,
                                                            imageProvider) =>
                                                        Container(
                                                      height: 200.h,
                                                      width: 200.w,
                                                      decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                          image: imageProvider,
                                                          fit: BoxFit.fill,
                                                          filterQuality:
                                                              FilterQuality
                                                                  .medium,
                                                        ),
                                                      ),
                                                    ),
                                                    imageUrl: e.path,
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
                    SizedBox(height: 20.h),
                  ],
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }
}
