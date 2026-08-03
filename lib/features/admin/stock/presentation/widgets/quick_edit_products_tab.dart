import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_net_image.dart';
import '../../../sales/presentation/utils/product_image_viewer.dart';
import '../controllers/stock_controller.dart';

class QuickEditProductsTab extends StatefulWidget {
  const QuickEditProductsTab({Key? key}) : super(key: key);

  @override
  State<QuickEditProductsTab> createState() => _QuickEditProductsTabState();
}

class _QuickEditProductsTabState extends State<QuickEditProductsTab> {
  static const double _desktopTableWidth = 4620;
  static const double _mobileTableWidth = 3560;
  static const double _rowHeight = 88;
  static const double _headingHeight = 56;
  static const double _scrollbarThickness = 12;

  final ScrollController _topHorizontalController = ScrollController();
  final ScrollController _tableHorizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  StockController get controller => Get.find<StockController>();

  bool _syncingHorizontalScroll = false;
  DateTime? _lastLoadMoreAt;

  @override
  void initState() {
    super.initState();
    _topHorizontalController.addListener(_syncTopToTable);
    _tableHorizontalController.addListener(_syncTableToTop);
    _verticalController.addListener(_loadMoreNearBottom);
  }

  @override
  void dispose() {
    _topHorizontalController.removeListener(_syncTopToTable);
    _tableHorizontalController.removeListener(_syncTableToTop);
    _verticalController.removeListener(_loadMoreNearBottom);
    _topHorizontalController.dispose();
    _tableHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _syncTopToTable() {
    _syncHorizontalControllers(
      source: _topHorizontalController,
      target: _tableHorizontalController,
    );
  }

  void _syncTableToTop() {
    _syncHorizontalControllers(
      source: _tableHorizontalController,
      target: _topHorizontalController,
    );
  }

  void _syncHorizontalControllers({
    required ScrollController source,
    required ScrollController target,
  }) {
    if (_syncingHorizontalScroll || !source.hasClients || !target.hasClients) {
      return;
    }
    final max = target.position.maxScrollExtent;
    final next = source.offset.clamp(0.0, max);
    if ((target.offset - next).abs() < 0.5) return;

    _syncingHorizontalScroll = true;
    target.jumpTo(next);
    _syncingHorizontalScroll = false;
  }

  void _loadMoreNearBottom() {
    if (!_verticalController.hasClients) return;
    if (controller.isQuickEditLoading.value ||
        controller.isQuickEditLoadingMore.value ||
        !controller.quickEditHasMore) {
      return;
    }

    final now = DateTime.now();
    final last = _lastLoadMoreAt;
    if (last != null && now.difference(last) < const Duration(seconds: 1)) {
      return;
    }

    if (_verticalController.position.pixels >=
        _verticalController.position.maxScrollExtent - 160) {
      _lastLoadMoreAt = now;
      controller.getQuickEditProducts(isRefresh: true);
    }
  }

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

      final viewportHeight = MediaQuery.sizeOf(context).height;
      final rowsHeight = rows.length * _rowHeight + _headingHeight;
      final tableHeight = rowsHeight.clamp(
        240.0,
        (viewportHeight - 245).clamp(320.0, 720.0),
      );
      final isCompact = MediaQuery.sizeOf(context).width < 700;
      final tableWidth = isCompact ? _mobileTableWidth : _desktopTableWidth;

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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ScrollConfiguration(
                  behavior: const _QuickEditScrollBehavior(),
                  child: Column(
                    children: [
                      SizedBox(
                        height: _scrollbarThickness + 4,
                        child: Scrollbar(
                          controller: _topHorizontalController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: _scrollbarThickness,
                          child: SingleChildScrollView(
                            controller: _topHorizontalController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: tableWidth,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: tableHeight,
                        child: Scrollbar(
                          controller: _verticalController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            controller: _verticalController,
                            child: Scrollbar(
                              controller: _tableHorizontalController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              thickness: _scrollbarThickness,
                              child: SingleChildScrollView(
                                controller: _tableHorizontalController,
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: tableWidth,
                                  child: DataTable(
                                    headingRowColor: WidgetStatePropertyAll(
                                      Colors.grey.shade100,
                                    ),
                                    dataRowMinHeight: 56,
                                    dataRowMaxHeight: 88,
                                    columnSpacing: 32,
                                    horizontalMargin: 12,
                                    columns: [
                                      _iconCol(
                                        'quickEditMark',
                                        Icons.check_box_outlined,
                                      ),
                                      _col('productId', width: 72),
                                      _col('productCode', width: 110),
                                      _iconCol(
                                        'productImages',
                                        Icons.image_outlined,
                                      ),
                                      _col('productName', width: 220),
                                      if (!isCompact) ...[
                                        _col('productNameEn', width: 180),
                                        _col('productNameHe', width: 180),
                                        _col('productDetails', width: 260),
                                      ],
                                      _col('category', width: 140),
                                      _col('subCategories', width: 170),
                                      _col('storeLocationTab', width: 130),
                                      _col('retailPrice', width: 90),
                                      _col('wholesalePrice', width: 90),
                                      _col('productCost', width: 90),
                                      _col('price', width: 90),
                                      _col('minSalePrice', width: 90),
                                      _col('stock', width: 90),
                                      _col('minStock', width: 90),
                                      _col('discount', width: 90),
                                      _iconCol(
                                        'productVisible',
                                        Icons.visibility_outlined,
                                      ),
                                      _iconCol(
                                        'productNewBadge',
                                        Icons.fiber_new_outlined,
                                      ),
                                      _iconCol(
                                        'productBestSeller',
                                        Icons.local_fire_department_outlined,
                                      ),
                                      _iconCol(
                                        'soldWithPaper',
                                        Icons.receipt_long_outlined,
                                      ),
                                      _col('rate', width: 90),
                                      _col('manufactureYear', width: 90),
                                      _col('productModel', width: 120),
                                      _col('productRotationDate', width: 130),
                                      _iconCol(
                                        'quickEditAction',
                                        Icons.edit_outlined,
                                      ),
                                    ],
                                    rows: rows
                                        .map((row) =>
                                            _row(row, isCompact: isCompact))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

  DataColumn _col(String key, {double width = 100}) {
    return DataColumn(
      label: Tooltip(
        message: key.tr,
        child: SizedBox(
          width: width,
          child: Text(
            key.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ),
    );
  }

  DataColumn _iconCol(String key, IconData icon) {
    return DataColumn(
      label: Tooltip(
        message: key.tr,
        child: SizedBox(
          width: 40,
          child: Center(child: Icon(icon, size: 18)),
        ),
      ),
    );
  }

  DataRow _row(
    QuickEditProductRowState row, {
    required bool isCompact,
  }) {
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
        if (!isCompact) ...[
          DataCell(_field(row, row.nameEngController, width: 180)),
          DataCell(_field(row, row.nameAbreeController, width: 180)),
          DataCell(_field(row, row.descriptionArController, width: 260)),
        ],
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
        DataCell(_dateField(row, row.rotationDateController, width: 140)),
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

  Widget _dateField(
    QuickEditProductRowState row,
    TextEditingController textController, {
    double width = 130,
  }) {
    return Obx(() {
      if (!row.isEditing.value) {
        return InkWell(
          onTap: () async {
            final picked = await _pickDate(textController.text);
            if (picked == null) return;
            controller.editQuickEditRow(row);
            textController.text = _formatDate(picked);
          },
          child: _readonly(textController.text, width: width),
        );
      }
      return SizedBox(
        width: width,
        child: TextField(
          controller: textController,
          readOnly: true,
          onTap: () async {
            final picked = await _pickDate(textController.text);
            if (picked == null) return;
            textController.text = _formatDate(picked);
          },
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_month_outlined, size: 18),
          ),
        ),
      );
    });
  }

  Future<DateTime?> _pickDate(String currentValue) {
    final current = _parseDate(currentValue) ?? DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
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

DateTime? _parseDate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return DateTime.tryParse(trimmed);
}

String _formatDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

class _QuickEditScrollBehavior extends MaterialScrollBehavior {
  const _QuickEditScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
