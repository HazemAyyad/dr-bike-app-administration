import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../sales/data/models/product_model.dart';
import '../../domain/product_location_utils.dart';
import '../../domain/stock_product_filters.dart';
import '../controllers/stock_controller.dart';

class StockFilterSheet extends StatefulWidget {
  const StockFilterSheet({Key? key}) : super(key: key);

  @override
  State<StockFilterSheet> createState() => _StockFilterSheetState();
}

class _StockFilterSheetState extends State<StockFilterSheet> {
  final StockController controller = Get.find<StockController>();

  String? categoryId;
  String? subCategoryId;
  String? storeSectionId;
  DateTime? dateFrom;
  DateTime? dateTo;
  String sortKey = 'latest';

  @override
  void initState() {
    super.initState();
    final f = controller.productListFilters.value;
    categoryId = f.categoryId;
    subCategoryId = f.subCategoryId;
    storeSectionId = f.storeSectionId;
    dateFrom = f.dateFrom;
    dateTo = f.dateTo;
    if (f.sortBy == 'name') {
      sortKey = 'name';
    } else if (f.sortDirection == 'asc') {
      sortKey = 'oldest';
    } else {
      sortKey = 'latest';
    }
    if (controller.mainCategories.isEmpty) {
      controller.getCategories();
    }
    controller.ensureStoreSectionsLoaded();
  }

  List<ProductModel> get _subcategoriesForCategory {
    if (categoryId == null || categoryId!.isEmpty) return [];
    return controller.allSubCategories
        .where((s) => s.mainCategoryId?.toString() == categoryId)
        .toList();
  }

  StockProductFilters _buildFilters() {
    String sortBy = 'created_at';
    String sortDirection = 'desc';
    if (sortKey == 'oldest') {
      sortDirection = 'asc';
    } else if (sortKey == 'name') {
      sortBy = 'name';
      sortDirection = 'asc';
    }
    return StockProductFilters(
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      storeSectionId: storeSectionId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      sortBy: sortBy,
      sortDirection: sortDirection,
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? dateFrom : dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        dateFrom = picked;
      } else {
        dateTo = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h + MediaQuery.paddingOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'timeFilter'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 16.h),
            _dropdown<String?>(
              label: 'mainCategory'.tr,
              value: categoryId,
              items: [
                DropdownMenuItem<String?>(value: null, child: Text('all'.tr)),
                ...controller.mainCategories.map(
                  (c) => DropdownMenuItem(
                    value: c.id.toString(),
                    child: Text(c.nameAr),
                  ),
                ),
              ],
              onChanged: (v) => setState(() {
                categoryId = v;
                subCategoryId = null;
              }),
            ),
            SizedBox(height: 12.h),
            _dropdown<String?>(
              label: 'subCategory'.tr,
              value: subCategoryId,
              items: [
                DropdownMenuItem<String?>(value: null, child: Text('all'.tr)),
                ..._subcategoriesForCategory.map(
                  (s) => DropdownMenuItem(
                    value: s.id.toString(),
                    child: Text(s.nameAr),
                  ),
                ),
              ],
              onChanged: categoryId == null
                  ? null
                  : (v) => setState(() => subCategoryId = v),
            ),
            SizedBox(height: 12.h),
            GetBuilder<StockController>(
              builder: (_) => _dropdown<String?>(
                label: 'storeSection'.tr,
                value: storeSectionId,
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text('all'.tr)),
                  DropdownMenuItem<String?>(
                    value: kUnassignedStoreSectionFilterId,
                    child: Text('noLocationAssigned'.tr),
                  ),
                  ...controller.storeSections
                      .where((s) => s.isActive)
                      .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => storeSectionId = v),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isFrom: true),
                    child: Text(
                      dateFrom == null
                          ? 'from'.tr
                          : '${'from'.tr}: ${StockProductFilters.formatDate(dateFrom!)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isFrom: false),
                    child: Text(
                      dateTo == null
                          ? 'to'.tr
                          : '${'to'.tr}: ${StockProductFilters.formatDate(dateTo!)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _dropdown<String>(
              label: 'sortByDate'.tr,
              value: sortKey,
              items: [
                DropdownMenuItem(
                  value: 'latest',
                  child: Text('sortByDateDesc'.tr),
                ),
                DropdownMenuItem(value: 'oldest', child: Text('sortByDate'.tr)),
                DropdownMenuItem(value: 'name', child: Text('name'.tr)),
              ],
              onChanged: (v) => setState(() => sortKey = v ?? 'latest'),
            ),
            SizedBox(height: 20.h),
            AppButton(
              isSafeArea: false,
              text: 'apply',
              onPressed: () async {
                Get.back();
                await controller.applyProductFilters(_buildFilters());
              },
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () async {
                Get.back();
                await controller.clearProductFilters();
              },
              child: Text('clear'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
