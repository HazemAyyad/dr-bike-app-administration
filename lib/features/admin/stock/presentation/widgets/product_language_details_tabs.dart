import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/product_details_model.dart';

/// Read-only Arabic / English / Hebrew tabs for name + description on product details.
class ProductLanguageDetailsTabs extends StatelessWidget {
  const ProductLanguageDetailsTabs({Key? key, required this.product})
      : super(key: key);

  final ProductDetailsModel product;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedTab =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            labelColor: cs.primary,
            unselectedLabelColor: unselectedTab,
            indicatorColor: cs.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'langArabic'.tr),
              Tab(text: 'langEnglish'.tr),
              Tab(text: 'langHebrew'.tr),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 240.h,
            child: TabBarView(
              children: [
                _langPane(
                  context,
                  name: product.nameAr,
                  description: product.descriptionAr ?? '',
                ),
                _langPane(
                  context,
                  name: product.nameEng,
                  description: product.descriptionEng ?? '',
                ),
                _langPane(
                  context,
                  name: product.nameAbree ?? '',
                  description: product.descriptionAbree ?? '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _langPane(
    BuildContext context, {
    required String name,
    required String description,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pdReadonlyField(context, 'productName', name),
          SizedBox(height: 16.h),
          _pdReadonlyField(context, 'productDetails', description),
        ],
      ),
    );
  }

  Widget _pdReadonlyField(
    BuildContext context,
    String titleKey,
    String value,
  ) {
    final display = value.trim().isEmpty ? '—' : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleKey.tr,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        SizedBox(height: 4.h),
        Text(
          display,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}
