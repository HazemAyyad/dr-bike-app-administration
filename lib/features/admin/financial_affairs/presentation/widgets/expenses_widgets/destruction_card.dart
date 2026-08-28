import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/helpers/app_button.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/expenses_models/destruction_model.dart';

import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/helpers/showtime.dart';
import '../../../../employee_tasks/presentation/views/task_details_screen.dart';
import '../../controllers/expenses_controller.dart';
import '../financial_operational_ui.dart';
import '../financial_image_cache.dart';
import '../../../../../../core/widgets/skeleton_loading.dart';

class DestructionCard extends StatelessWidget {
  const DestructionCard({Key? key, required this.data}) : super(key: key);

  final DestructionModel data;

  @override
  Widget build(BuildContext context) {
    return FinancialOperationalCard(
      onTap: () => Get.dialog(DestructionDetails(data: data)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9.r),
          child: CachedNetworkImage(
            cacheManager: FinancialImageCache.instance,
            imageUrl: data.image.isEmpty
                ? AssetsManager.noImageNet
                : data.image.first,
            width: 36.w,
            height: 36.w,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                SkeletonBlock(width: 36.w, height: 36.w, radius: 9),
            errorWidget: (_, __, ___) => Container(
              width: 36.w,
              height: 36.w,
              color: AppColors.operationalSurface,
              child: Icon(Icons.delete_sweep_outlined,
                  size: 18.sp, color: AppColors.operationalPurple),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.operationalNavy)),
            SizedBox(height: 3.h),
            Text(showData(data.createdAt),
                style: TextStyle(
                    fontSize: 9.5.sp, color: AppColors.customGreyColor5)),
          ]),
        ),
        FinancialMiniChip(
            label: '${data.piecesNumber} قطعة',
            color: AppColors.customOrange3,
            icon: Icons.numbers),
        SizedBox(width: 5.w),
        FinancialMiniChip(
            label:
                '${NumberFormat('#,###.##').format(data.destructionValue)} ₪',
            color: AppColors.operationalPurple,
            icon: Icons.payments_outlined),
      ]),
    );
  }
}

class DestructionDetails extends GetView<ExpensesController> {
  const DestructionDetails({Key? key, required this.data}) : super(key: key);

  final DestructionModel data;

  @override
  Widget build(BuildContext context) {
    final mediaFiles =
        data.image.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'تعديل التفاصيل',
                    onPressed: () => _showEditDialog(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  Text(
                    'details'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.whiteColor
                              : AppColors.secondaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                  ),
                  const SizedBox.shrink(),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'productName',
                      discription: data.productName,
                    ),
                  ),
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'destructionValue',
                      discription: data.destructionValue.toString(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'piecesCount',
                      discription: data.piecesNumber.toString(),
                    ),
                  ),
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'damageReason',
                      discription: data.destructionReason,
                    ),
                  ),
                ],
              ),
              if (mediaFiles.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: '${'images'.tr} ${'or'.tr} ${'video'.tr}',
                      discription: '',
                    ),
                    SizedBox(height: 5.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...mediaFiles.asMap().entries.map(
                                (entry) => entry.value.contains('.mp4')
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5),
                                        child: GestureDetector(
                                          onTap: () {
                                            showGeneralDialog(
                                              context: context,
                                              barrierDismissible: true,
                                              barrierLabel: 'Dismiss',
                                              barrierColor:
                                                  Colors.black.withAlpha(128),
                                              transitionDuration:
                                                  const Duration(
                                                      milliseconds: 300),
                                              pageBuilder:
                                                  (context, anim1, anim2) {
                                                return FullScreenZoomImage(
                                                  imageUrl: entry.value,
                                                  imageUrls: mediaFiles,
                                                  downloadFolderSegments: [
                                                    'Expenses',
                                                    'Destruction',
                                                    data.productName,
                                                  ],
                                                  initialIndex: entry.key,
                                                );
                                              },
                                            );
                                          },
                                          child: Icon(
                                            Icons.video_library_rounded,
                                            size: 80.sp,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5),
                                        child: GestureDetector(
                                          onTap: () {
                                            showGeneralDialog(
                                              context: context,
                                              barrierDismissible: true,
                                              barrierLabel: 'Dismiss',
                                              barrierColor:
                                                  Colors.black.withAlpha(128),
                                              transitionDuration:
                                                  const Duration(
                                                      milliseconds: 300),
                                              pageBuilder:
                                                  (context, anim1, anim2) {
                                                return FullScreenZoomImage(
                                                  imageUrl: entry.value,
                                                  imageUrls: mediaFiles,
                                                  downloadFolderSegments: [
                                                    'Expenses',
                                                    'Destruction',
                                                    data.productName,
                                                  ],
                                                  initialIndex: entry.key,
                                                );
                                              },
                                            );
                                          },
                                          child: CachedNetworkImage(
                                            imageUrl: entry.value,
                                            cacheManager:
                                                FinancialImageCache.instance,
                                            imageBuilder:
                                                (context, imageProvider) =>
                                                    Container(
                                              height: 150.h,
                                              width: 150.w,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.cover,
                                                  filterQuality:
                                                      FilterQuality.medium,
                                                ),
                                              ),
                                            ),
                                            placeholder: (context, url) =>
                                                const Center(
                                              child: CircularProgressIndicator(
                                                  color:
                                                      AppColors.primaryColor),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(
                                              Icons.error,
                                              size: 50,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                        ],
                      ),
                    )
                  ],
                ),
              SupTextAndDiscr(
                titleColor: AppColors.primaryColor,
                title: 'date',
                discription: showData(data.createdAt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final reasonController =
        TextEditingController(text: data.destructionReason);
    controller.assetsFile.clear();
    Get.dialog(
      Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('تعديل تفاصيل الإتلاف',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.operationalNavy)),
            SizedBox(height: 12.h),
            CustomTextField(
              controller: reasonController,
              label: 'damageReason',
              hintText: 'damageReason',
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 4,
              maxLines: 8,
            ),
            SizedBox(height: 10.h),
            MediaUploadButton(
              onFilesChanged: (files) => controller.assetsFile = files,
              title: 'إضافة مرفقات جديدة',
            ),
            SizedBox(height: 14.h),
            AppButton(
              isLoading: controller.isLoading,
              text: 'save',
              onPressed: () => controller.editDestructionDetails(
                context,
                destructionId: data.destructionId.toString(),
                reason: reasonController.text,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'المنتج والكمية وسعر التكلفة مقفلة محاسبيًا.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9.5.sp, color: AppColors.customGreyColor5),
            ),
          ]),
        ),
      ),
    );
  }
}
