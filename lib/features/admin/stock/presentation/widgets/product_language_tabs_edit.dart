import 'package:doctorbike/core/helpers/admin_ui_colors.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/stock_controller.dart';

/// Name + description fields grouped by language (Arabic / English / Hebrew).
/// Indexed content (no [TabBarView]) so section height follows fields — no forced tall area.
class ProductLanguageTabsEdit extends StatefulWidget {
  const ProductLanguageTabsEdit({Key? key, required this.controller})
      : super(key: key);

  final StockController controller;

  @override
  State<ProductLanguageTabsEdit> createState() =>
      _ProductLanguageTabsEditState();
}

class _ProductLanguageTabsEditState extends State<ProductLanguageTabsEdit>
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
    final c = widget.controller;
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
          labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          unselectedLabelStyle:
              Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: unselectedTab,
                  ),
          tabs: [
            Tab(text: 'langArabic'.tr),
            Tab(text: 'langEnglish'.tr),
            Tab(text: 'langHebrew'.tr),
          ],
        ),
        SizedBox(height: 16.h),
        _langColumnForIndex(context, c, _tabController.index),
      ],
    );
  }

  Widget _langColumnForIndex(
    BuildContext context,
    StockController c,
    int index,
  ) {
    switch (index) {
      case 0:
        return _langColumn(
          context,
          nameController: c.productNameController,
          descController: c.productDetailsController,
        );
      case 1:
        return _langColumn(
          context,
          nameController: c.nameEngController,
          descController: c.descriptionEngController,
        );
      default:
        return _langColumn(
          context,
          nameController: c.nameAbreeController,
          descController: c.descriptionAbreeController,
        );
    }
  }

  Widget _langColumn(
    BuildContext context, {
    required TextEditingController nameController,
    required TextEditingController descController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomTextField(
          label: 'productName',
          hintText: 'productName',
          controller: nameController,
        ),
        SizedBox(height: 16.h),
        CustomTextField(
          label: 'productDetails',
          hintText: 'productDetails',
          controller: descController,
          minLines: 3,
          maxLines: 8,
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
