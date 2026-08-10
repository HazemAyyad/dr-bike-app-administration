import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_net_image.dart';
import '../../../sales/presentation/utils/product_image_viewer.dart';
import '../controllers/stock_controller.dart';
import 'stock_product_grid_layout.dart';

class QuickEditProductsTab extends StatefulWidget {
  const QuickEditProductsTab({Key? key}) : super(key: key);

  @override
  State<QuickEditProductsTab> createState() => _QuickEditProductsTabState();
}

class _QuickEditProductsTabState extends State<QuickEditProductsTab> {
  static const double _desktopTableWidth = 2960;
  static const double _mobileTableWidth = 2180;
  static const double _landscapeTableWidth = 1840;
  static const double _rowHeight = 58;
  static const double _headingHeight = 46;
  static const double _compactRowHeight = 42;
  static const double _compactHeadingHeight = 36;
  static const double _scrollbarThickness = 10;

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

      final isLandscapePhone = StockProductGridLayout.isPhoneLandscape(context);
      final viewportHeight = MediaQuery.sizeOf(context).height;
      final rowHeight = isLandscapePhone ? _compactRowHeight : _rowHeight;
      final headingHeight =
          isLandscapePhone ? _compactHeadingHeight : _headingHeight;
      final rowsHeight = rows.length * rowHeight + headingHeight;
      final tableHeight = rowsHeight.clamp(
        isLandscapePhone ? 180.0 : 240.0,
        (viewportHeight - (isLandscapePhone ? 150 : 245)).clamp(
          isLandscapePhone ? 220.0 : 320.0,
          isLandscapePhone ? 360.0 : 720.0,
        ),
      );
      final isCompact =
          isLandscapePhone || MediaQuery.sizeOf(context).width < 700;
      final tableWidth = isLandscapePhone
          ? _landscapeTableWidth
          : isCompact
              ? _mobileTableWidth
              : _desktopTableWidth;

      return Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          isLandscapePhone ? 2 : 6,
          12,
          isLandscapePhone ? 24 : 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _QuickEditFilterChip(
                  selected: !controller.quickEditOnlyUnmarked.value,
                  label: Text('quickEditAll'.tr),
                  onSelected: (_) =>
                      controller.quickEditOnlyUnmarked.value = false,
                  compact: isLandscapePhone,
                ),
                const SizedBox(width: 8),
                _QuickEditFilterChip(
                  selected: controller.quickEditOnlyUnmarked.value,
                  label: Text('quickEditUnmarkedToday'.tr),
                  onSelected: (_) =>
                      controller.quickEditOnlyUnmarked.value = true,
                  compact: isLandscapePhone,
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
            SizedBox(height: isLandscapePhone ? 4 : 8),
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
                                    headingRowHeight: headingHeight,
                                    dataRowMinHeight:
                                        isLandscapePhone ? 34 : 44,
                                    dataRowMaxHeight: rowHeight,
                                    columnSpacing: isLandscapePhone ? 8 : 12,
                                    horizontalMargin: isLandscapePhone ? 6 : 8,
                                    headingTextStyle: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontSize: isLandscapePhone ? 9 : 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                    dataTextStyle: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: isLandscapePhone ? 10 : 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    columns: [
                                      _iconCol(
                                        'quickEditMark',
                                        Icons.check_box_outlined,
                                      ),
                                      _col('productId',
                                          width: isLandscapePhone ? 46 : 54),
                                      _col('productCode',
                                          width: isLandscapePhone ? 74 : 86),
                                      _iconCol(
                                        'productImages',
                                        Icons.image_outlined,
                                      ),
                                      _col('productName',
                                          width: isLandscapePhone ? 138 : 168),
                                      if (!isCompact) ...[
                                        _col('productNameEn', width: 138),
                                        _col('productNameHe', width: 138),
                                        _col('productDetails', width: 190),
                                      ],
                                      _col('category',
                                          width: isLandscapePhone ? 88 : 104),
                                      _col('subCategories',
                                          width: isLandscapePhone ? 104 : 126),
                                      _col('storeLocationTab',
                                          width: isLandscapePhone ? 88 : 104),
                                      _col('retailPrice',
                                          width: isLandscapePhone ? 58 : 72),
                                      _col('wholesalePrice',
                                          width: isLandscapePhone ? 62 : 76),
                                      _col('productCost',
                                          width: isLandscapePhone ? 58 : 72),
                                      _col('minSalePrice',
                                          width: isLandscapePhone ? 62 : 76),
                                      _col('stock',
                                          width: isLandscapePhone ? 52 : 64),
                                      _col('minStock',
                                          width: isLandscapePhone ? 58 : 72),
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
                                      _col('rate',
                                          width: isLandscapePhone ? 50 : 60),
                                      _col('manufactureYear',
                                          width: isLandscapePhone ? 58 : 72),
                                      _col('productModel',
                                          width: isLandscapePhone ? 82 : 96),
                                      _col('rotationNumberField',
                                          width: isLandscapePhone ? 74 : 86),
                                      _iconCol(
                                        'quickEditAction',
                                        Icons.edit_outlined,
                                      ),
                                    ],
                                    rows: rows
                                        .map((row) => _row(
                                              row,
                                              isCompact: isCompact,
                                              isLandscapePhone:
                                                  isLandscapePhone,
                                            ))
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            textAlign: TextAlign.center,
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
          width: 46,
          child: Center(child: Icon(icon, size: 18)),
        ),
      ),
    );
  }

  DataRow _row(
    QuickEditProductRowState row, {
    required bool isCompact,
    required bool isLandscapePhone,
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
        DataCell(_field(
          row,
          row.productCodeController,
          width: isLandscapePhone ? 74 : 86,
          compact: isLandscapePhone,
        )),
        DataCell(_image(row.product.productImage, compact: isLandscapePhone)),
        DataCell(_field(
          row,
          row.nameArController,
          width: isLandscapePhone ? 138 : 168,
          compact: isLandscapePhone,
        )),
        if (!isCompact) ...[
          DataCell(_field(row, row.nameEngController, width: 138)),
          DataCell(_field(row, row.nameAbreeController, width: 138)),
          DataCell(_field(row, row.descriptionArController, width: 190)),
        ],
        DataCell(_readonly(row.product.categoryName,
            width: isLandscapePhone ? 88 : 104, compact: isLandscapePhone)),
        DataCell(_readonly(row.product.subCategories,
            width: isLandscapePhone ? 104 : 126, compact: isLandscapePhone)),
        DataCell(_readonly(row.product.storeSectionName,
            width: isLandscapePhone ? 88 : 104, compact: isLandscapePhone)),
        DataCell(_number(row, row.normailPriceController,
            width: isLandscapePhone ? 58 : 72, compact: isLandscapePhone)),
        DataCell(_number(row, row.wholesalePriceController,
            width: isLandscapePhone ? 62 : 76, compact: isLandscapePhone)),
        DataCell(_number(row, row.costPriceController,
            width: isLandscapePhone ? 58 : 72, compact: isLandscapePhone)),
        DataCell(_number(row, row.minSalePriceController,
            width: isLandscapePhone ? 62 : 76, compact: isLandscapePhone)),
        DataCell(_number(row, row.stockController,
            integerOnly: true,
            width: isLandscapePhone ? 52 : 64,
            compact: isLandscapePhone)),
        DataCell(_number(row, row.minStockController,
            width: isLandscapePhone ? 58 : 72, compact: isLandscapePhone)),
        DataCell(_switch(row, (v) => row.isShow = v, () => row.isShow,
            compact: isLandscapePhone)),
        DataCell(_switch(row, (v) => row.isNewItem = v, () => row.isNewItem,
            compact: isLandscapePhone)),
        DataCell(
          _switch(row, (v) => row.isMoreSales = v, () => row.isMoreSales,
              compact: isLandscapePhone),
        ),
        DataCell(
          _switch(
            row,
            (v) => row.isSoldWithPaper = v,
            () => row.isSoldWithPaper,
            compact: isLandscapePhone,
          ),
        ),
        DataCell(_number(row, row.rateController,
            width: isLandscapePhone ? 50 : 60, compact: isLandscapePhone)),
        DataCell(_number(row, row.manufactureYearController,
            integerOnly: true,
            width: isLandscapePhone ? 58 : 72,
            compact: isLandscapePhone)),
        DataCell(_field(row, row.modelController,
            width: isLandscapePhone ? 82 : 96, compact: isLandscapePhone)),
        DataCell(_number(row, row.rotationDateController,
            width: isLandscapePhone ? 74 : 86, compact: isLandscapePhone)),
        DataCell(
          Obx(() {
            if (row.isSaving.value) {
              return const SizedBox(
                width: 32,
                height: 32,
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
              visualDensity: VisualDensity.compact,
              constraints: BoxConstraints.tightFor(
                width: isLandscapePhone ? 28 : 32,
                height: isLandscapePhone ? 28 : 32,
              ),
              padding: EdgeInsets.zero,
              icon: Icon(
                editing ? Icons.save_outlined : Icons.edit_outlined,
                size: isLandscapePhone ? 18 : null,
              ),
              onPressed: editing
                  ? () => controller.saveQuickEditRow(row)
                  : () => controller.editQuickEditRow(row),
            );
          }),
        ),
      ],
    );
  }

  Widget _readonly(
    String value, {
    double width = 100,
    bool compact = false,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _image(String raw, {bool compact = false}) {
    final size = compact ? 34.0 : 42.0;
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
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.network(
                  ShowNetImage.getPhoto(raw),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => SizedBox(
                    width: size,
                    height: size,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(color: Color(0xFFEFF2F5)),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: compact ? 16 : 18,
                      ),
                    ),
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
    bool compact = false,
  }) {
    return Obx(() {
      if (!row.isEditing.value) {
        return _readonly(textController.text, width: width, compact: compact);
      }
      return SizedBox(
        width: width,
        child: TextField(
          controller: textController,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
          ),
          minLines: 1,
          maxLines: width > 240 ? 2 : 1,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 6,
              vertical: compact ? 6 : 8,
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      );
    });
  }

  Widget _number(
    QuickEditProductRowState row,
    TextEditingController textController, {
    bool integerOnly = false,
    double width = 90,
    bool compact = false,
  }) {
    return Obx(() {
      if (!row.isEditing.value) {
        return _readonly(textController.text, width: width, compact: compact);
      }
      return SizedBox(
        width: width,
        child: TextField(
          controller: textController,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              integerOnly ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
            ),
            LengthLimitingTextInputFormatter(5),
          ],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 6,
              vertical: compact ? 6 : 8,
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      );
    });
  }

  Widget _switch(QuickEditProductRowState row, ValueChanged<bool> update,
      bool Function() value,
      {bool compact = false}) {
    return Obx(() {
      if (!row.isEditing.value) {
        return Icon(
          value() ? Icons.check_circle : Icons.remove_circle_outline,
          size: compact ? 16 : 18,
          color: value() ? Colors.green : Colors.grey,
        );
      }
      return StatefulBuilder(
        builder: (context, setState) {
          return Transform.scale(
            scale: compact ? 0.62 : 0.72,
            child: Switch(
              value: value(),
              onChanged: (next) {
                update(next);
                setState(() {});
              },
            ),
          );
        },
      );
    });
  }
}

class _QuickEditFilterChip extends StatelessWidget {
  const _QuickEditFilterChip({
    required this.selected,
    required this.label,
    required this.onSelected,
    required this.compact,
  });

  final bool selected;
  final Widget label;
  final ValueChanged<bool> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: label,
      onSelected: onSelected,
      labelStyle: compact
          ? Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)
          : null,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : null,
      visualDensity: compact ? VisualDensity.compact : null,
      materialTapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
    );
  }
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
