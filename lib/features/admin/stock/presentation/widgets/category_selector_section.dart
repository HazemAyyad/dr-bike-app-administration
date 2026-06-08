import 'package:doctorbike/core/helpers/outline_input_style.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../sales/data/models/product_model.dart';
import '../controllers/stock_controller.dart';

ProductModel? _selectedMainCategory(
  String? mainId,
  List<ProductModel> mains,
) {
  if (mainId == null || mainId.isEmpty) {
    return null;
  }
  final needle = mainId.trim();
  for (final m in mains) {
    if (m.id.trim() == needle) {
      return m;
    }
  }
  return null;
}

List<ProductModel> _filterMainCategories(
  List<ProductModel> mains,
  String filter,
) {
  if (filter.trim().isEmpty) {
    return mains;
  }
  final q = filter.trim().toLowerCase();
  return mains
      .where((m) => m.nameAr.toLowerCase().contains(q))
      .toList(growable: false);
}

void _deferMainCategoryChange(StockController controller, ProductModel? item) {
  final id = item?.id;
  SchedulerBinding.instance.addPostFrameCallback((_) {
    controller.setMainCategory(id);
  });
}

/// Main category (searchable) + dependent multi-select subcategories.
class CategorySelectorSection extends StatelessWidget {
  const CategorySelectorSection({Key? key, required this.controller})
      : super(key: key);

  final StockController controller;

  static const _mainDropdownKey = ValueKey<String>('main_category_dropdown');
  static const _subDropdownKey = ValueKey<String>('sub_category_dropdown');

  @override
  Widget build(BuildContext context) {
    if (controller.mainCategories.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text('noCategories'.tr),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => DropdownSearch<ProductModel>(
            key: _mainDropdownKey,
            selectedItem: _selectedMainCategory(
              controller.selectedMainCategoryId.value,
              controller.mainCategories,
            ),
            items: (filter, _) async =>
                _filterMainCategories(controller.mainCategories, filter),
            itemAsString: (m) => m.nameAr,
            compareFn: (a, b) => a.id == b.id,
            popupProps: PopupProps.menu(
              showSearchBox: true,
              constraints: const BoxConstraints(maxHeight: 320),
              searchDelay: const Duration(milliseconds: 0),
            ),
            decoratorProps: DropDownDecoratorProps(
              decoration: OutlineInputStyle.merge(
                context,
                labelText: 'mainCategory'.tr,
                hintText: 'mainCategoryHint'.tr,
              ),
            ),
            onChanged: (m) => _deferMainCategoryChange(controller, m),
          ),
        ),
        Obx(
          () {
            final mainId = controller.selectedMainCategoryId.value;
            final hasMain = mainId != null && mainId.isNotEmpty;
            final filtered = controller.getFilteredSubCategories();
            if (!hasMain || filtered.isEmpty) {
              return const SizedBox.shrink();
            }

            final ids = controller.selectedSubCategoryIds.toList();
            final selected =
                filtered.where((c) => ids.contains(c.id)).toList();

            return Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: DropdownSearch<ProductModel>.multiSelection(
                key: _subDropdownKey,
                selectedItems: selected,
                items: (filter, loadProps) async => filtered,
                itemAsString: (c) => c.nameAr,
                compareFn: (a, b) => a.id == b.id,
                popupProps: PopupPropsMultiSelection.menu(
                  showSearchBox: true,
                  constraints: const BoxConstraints(maxHeight: 320),
                  validationBuilder: (_, __) => const SizedBox.shrink(),
                  onItemAdded: (selectedItems, _) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      controller.selectedSubCategoryIds.clear();
                      controller.selectedSubCategoryIds
                          .addAll(selectedItems.map((e) => e.id));
                      controller.update();
                    });
                  },
                  onItemRemoved: (selectedItems, _) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      controller.selectedSubCategoryIds.clear();
                      controller.selectedSubCategoryIds
                          .addAll(selectedItems.map((e) => e.id));
                      controller.update();
                    });
                  },
                ),
                decoratorProps: DropDownDecoratorProps(
                  decoration: OutlineInputStyle.merge(
                    context,
                    labelText: 'subCategoryMulti'.tr,
                    hintText: 'selectSubCategoryHint'.tr,
                  ),
                ),
                onChanged: (list) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    controller.selectedSubCategoryIds.clear();
                    controller.selectedSubCategoryIds
                        .addAll(list.map((e) => e.id));
                    controller.update();
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
