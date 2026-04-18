import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../sales/data/models/product_model.dart';
import '../controllers/stock_controller.dart';

/// Main category dropdown + dependent multi-select subcategories.
class CategorySelectorSection extends StatelessWidget {
  const CategorySelectorSection({Key? key, required this.controller})
      : super(key: key);

  final StockController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final mainId = controller.selectedMainCategoryId.value;
        final hasMain = mainId != null && mainId.isNotEmpty;
        final filtered = controller.getFilteredSubCategories();
        final ids = controller.selectedSubCategoryIds.toList();
        final selected =
            filtered.where((c) => ids.contains(c.id)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: mainId != null &&
                      mainId.isNotEmpty &&
                      controller.mainCategories.any((m) => m.id == mainId)
                  ? mainId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
                labelText: 'mainCategory'.tr,
                hintText: 'mainCategoryHint'.tr,
                hintStyle: TextStyle(color: Theme.of(context).hintColor),
              ),
              items: controller.mainCategories
                  .map(
                    (m) => DropdownMenuItem<String>(
                      value: m.id,
                      child: Text(m.nameAr, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                controller.setMainCategory(v);
              },
            ),
            SizedBox(height: 12.h),
            if (controller.mainCategories.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text('noCategories'.tr),
              )
            else
              DropdownSearch<ProductModel>.multiSelection(
                key: ValueKey(
                  '${mainId ?? 'none'}_${ids.join(',')}',
                ),
                selectedItems: selected,
                enabled: hasMain && filtered.isNotEmpty,
                items: (filter, loadProps) async => filtered,
                itemAsString: (c) => c.nameAr,
                compareFn: (a, b) => a.id == b.id,
                popupProps: PopupPropsMultiSelection.menu(
                  showSearchBox: true,
                  constraints: const BoxConstraints(maxHeight: 320),
                  validationBuilder: (_, __) => const SizedBox.shrink(),
                  onItemAdded: (selectedItems, _) {
                    controller.selectedSubCategoryIds.clear();
                    controller.selectedSubCategoryIds
                        .addAll(selectedItems.map((e) => e.id));
                    controller.update();
                  },
                  onItemRemoved: (selectedItems, _) {
                    controller.selectedSubCategoryIds.clear();
                    controller.selectedSubCategoryIds
                        .addAll(selectedItems.map((e) => e.id));
                    controller.update();
                  },
                ),
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    labelText: 'subCategoryMulti'.tr,
                    hintText: hasMain
                        ? 'selectSubCategoryHint'.tr
                        : 'selectMainCategoryFirst'.tr,
                    hintStyle: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                onChanged: (list) {
                  controller.selectedSubCategoryIds.clear();
                  controller.selectedSubCategoryIds
                      .addAll(list.map((e) => e.id));
                  controller.update();
                },
              ),
          ],
        );
      },
    );
  }
}
