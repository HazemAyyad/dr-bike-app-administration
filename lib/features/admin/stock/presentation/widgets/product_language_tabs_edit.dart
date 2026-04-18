import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/stock_controller.dart';

Color _editSectionTitleColor(BuildContext context) {
  final t = Theme.of(context);
  if (t.brightness == Brightness.dark) {
    return t.colorScheme.primary;
  }
  return AppColors.secondaryColor;
}

/// Name + description fields grouped by language (Arabic / English / Hebrew).
class ProductLanguageTabsEdit extends StatelessWidget {
  const ProductLanguageTabsEdit({Key? key, required this.controller})
      : super(key: key);

  final StockController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            labelColor: cs.primary,
            unselectedLabelColor: Theme.of(context).hintColor,
            indicatorColor: cs.primary,
            indicatorWeight: 3,
            labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            unselectedLabelStyle:
                Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
            tabs: [
              Tab(text: 'langArabic'.tr),
              Tab(text: 'langEnglish'.tr),
              Tab(text: 'langHebrew'.tr),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 280.h,
            child: TabBarView(
              children: [
                _langColumn(
                  context,
                  nameController: controller.productNameController,
                  descController: controller.productDetailsController,
                ),
                _langColumn(
                  context,
                  nameController: controller.nameEngController,
                  descController: controller.descriptionEngController,
                ),
                _langColumn(
                  context,
                  nameController: controller.nameAbreeController,
                  descController: controller.descriptionAbreeController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _langColumn(
    BuildContext context, {
    required TextEditingController nameController,
    required TextEditingController descController,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            label: 'productName',
            hintText: 'productName',
            controller: nameController,
          ),
          SizedBox(height: 10.h),
          CustomTextField(
            label: 'productDetails',
            hintText: 'productDetails',
            controller: descController,
            minLines: 3,
            maxLines: 8,
          ),
        ],
      ),
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
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
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
                    color: _editSectionTitleColor(context),
                  ),
            ),
            SizedBox(height: 12.h),
            child,
          ],
        ),
      ),
    );
  }
}
