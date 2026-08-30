import 'dart:io';

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
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/widgets/skeleton_loading.dart';
import '../../../../../../routes/app_routes.dart';
import '../../controllers/expenses_controller.dart';
import '../../widgets/financial_operational_ui.dart';
import '../../widgets/financial_skeletons.dart';

class AddExpenseScreen extends GetView<ExpensesController> {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: controller.isEditing.value ? 'تعديل المصروف' : 'addExpense',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(13.w, 10.h, 13.w, 28.h),
        child: GetBuilder<ExpensesController>(
          builder: (controller) {
            if (controller.isLoadingGet.value) {
              return const FinancialFormSkeleton();
            }
            return Form(
              key: controller.formKey,
              child: Column(
                children: [
                  FinancialOperationalCard(
                    child: Column(children: [
                      Row(children: [
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AppColors.operationalPurple
                                .withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(11.r),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.operationalPurple,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.isEditing.value
                                    ? 'بيانات المصروف'
                                    : 'مصروف عمومي جديد',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'الرواتب وإتلاف البضاعة لهما شاشات مستقلة',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ]),
                      SizedBox(height: 10.h),
                      CustomTextField(
                        label: 'expenseName',
                        hintText: 'expenseName',
                        controller: controller.expenseNameController,
                        enabled: !controller.isExpenseReadOnly.value,
                      ),
                      SizedBox(height: 9.h),
                      Row(children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'price',
                            hintText: 'price',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            controller: controller.expensePriceController,
                            enabled: !controller.isEditing.value &&
                                !controller.isExpenseReadOnly.value,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: TextFormField(
                            controller: controller.expenseDateController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'التاريخ',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_month_rounded),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'حدد التاريخ'
                                : null,
                            onTap: controller.isEditing.value
                                ? null
                                : () async {
                                    final selected = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (selected != null) {
                                      controller.expenseDateController.text =
                                          '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
                                    }
                                  },
                          ),
                        ),
                      ]),
                    ]),
                  ),
                  SizedBox(height: 9.h),
                  FinancialOperationalCard(
                    child: Row(children: [
                      Expanded(
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
                          isEnabled: !controller.isEditing.value &&
                              !controller.isExpenseReadOnly.value,
                        ),
                      ),
                      if (!controller.isEditing.value)
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
                    ]),
                  ),
                  SizedBox(height: 10.h),
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
                              imageUrls: controller.invoiceFile
                                  .map((file) => file.path)
                                  .toList(),
                              downloadFolderSegments: [
                                'Expenses',
                                controller.expenseNameController.text,
                                'Invoices',
                              ],
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
                          height: 125.h,
                          width: 125.w,
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
                          height: 125.h,
                          width: 125.w,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  SizedBox(height: 10.h),
                  if (!controller.isExpenseReadOnly.value)
                    MediaUploadButton(
                      allowedType: MediaType.image,
                      onFilesChanged: (files) {
                        controller.setInvoiceFiles(files);
                      },
                      title: 'invoiceImage',
                    ),
                  if (!controller.isExpenseReadOnly.value)
                    GetBuilder<ExpensesController>(
                      builder: (controller) => _ExpenseAttachmentPreview(
                        files: controller.invoiceFile,
                        onRemove: controller.removeInvoiceFileAt,
                      ),
                    ),
                  SizedBox(height: 10.h),
                  CustomTextField(
                    controller: controller.expenseNoteController,
                    label: 'notes',
                    hintText: 'notes',
                    enabled: !controller.isExpenseReadOnly.value,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 2,
                    maxLines: 5,
                    validator: (p0) => null,
                  ),
                  SizedBox(height: 10.h),
                  const EditImagesWidget(),
                  if (!controller.isExpenseReadOnly.value)
                    MediaUploadButton(
                      onFilesChanged: (files) {
                        controller.setExpenseMediaFiles(files);
                      },
                      title: 'uploadMedia',
                    ),
                  if (!controller.isExpenseReadOnly.value)
                    GetBuilder<ExpensesController>(
                      builder: (controller) => _ExpenseAttachmentPreview(
                        files: controller.expensesFile,
                        onRemove: controller.removeExpenseMediaAt,
                      ),
                    ),
                  SizedBox(height: 18.h),
                  Obx(
                    () => controller.isAddLoading.value &&
                            controller.uploadProgress.value > 0
                        ? Padding(
                            padding: EdgeInsets.only(bottom: 14.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                LinearProgressIndicator(
                                  value: controller.uploadProgress.value,
                                  minHeight: 7.h,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  'جاري رفع المرفقات ${(controller.uploadProgress.value * 100).round()}%',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (!controller.isExpenseReadOnly.value)
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

class _ExpenseAttachmentPreview extends StatelessWidget {
  const _ExpenseAttachmentPreview({
    required this.files,
    required this.onRemove,
  });

  final List<File> files;
  final ValueChanged<int> onRemove;

  bool _isVideo(String path) {
    final value = path.toLowerCase();
    return value.endsWith('.mp4') ||
        value.endsWith('.mov') ||
        value.endsWith('.avi') ||
        value.endsWith('.webm') ||
        value.endsWith('.mkv');
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: SizedBox(
        height: 92.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: files.length,
          separatorBuilder: (_, __) => SizedBox(width: 8.w),
          itemBuilder: (context, index) {
            final path = files[index].path;
            final remote = path.startsWith('http');
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    width: 86.w,
                    height: 86.h,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.06),
                    child: _isVideo(path)
                        ? const Icon(Icons.play_circle_outline_rounded)
                        : remote
                            ? CachedNetworkImage(
                                imageUrl: path,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => SkeletonBlock(
                                  width: 86.w,
                                  height: 86.h,
                                  radius: 10,
                                ),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.broken_image_outlined),
                              )
                            : Image.file(
                                files[index],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.insert_drive_file_outlined),
                              ),
                  ),
                ),
                PositionedDirectional(
                  top: 3,
                  end: 3,
                  child: InkWell(
                    onTap: () => onRemove(index),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
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
        final mediaFiles = controller.expensesFile
            .map((file) => file.path)
            .where((path) => path.trim().isNotEmpty)
            .toList();

        return controller.isEditing.value
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    mediaFiles.isEmpty
                        ? const SizedBox.shrink()
                        : Row(
                            children: [
                              ...mediaFiles.asMap().entries.map(
                                    (entry) => controller.isLoadingGet.value
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
                                                  showGeneralDialog(
                                                    context: context,
                                                    barrierDismissible: true,
                                                    barrierLabel: 'Dismiss',
                                                    barrierColor: Colors.black
                                                        .withAlpha(128),
                                                    transitionDuration:
                                                        const Duration(
                                                            milliseconds: 300),
                                                    pageBuilder: (context,
                                                        anim1, anim2) {
                                                      return FullScreenZoomImage(
                                                        imageUrl: entry.value,
                                                        imageUrls: mediaFiles,
                                                        downloadFolderSegments: [
                                                          'Expenses',
                                                          controller
                                                              .expenseNameController
                                                              .text,
                                                          'Media',
                                                        ],
                                                        initialIndex: entry.key,
                                                      );
                                                    },
                                                  );
                                                },
                                                child: entry.value
                                                        .contains('.mp4')
                                                    ? Icon(
                                                        Icons
                                                            .play_circle_outline_rounded,
                                                        size: 150.sp,
                                                        color: AppColors
                                                            .primaryColor,
                                                      )
                                                    : CachedNetworkImage(
                                                        cacheManager:
                                                            CacheManager(
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
                                                          decoration:
                                                              BoxDecoration(
                                                            image:
                                                                DecorationImage(
                                                              image:
                                                                  imageProvider,
                                                              fit: BoxFit.fill,
                                                              filterQuality:
                                                                  FilterQuality
                                                                      .medium,
                                                            ),
                                                          ),
                                                        ),
                                                        fadeInDuration:
                                                            const Duration(
                                                                milliseconds:
                                                                    200),
                                                        fadeOutDuration:
                                                            const Duration(
                                                                milliseconds:
                                                                    200),
                                                        placeholder:
                                                            (context, url) =>
                                                                const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            const Icon(
                                                                Icons.error),
                                                        imageUrl: entry.value,
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
