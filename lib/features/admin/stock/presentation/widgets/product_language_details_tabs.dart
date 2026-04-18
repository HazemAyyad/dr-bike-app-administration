import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/product_details_model.dart';

/// Read-only Arabic / English / Hebrew tabs for name + description on product details.
/// Uses indexed content (no [TabBarView]) so height follows text — no large empty gap.
class ProductLanguageDetailsTabs extends StatefulWidget {
  const ProductLanguageDetailsTabs({Key? key, required this.product})
      : super(key: key);

  final ProductDetailsModel product;

  @override
  State<ProductLanguageDetailsTabs> createState() =>
      _ProductLanguageDetailsTabsState();
}

class _ProductLanguageDetailsTabsState extends State<ProductLanguageDetailsTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedTab =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final p = widget.product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController,
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
        _langPaneForIndex(
          context,
          _tabController.index,
          p,
        ),
      ],
    );
  }

  Widget _langPaneForIndex(
    BuildContext context,
    int index,
    ProductDetailsModel p,
  ) {
    switch (index) {
      case 0:
        return _langPane(
          context,
          name: p.nameAr,
          description: p.descriptionAr ?? '',
        );
      case 1:
        return _langPane(
          context,
          name: p.nameEng,
          description: p.descriptionEng ?? '',
        );
      default:
        return _langPane(
          context,
          name: p.nameAbree ?? '',
          description: p.descriptionAbree ?? '',
        );
    }
  }

  Widget _langPane(
    BuildContext context, {
    required String name,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _pdReadonlyField(context, 'productName', name),
        SizedBox(height: 16.h),
        _pdReadonlyField(context, 'productDetails', description),
      ],
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
