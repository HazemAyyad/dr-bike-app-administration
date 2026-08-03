import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/widgets/skeleton_loading.dart';
import '../../data/models/all_stock_products_model.dart';
import '../../domain/product_location_utils.dart';
import '../controllers/stock_controller.dart';
import '../../../sales/presentation/utils/product_image_viewer.dart';
import 'product_card.dart';
import '../../../../../routes/app_routes.dart';
import 'stock_product_grid_layout.dart';
import 'stock_results_count_banner.dart';

class StockLocationTab extends GetView<StockController> {
  const StockLocationTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sections = controller.storeSections
          .where((s) => s.isActive)
          .toList(growable: false);
      final selectedSectionId = controller.selectedLocationSectionId.value;
      final hasLocationFilter =
          selectedSectionId != null && selectedSectionId.isNotEmpty;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'manageStoreSections'.tr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            SizedBox(height: 8.h),
            OutlinedButton.icon(
              onPressed: () async {
                await Get.toNamed(AppRoutes.STORESECTIONSSETTINGSSCREEN);
                await controller.refreshAfterStoreSectionsChanged();
              },
              icon: const Icon(Icons.settings_outlined),
              label: Text('manageStoreSections'.tr),
            ),
            SizedBox(height: 16.h),
            Text(
              'filterByStoreLocation'.tr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 8.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      label: Text('all'.tr),
                      selected: selectedSectionId == null ||
                          selectedSectionId.isEmpty,
                      onSelected: (_) => controller.selectLocationFilter(null),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      avatar: const Icon(Icons.location_off_outlined, size: 16),
                      label: Text('noLocationAssigned'.tr),
                      selected:
                          selectedSectionId == kUnassignedStoreSectionFilterId,
                      onSelected: (_) {
                        if (selectedSectionId ==
                            kUnassignedStoreSectionFilterId) {
                          controller.selectLocationFilter(null);
                        } else {
                          controller.selectLocationFilter(
                            kUnassignedStoreSectionFilterId,
                          );
                        }
                      },
                    ),
                  ),
                  ...sections.map(
                    (s) => Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: ChoiceChip(
                        avatar: const Icon(Icons.place_outlined, size: 16),
                        label: Text(s.name),
                        selected: selectedSectionId == s.id,
                        onSelected: (_) {
                          if (selectedSectionId == s.id) {
                            controller.selectLocationFilter(null);
                          } else {
                            controller.selectLocationFilter(s.id);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            if (controller.canUseLocationQuickEditTable)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Obx(
                  () => IconButton(
                    tooltip: controller.locationTableView.value
                        ? 'locationCardsView'.tr
                        : 'locationTableView'.tr,
                    onPressed: () => controller.setLocationTableView(
                      !controller.locationTableView.value,
                    ),
                    icon: Icon(
                      controller.locationTableView.value
                          ? Icons.grid_view_rounded
                          : Icons.table_rows_outlined,
                    ),
                  ),
                ),
              ),
            if (!hasLocationFilter)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Text(
                  'selectSectionToViewProducts'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              )
            else if (controller.isLoading.value &&
                controller.locationFilterProducts.isEmpty)
              controller.locationTableView.value
                  ? const _LocationProductsTableSkeleton()
                  : const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
            else ...[
              StockResultsCountBanner(
                count: controller.locationFilterTotalCount.value,
              ),
              if (controller.locationFilterProducts.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Text(
                    'noData'.tr,
                    textAlign: TextAlign.center,
                  ),
                )
              else if (controller.locationTableView.value)
                _LocationProductsTable(
                  products: controller.locationFilterProducts.toList(),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: StockProductGridLayout.delegate(
                    context: context,
                    aspectRatio: StockProductGridLayout.aspectRatioForTab(
                      0,
                      context: context,
                    ),
                  ),
                  itemCount: controller.locationFilterProducts.length,
                  itemBuilder: (context, index) {
                    final product = controller.locationFilterProducts[index];
                    return Align(
                      alignment: Alignment.topCenter,
                      child: BuildProductCard(
                        product: product,
                        isCloseouts: false,
                      ),
                    );
                  },
                ),
              if (controller.locationFilterProducts.isNotEmpty &&
                  controller.locationProductsLoadingMore.value)
                controller.locationTableView.value
                    ? const _LocationProductsTableSkeleton(rows: 3)
                    : const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
              SizedBox(height: 40.h),
            ],
          ],
        ),
      );
    });
  }
}

class _LocationProductsTable extends StatefulWidget {
  const _LocationProductsTable({required this.products});

  final List<AllStockProductsModel> products;

  @override
  State<_LocationProductsTable> createState() => _LocationProductsTableState();
}

class _LocationProductsTableState extends State<_LocationProductsTable> {
  static const double _tableWidth = 1660;
  static const double _scrollbarThickness = 12;

  final ScrollController _topHorizontalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  bool _syncingHorizontalScroll = false;

  @override
  void initState() {
    super.initState();
    _topHorizontalController.addListener(_syncTopToTable);
    _horizontalController.addListener(_syncTableToTop);
  }

  @override
  void dispose() {
    _topHorizontalController.removeListener(_syncTopToTable);
    _horizontalController.removeListener(_syncTableToTop);
    _topHorizontalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _syncTopToTable() {
    _syncHorizontalControllers(
      source: _topHorizontalController,
      target: _horizontalController,
    );
  }

  void _syncTableToTop() {
    _syncHorizontalControllers(
      source: _horizontalController,
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
    final next = source.offset.clamp(0.0, target.position.maxScrollExtent);
    if ((target.offset - next).abs() < 0.5) return;
    _syncingHorizontalScroll = true;
    target.jumpTo(next);
    _syncingHorizontalScroll = false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ScrollConfiguration(
        behavior: const _LocationTableScrollBehavior(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  child: const SizedBox(
                    width: _tableWidth,
                    height: 1,
                  ),
                ),
              ),
            ),
            Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: _scrollbarThickness,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _tableWidth,
                  child: DataTable(
                    headingRowHeight: 42,
                    dataRowMinHeight: 58,
                    dataRowMaxHeight: 74,
                    columnSpacing: 18.w,
                    horizontalMargin: 12.w,
                    columns: [
                      _iconCol('productImages', Icons.image_outlined),
                      _col('productId', width: 70),
                      _col('productCode', width: 120),
                      _col('productName', width: 240),
                      _col('retailPrice'),
                      _col('wholesalePrice'),
                      _col('productCost'),
                      _col('price'),
                      _col('minimumSale'),
                      _col('stock'),
                      _col('minStock'),
                      _col('discount'),
                      _col('rotationDateField', width: 140),
                    ],
                    rows: widget.products
                        .map(
                          (p) => DataRow(
                            cells: [
                              DataCell(_LocationProductImage(product: p)),
                              DataCell(Text(p.productId)),
                              DataCell(_EditablePriceCell(
                                product: p,
                                field: 'product_code',
                                value: p.productCode,
                                width: 120,
                                numeric: false,
                              )),
                              DataCell(_EditablePriceCell(
                                product: p,
                                field: 'nameAr',
                                value: p.name,
                                width: 240,
                                numeric: false,
                                maxLines: 2,
                              )),
                              DataCell(_EditablePriceCell(
                                product: p,
                                field: 'normailPrice',
                                value: _money(p.normailPrice),
                              )),
                              DataCell(_EditablePriceCell(
                                product: p,
                                field: 'wholesalePrice',
                                value: _money(p.wholesalePrice),
                              )),
                              DataCell(_EditablePriceCell(
                                product: p,
                                field: 'cost_price',
                                value: p.costPrice == null
                                    ? ''
                                    : _money(p.costPrice!),
                              )),
                              DataCell(_EditablePriceCell(
                                product: p,
                                field: 'price',
                                value: _money(p.price),
                              )),
                              DataCell(_EditablePriceCell(
                                product: p,
                                field: 'min_sale_price',
                                value: p.productMinSalePrice,
                              )),
                              DataCell(_EditablePriceCell(
                                product: p,
                                field: 'stock',
                                value: p.stock,
                              )),
                              DataCell(_EditablePriceCell(
                                product: p,
                                field: 'min_stock',
                                value: p.minStock,
                              )),
                              DataCell(_EditablePriceCell(
                                product: p,
                                field: 'discount',
                                value: p.discount,
                              )),
                              DataCell(_EditableDateCell(product: p)),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _money(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  DataColumn _col(String key, {double width = 96}) {
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
          width: 52,
          child: Center(child: Icon(icon, size: 18)),
        ),
      ),
    );
  }
}

class _LocationTableScrollBehavior extends MaterialScrollBehavior {
  const _LocationTableScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _LocationProductImage extends StatelessWidget {
  const _LocationProductImage({required this.product});

  final AllStockProductsModel product;

  @override
  Widget build(BuildContext context) {
    final raw = product.preferredImageUrl;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => openProductImageViewer(context, raw),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            ShowNetImage.getThumbnailPhoto(raw),
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Image.network(
              ShowNetImage.getPhoto(raw),
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableDateCell extends StatefulWidget {
  const _EditableDateCell({required this.product});

  final AllStockProductsModel product;

  @override
  State<_EditableDateCell> createState() => _EditableDateCellState();
}

class _EditableDateCellState extends State<_EditableDateCell> {
  late final TextEditingController _controller;

  StockController get controller => Get.find<StockController>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.product.rotationDate);
  }

  @override
  void didUpdateWidget(covariant _EditableDateCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.rotationDate != widget.product.rotationDate) {
      _controller.text = widget.product.rotationDate;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = _parseDate(_controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;

    final next = _formatDate(picked);
    _controller.text = next;
    await controller.saveLocationProductPrice(
      product: widget.product,
      field: 'rotation_date',
      value: next,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final saving = controller.isLocationPriceSaving(
        widget.product.productId,
        'rotation_date',
      );
      return SizedBox(
        width: 140,
        child: TextField(
          controller: _controller,
          readOnly: true,
          enabled: !saving,
          onTap: saving ? null : _pickDate,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: saving
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.calendar_month_outlined, size: 18),
          ),
        ),
      );
    });
  }
}

class _EditablePriceCell extends StatefulWidget {
  const _EditablePriceCell({
    required this.product,
    required this.field,
    required this.value,
    this.width = 96,
    this.numeric = true,
    this.maxLines = 1,
  });

  final AllStockProductsModel product;
  final String field;
  final String value;
  final double width;
  final bool numeric;
  final int maxLines;

  @override
  State<_EditablePriceCell> createState() => _EditablePriceCellState();
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

class _EditablePriceCellState extends State<_EditablePriceCell> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late String _lastSavedValue;

  StockController get controller => Get.find<StockController>();

  @override
  void initState() {
    super.initState();
    _lastSavedValue = widget.value;
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode()..addListener(_saveOnBlur);
  }

  @override
  void didUpdateWidget(covariant _EditablePriceCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _lastSavedValue = widget.value;
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_saveOnBlur);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _saveOnBlur() {
    if (!_focusNode.hasFocus) {
      _save();
    }
  }

  Future<void> _save() async {
    final next = _controller.text.trim();
    if (next == _lastSavedValue.trim()) return;
    await controller.saveLocationProductPrice(
      product: widget.product,
      field: widget.field,
      value: next,
    );
    _lastSavedValue = next;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final saving = controller.isLocationPriceSaving(
        widget.product.productId,
        widget.field,
      );
      return SizedBox(
        width: widget.width,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: !saving,
          keyboardType:
              widget.numeric ? TextInputType.number : TextInputType.text,
          inputFormatters: widget.numeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : null,
          minLines: 1,
          maxLines: widget.maxLines,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: saving
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
      );
    });
  }
}

class _LocationProductsTableSkeleton extends StatelessWidget {
  const _LocationProductsTableSkeleton({this.rows = 8});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            SkeletonBlock(width: double.infinity, height: 36.h, radius: 8),
            SizedBox(height: 10.h),
            for (var i = 0; i < rows; i++) ...[
              Row(
                children: [
                  SkeletonBlock(width: 52.w, height: 52.h, radius: 8),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 3,
                    child: SkeletonBlock(width: double.infinity, height: 16.h),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: SkeletonBlock(width: double.infinity, height: 32.h),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: SkeletonBlock(width: double.infinity, height: 32.h),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
          ],
        ),
      ),
    );
  }
}
