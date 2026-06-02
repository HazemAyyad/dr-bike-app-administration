import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../data/models/product_details_model.dart';

class ProductLanguageDetailsTabs extends StatelessWidget {
  const ProductLanguageDetailsTabs({Key? key, required this.product})
      : super(key: key);

  final ProductDetailsModel product;

  @override
  Widget build(BuildContext context) {
    final description = (product.descriptionAr ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.nameAr.trim().isEmpty ? '—' : product.nameAr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            SizedBox(width: 8.w),
            Tooltip(
              message: 'اللغات الاخرى',
              child: IconButton.filledTonal(
                icon: const Icon(Icons.translate),
                onPressed: () => _showOtherLanguages(context),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AdminUiColors.subtleOverlay(context),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Text(
            description.isEmpty ? '—' : description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.55,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
      ],
    );
  }

  void _showOtherLanguages(BuildContext context) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(18.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.translate,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'اللغات الاخرى',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: Get.back,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _languageBlock(
                context,
                title: 'langEnglish'.tr,
                name: product.nameEng,
                description: product.descriptionEng ?? '',
              ),
              SizedBox(height: 12.h),
              _languageBlock(
                context,
                title: 'langHebrew'.tr,
                name: product.nameAbree ?? '',
                description: product.descriptionAbree ?? '',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageBlock(
    BuildContext context, {
    required String title,
    required String name,
    required String description,
  }) {
    final displayName = name.trim().isEmpty ? '—' : name.trim();
    final displayDescription =
        description.trim().isEmpty ? '—' : description.trim();
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: 6.h),
          Text(
            displayDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
