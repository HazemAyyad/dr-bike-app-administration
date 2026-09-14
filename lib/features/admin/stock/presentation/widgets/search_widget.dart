import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';
import 'stock_search_sheet.dart';

/// Direct inventory search. Closeout selection keeps its dedicated picker.
class SearchWidget extends GetView<StockController> {
  const SearchWidget({
    Key? key,
    required this.isCloseouts,
    this.borderRadius,
    this.newComposition,
    this.productIdController,
    this.productNameController,
  }) : super(key: key);

  final bool isCloseouts;
  final BorderRadius? borderRadius;
  final NewCompositionModel? newComposition;
  final TextEditingController? productIdController;
  final TextEditingController? productNameController;

  StockSearchContext get _searchContext => StockSearchContext(
        isCloseouts: isCloseouts,
        borderRadius: borderRadius,
        newComposition: newComposition,
        productIdController: productIdController,
        productNameController: productNameController,
      );

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => TextField(
        controller: isCloseouts ? null : controller.stockSearchQueryController,
        readOnly: isCloseouts,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'search'.tr,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: !isCloseouts &&
                  controller.stockSearchActiveQuery.value.trim().isNotEmpty
              ? IconButton(
                  tooltip: 'clear'.tr,
                  onPressed: () {
                    controller.stockSearchQueryController.clear();
                    controller.onStockSearchQueryChanged('');
                  },
                  icon: const Icon(Icons.close),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: isCloseouts ? null : controller.onStockSearchQueryChanged,
        onSubmitted: isCloseouts
            ? null
            : (value) => controller.getSearchProducts(name: value),
        onTap: isCloseouts
            ? () => openStockSearchSheet(
                  controller: controller,
                  searchContext: _searchContext,
                )
            : null,
      ),
    );
  }
}
