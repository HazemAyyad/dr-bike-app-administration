import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_net_image.dart';
import '../../../sales/presentation/utils/product_image_viewer.dart';
import '../controllers/stock_controller.dart';

class QuickEditProductsTab extends GetView<StockController> {
  const QuickEditProductsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isQuickEditLoading.value) {
        return const SizedBox(
          height: 360,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final rows = controller.quickEditOnlyUnmarked.value
          ? controller.quickEditRows
              .where((row) => !row.markedToday.value)
              .toList()
          : controller.quickEditRows.toList();

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FilterChip(
                  selected: !controller.quickEditOnlyUnmarked.value,
                  label: Text('quickEditAll'.tr),
                  onSelected: (_) =>
                      controller.quickEditOnlyUnmarked.value = false,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: controller.quickEditOnlyUnmarked.value,
                  label: Text('quickEditUnmarkedToday'.tr),
                  onSelected: (_) =>
                      controller.quickEditOnlyUnmarked.value = true,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'refresh'.tr,
                  onPressed: () async {
                    controller.resetQuickEditPagination();
                    await controller.getQuickEditProducts();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(
                      Colors.grey.shade100,
                    ),
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 88,
                    columns: [
                      _col('quickEditMark'),
                      _col('productId'),
                      _col('productCode'),
                      _col('productImages'),
                      _col('productName'),
                      _col('productNameEn'),
                      _col('productNameHe'),
                      _col('productDetails'),
                      _col('category'),
                      _col('subCategories'),
                      _col('storeLocationTab'),
                      _col('retailPrice'),
                      _col('wholesalePrice'),
                      _col('productCost'),
                      _col('price'),
                      _col('minSalePrice'),
                      _col('stock'),
                      _col('minStock'),
                      _col('discount'),
                      _col('productVisible'),
                      _col('productNewBadge'),
                      _col('productBestSeller'),
                      _col('soldWithPaper'),
                      _col('rate'),
                      _col('manufactureYear'),
                      _col('productModel'),
                      _col('productRotationDate'),
                      _col('quickEditAction'),
                    ],
                    rows: rows.map(_row).toList(),
                  ),
                ),
              ),
            ),
            if (controller.isQuickEditLoadingMore.value)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      );
    });
  }

  DataColumn _col(String key) => DataColumn(label: Text(key.tr));

  DataRow _row(QuickEditProductRowState row) {
    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        return row.markedToday.value ? Colors.green.withAlpha(18) : null;
      }),
      cells: [
        DataCell(
          Obx(
            () => Checkbox(
              value: row.markedToday.value,
              onChanged: row.isSaving.value
                  ? null
                  : (_) => controller.toggleQuickEditMark(row),
            ),
          ),
        ),
        DataCell(Text(row.product.productId)),
        DataCell(_field(row, row.productCodeController, width: 110)),
        DataCell(_image(row.product.productImage)),
        DataCell(_field(row, row.nameArController, width: 220)),
        DataCell(_field(row, row.nameEngController, width: 180)),
        DataCell(_field(row, row.nameAbreeController, width: 180)),
        DataCell(_field(row, row.descriptionArController, width: 260)),
        DataCell(_readonly(row.product.categoryName, width: 140)),
        DataCell(_readonly(row.product.subCategories, width: 170)),
        DataCell(_readonly(row.product.storeSectionName, width: 130)),
        DataCell(_number(row, row.normailPriceController)),
        DataCell(_number(row, row.wholesalePriceController)),
        DataCell(_number(row, row.costPriceController)),
        DataCell(_number(row, row.priceController)),
        DataCell(_number(row, row.minSalePriceController)),
        DataCell(_number(row, row.stockController, integerOnly: true)),
        DataCell(_number(row, row.minStockController)),
        DataCell(_number(row, row.discountController)),
        DataCell(_switch(row, (v) => row.isShow = v, () => row.isShow)),
        DataCell(_switch(row, (v) => row.isNewItem = v, () => row.isNewItem)),
        DataCell(
          _switch(row, (v) => row.isMoreSales = v, () => row.isMoreSales),
        ),
        DataCell(
          _switch(
            row,
            (v) => row.isSoldWithPaper = v,
            () => row.isSoldWithPaper,
          ),
        ),
        DataCell(_number(row, row.rateController)),
        DataCell(
            _number(row, row.manufactureYearController, integerOnly: true)),
        DataCell(_field(row, row.modelController, width: 120)),
        DataCell(_field(row, row.rotationDateController, width: 130)),
        DataCell(
          Obx(() {
            if (row.isSaving.value) {
              return const SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final editing = row.isEditing.value;
            return IconButton(
              tooltip: editing ? 'save'.tr : 'edit'.tr,
              icon: Icon(editing ? Icons.save_outlined : Icons.edit_outlined),
              onPressed: editing
                  ? () => controller.saveQuickEditRow(row)
                  : () => controller.editQuickEditRow(row),
            );
          }),
        ),
      ],
    );
  }

  Widget _readonly(String value, {double width = 100}) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _image(String raw) {
    return Builder(
      builder: (context) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => openProductImageViewer(context, raw),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                ShowNetImage.getThumbnailPhoto(raw),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.network(
                  ShowNetImage.getPhoto(raw),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field(
    QuickEditProductRowState row,
    TextEditingController textController, {
    double width = 100,
  }) {
    return Obx(() {
      if (!row.isEditing.value) {
        return _readonly(textController.text, width: width);
      }
      return SizedBox(
        width: width,
        child: TextField(
          controller: textController,
          minLines: 1,
          maxLines: width > 240 ? 2 : 1,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      );
    });
  }

  Widget _number(
    QuickEditProductRowState row,
    TextEditingController textController, {
    bool integerOnly = false,
  }) {
    return Obx(() {
      if (!row.isEditing.value) {
        return _readonly(textController.text, width: 90);
      }
      return SizedBox(
        width: 90,
        child: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              integerOnly ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
            ),
          ],
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      );
    });
  }

  Widget _switch(
    QuickEditProductRowState row,
    ValueChanged<bool> update,
    bool Function() value,
  ) {
    return Obx(() {
      if (!row.isEditing.value) {
        return Icon(
          value() ? Icons.check_circle : Icons.remove_circle_outline,
          color: value() ? Colors.green : Colors.grey,
        );
      }
      return StatefulBuilder(
        builder: (context, setState) {
          return Switch(
            value: value(),
            onChanged: (next) {
              update(next);
              setState(() {});
            },
          );
        },
      );
    });
  }
}
