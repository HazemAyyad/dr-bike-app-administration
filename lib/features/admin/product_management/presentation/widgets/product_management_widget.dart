import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/product_management_controller.dart';

class ProductManagementWidget extends GetView<ProductManagementController> {
  const ProductManagementWidget({
    Key? key,
    required this.productName,
    required this.productImage,
    required this.currentStep,
    required this.rating,
    this.isEdit = false,
    this.stageLabel = '',
    this.onHistoryTap,
  }) : super(key: key);

  final String currentStep;
  final String productName;
  final String productImage;
  final double rating;
  final bool isEdit;
  final String stageLabel;
  final VoidCallback? onHistoryTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.bodyMedium!;
    final imageUrl = ShowNetImage.getThumbnailPhoto(productImage);
    final originalImageUrl = ShowNetImage.getPhoto(productImage);

    return Container(
      height: stageLabel.isEmpty ? 35.h : 44.h,
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            SizedBox(width: 14.w),
            if (onHistoryTap != null) ...[
              InkWell(
                onTap: onHistoryTap,
                borderRadius: BorderRadius.circular(16.r),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(
                    Icons.history_rounded,
                    size: 17.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
            ],
            SizedBox(
              width: onHistoryTap == null ? 78.w : 58.w,
              child: isEdit
                  ? Text(
                      controller.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: textTheme.copyWith(
                        color: AppColors.customGreyColor2,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : _RatingStars(rating: rating),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: textTheme.copyWith(
                      color: ThemeService.isDark.value
                          ? AppColors.whiteColor
                          : AppColors.secondaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (stageLabel.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      stageLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: textTheme.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 10.w),
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
                      imageUrl: originalImageUrl,
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
                  height: 27.h,
                  width: 36.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.r),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
                imageUrl: imageUrl,
                placeholder: (context, url) => Container(
                  height: 27.h,
                  width: 36.w,
                  decoration: BoxDecoration(
                    color: AppColors.customGreyColor6,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 27.h,
                  width: 36.w,
                  alignment: Alignment.center,
                  color: AppColors.customGreyColor6,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 16.sp,
                    color: AppColors.customGreyColor5,
                  ),
                ),
              ),
            ),
            SizedBox(width: 6.w),
          ],
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(7, (index) {
          final value = rating.clamp(0, 7).round();
          final filled = index < value;
          return Icon(
            Icons.star,
            size: 12.sp,
            color:
                filled ? const Color(0xFFFF8A00) : AppColors.customGreyColor5,
          );
        }),
      ),
    );
  }
}

class ProductDevelopmentStepper extends StatelessWidget {
  const ProductDevelopmentStepper({
    Key? key,
    required this.firstSteps,
    required this.secondSteps,
    required this.activeStep,
  }) : super(key: key);

  final List<Map<int, String>> firstSteps;
  final List<Map<int, String>> secondSteps;
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StepRow(steps: firstSteps, activeStep: activeStep),
        SizedBox(height: 24.h),
        _StepRow(steps: secondSteps, activeStep: activeStep),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.steps,
    required this.activeStep,
  });

  final List<Map<int, String>> steps;
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          textDirection: Get.locale?.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          children: [
            for (int index = 0; index < steps.length; index++) ...[
              _StepCircle(
                number: steps[index].keys.first,
                activeStep: activeStep,
              ),
              if (index != steps.length - 1)
                Expanded(
                  child: Container(
                    height: 1.h,
                    color: _lineColor(
                      steps[index].keys.first,
                      steps[index + 1].keys.first,
                    ),
                  ),
                ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          textDirection: Get.locale?.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: steps
              .map(
                (step) => Expanded(
                  child: Text(
                    step.values.first.tr,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: _textColor(step.keys.first),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Color _lineColor(int from, int to) {
    if (activeStep >= from && activeStep >= to) {
      return AppColors.primaryColor;
    }
    return Colors.grey.shade500;
  }

  Color _textColor(int step) {
    if (activeStep == step || step < activeStep) {
      return AppColors.primaryColor;
    }
    return AppColors.customGreyColor5;
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.number,
    required this.activeStep,
  });

  final int number;
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    final isDone = number < activeStep;
    final isActive = number == activeStep;
    final fill = isDone ? AppColors.primaryColor : Colors.transparent;
    final border = isDone || isActive ? AppColors.primaryColor : Colors.grey;
    final textColor = isDone
        ? AppColors.whiteColor
        : isActive
            ? AppColors.primaryColor
            : AppColors.customGreyColor5;

    return Container(
      width: 46.w,
      height: 46.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.w),
      ),
      child: Text(
        number.toString(),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: textColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
