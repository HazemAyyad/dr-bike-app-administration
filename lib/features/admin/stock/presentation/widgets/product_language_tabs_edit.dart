import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/outline_input_style.dart';
import '../controllers/stock_controller.dart';

/// Compact Arabic name + description (primary fields on add/edit product).
class ProductArabicFieldsEdit extends StatelessWidget {
  const ProductArabicFieldsEdit({Key? key, required this.controller})
      : super(key: key);

  final StockController controller;

  static EdgeInsetsGeometry _densePadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h);

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
        );

    InputDecoration fieldDecoration(String label) {
      return OutlineInputStyle.merge(
        context,
        labelText: label,
        hintText: label,
      ).copyWith(
        isDense: true,
        contentPadding: _densePadding(context),
        labelStyle: labelStyle,
      );
    }

    final fieldStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: c.productNameController,
          style: fieldStyle?.copyWith(fontWeight: FontWeight.w800),
          textInputAction: TextInputAction.next,
          decoration: fieldDecoration('productName'.tr),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: c.productDetailsController,
          style: fieldStyle,
          minLines: 2,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          decoration: fieldDecoration('productDetails'.tr),
        ),
      ],
    );
  }
}

/// Section card wrapper for edit product screen sections.
class EditProductSectionCard extends StatelessWidget {
  const EditProductSectionCard({
    Key? key,
    required this.titleKey,
    required this.child,
  }) : super(key: key);

  final String titleKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 24.h),
      elevation: 0,
      color: AdminUiColors.cardBackground(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titleKey.tr,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            SizedBox(height: 16.h),
            child,
          ],
        ),
      ),
    );
  }
}

/// Kept for any legacy import; redirects to Arabic-only compact fields.
@Deprecated('Use ProductArabicFieldsEdit')
class ProductLanguageTabsEdit extends StatelessWidget {
  const ProductLanguageTabsEdit({Key? key, required this.controller})
      : super(key: key);

  final StockController controller;

  @override
  Widget build(BuildContext context) =>
      ProductArabicFieldsEdit(controller: controller);
}
