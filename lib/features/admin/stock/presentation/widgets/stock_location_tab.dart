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
      final isLandscapePhone = StockProductGridLayout.isPhoneLandscape(context);
      final horizontalPadding = isLandscapePhone ? 12.0 : 16.w;
      final smallGap = isLandscapePhone ? 6.0 : 8.h;
      final sectionGap = isLandscapePhone ? 10.0 : 16.h;
      final sections = controller.storeSections
          .where((s) => s.isActive)
          .toList(growable: false);
      final selectedSectionId = controller.selectedLocationSectionId.value;
      final hasLocationFilter =
          selectedSectionId != null && selectedSectionId.isNotEmpty;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isLandscapePhone) ...[
              Text(
                'manageStoreSections'.tr,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              SizedBox(height: smallGap),
              OutlinedButton.icon(
                onPressed: () async {
                  await Get.toNamed(AppRoutes.STORESECTIONSSETTINGSSCREEN);
                  await controller.refreshAfterStoreSectionsChanged();
                },
                icon: const Icon(Icons.settings_outlined),
                label: Text('manageStoreSections'.tr),
              ),
              SizedBox(height: sectionGap),
              Text(
                'filterByStoreLocation'.tr,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: smallGap),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: isLandscapePhone ? 6 : 8.w),
                    child: _LocationChoiceChip(
                      label: Text('all'.tr),
                      selected: selectedSectionId == null ||
                          selectedSectionId.isEmpty,
                      onSelected: (_) => controller.selectLocationFilter(null),
                      compact: isLandscapePhone,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: isLandscapePhone ? 6 : 8.w),
                    child: _LocationChoiceChip(
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
                      compact: isLandscapePhone,
                    ),
                  ),
                  ...sections.map(
                    (s) => Padding(
                      padding:
                          EdgeInsets.only(right: isLandscapePhone ? 6 : 8.w),
                      child: _LocationChoiceChip(
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
                        compact: isLandscapePhone,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: sectionGap),
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
                padding: EdgeInsets.symmetric(
                    vertical: isLandscapePhone ? 12 : 24.h),
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
                  padding: EdgeInsets.symmetric(
                    vertical: isLandscapePhone ? 12 : 24.h,
                  ),
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
  static const double _scrollbarThickness = 10;

  final ScrollController _topHorizontalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  bool _syncingHorizontalScroll = false;

  @override
  void initState() {
    super.initState();
    _topHorizontalController.addListener(_syncTopToTable);
    _headerHorizontalController.addListener(_syncHeaderToOthers);
    _bodyHorizontalController.addListener(_syncBodyToOthers);
  }

  @override
  void dispose() {
    _topHorizontalController.removeListener(_syncTopToTable);
    _headerHorizontalController.removeListener(_syncHeaderToOthers);
    _bodyHorizontalController.removeListener(_syncBodyToOthers);
    _topHorizontalController.dispose();
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _syncTopToTable() {
    _syncHorizontalControllers(
      source: _topHorizontalController,
      targets: [_headerHorizontalController, _bodyHorizontalController],
    );
  }

  void _syncHeaderToOthers() {
    _syncHorizontalControllers(
      source: _headerHorizontalController,
      targets: [_topHorizontalController, _bodyHorizontalController],
    );
  }

  void _syncBodyToOthers() {
    _syncHorizontalControllers(
      source: _bodyHorizontalController,
      targets: [_topHorizontalController, _headerHorizontalController],
    );
  }

  void _syncHorizontalControllers({
    required ScrollController source,
    required List<ScrollController> targets,
  }) {
    if (_syncingHorizontalScroll || !source.hasClients) {
      return;
    }
    _syncingHorizontalScroll = true;
    for (final target in targets) {
      if (!target.hasClients) continue;
      final next = source.offset.clamp(0.0, target.position.maxScrollExtent);
      if ((target.offset - next).abs() < 0.5) continue;
      target.jumpTo(next);
    }
    _syncingHorizontalScroll = false;
  }

  @override
  Widget build(BuildContext context) {
    final isLandscapePhone = StockProductGridLayout.isPhoneLandscape(context);
    final tableWidth = isLandscapePhone ? 760.0 : 890.0;
    final columnSpacing = isLandscapePhone ? 6.0 : 8.w;
    final horizontalMargin = isLandscapePhone ? 8.0 : 12.w;
    final headingFontSize = isLandscapePhone ? 9.0 : 10.sp;
    final dataFontSize = isLandscapePhone ? 10.0 : 11.sp;
    final rowMinHeight = isLandscapePhone ? 34.0 : 42.0;
    final rowMaxHeight = isLandscapePhone ? 40.0 : 50.0;
    final tableHeight = (MediaQuery.sizeOf(context).height * 0.58).clamp(
      isLandscapePhone ? 180.0 : 260.0,
      isLandscapePhone ? 320.0 : 520.0,
    );

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
                  child: SizedBox(
                    width: tableWidth,
                    height: 1,
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              controller: _headerHorizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: DataTable(
                  headingRowHeight: isLandscapePhone ? 34 : 42,
                  dataRowMinHeight: 0,
                  dataRowMaxHeight: 0,
                  columnSpacing: columnSpacing,
                  horizontalMargin: horizontalMargin,
                  headingTextStyle:
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                          ),
                  columns: _columns(context),
                  rows: const [],
                ),
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: tableHeight,
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  child: Scrollbar(
                    controller: _bodyHorizontalController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: _scrollbarThickness,
                    child: SingleChildScrollView(
                      controller: _bodyHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: DataTable(
                          headingRowHeight: 0,
                          dataRowMinHeight: rowMinHeight,
                          dataRowMaxHeight: rowMaxHeight,
                          columnSpacing: columnSpacing,
                          horizontalMargin: horizontalMargin,
                          dataTextStyle:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: dataFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                          columns: _columns(context, hiddenLabels: true),
                          rows: widget.products
                              .map(
                                (p) => DataRow(
                                  cells: [
                                    DataCell(_LocationProductImage(product: p)),
                                    DataCell(Text(p.productId)),
                                    DataCell(_EditablePriceCell(
                                      product: p,
                                      field: 'nameAr',
                                      value: p.name,
                                      width: isLandscapePhone ? 132 : 154,
                                      numeric: false,
                                      maxLines: 2,
                                      compact: isLandscapePhone,
                                    )),
                                    DataCell(_EditablePriceCell(
                                      product: p,
                                      field: 'normailPrice',
                                      value: _money(p.normailPrice),
                                      width: isLandscapePhone ? 48 : 56,
                                      compact: isLandscapePhone,
                                    )),
                                    DataCell(_EditablePriceCell(
                                      product: p,
                                      field: 'min_sale_price',
                                      value: p.productMinSalePrice,
                                      width: isLandscapePhone ? 50 : 58,
                                      compact: isLandscapePhone,
                                    )),
                                    DataCell(_EditablePriceCell(
                                      product: p,
                                      field: 'wholesalePrice',
                                      value: _money(p.wholesalePrice),
                                      width: isLandscapePhone ? 50 : 58,
                                      compact: isLandscapePhone,
                                    )),
                                    DataCell(_EditablePriceCell(
                                      product: p,
                                      field: 'cost_price',
                                      value: p.costPrice == null
                                          ? ''
                                          : _money(p.costPrice!),
                                      width: isLandscapePhone ? 48 : 56,
                                      compact: isLandscapePhone,
                                    )),
                                    DataCell(_EditablePriceCell(
                                      product: p,
                                      field: 'stock',
                                      value: p.stock,
                                      width: isLandscapePhone ? 42 : 48,
                                      compact: isLandscapePhone,
                                    )),
                                    DataCell(_EditablePriceCell(
                                      product: p,
                                      field: 'min_stock',
                                      value: p.minStock,
                                      width: isLandscapePhone ? 46 : 54,
                                      compact: isLandscapePhone,
                                    )),
                                    DataCell(_EditablePriceCell(
                                      product: p,
                                      field: 'rotation_date',
                                      value: p.rotationDate,
                                      width: isLandscapePhone ? 50 : 58,
                                      compact: isLandscapePhone,
                                    )),
                                  ],
                                ),
                              )
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
    );
  }

  static String _money(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  List<DataColumn> _columns(
    BuildContext context, {
    bool hiddenLabels = false,
  }) {
    Widget label(String key, {double width = 96}) {
      final isLandscapePhone = StockProductGridLayout.isPhoneLandscape(context);
      final resolvedWidth = isLandscapePhone ? width * 0.86 : width;
      if (hiddenLabels) return SizedBox(width: resolvedWidth);
      return Tooltip(
        message: key.tr,
        child: SizedBox(
          width: resolvedWidth,
          child: Text(
            key.tr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    Widget iconLabel(String key, IconData icon) {
      final isLandscapePhone = StockProductGridLayout.isPhoneLandscape(context);
      final width = isLandscapePhone ? 46.0 : 64.0;
      if (hiddenLabels) return SizedBox(width: width);
      return Tooltip(
        message: key.tr,
        child: SizedBox(
          width: width,
          child: Center(child: Icon(icon, size: isLandscapePhone ? 16 : 18)),
        ),
      );
    }

    return [
      DataColumn(label: iconLabel('productImages', Icons.image_outlined)),
      DataColumn(label: label('productId', width: 48)),
      DataColumn(label: label('productName', width: 154)),
      DataColumn(label: label('retailPrice', width: 56)),
      DataColumn(label: label('minimumSale', width: 58)),
      DataColumn(label: label('wholesalePrice', width: 58)),
      DataColumn(label: label('productCost', width: 56)),
      DataColumn(label: label('stock', width: 48)),
      DataColumn(label: label('stockLocationMinStock', width: 54)),
      DataColumn(label: label('rotationDateField', width: 58)),
    ];
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
    final normalized = raw.trim().toLowerCase();
    final hasImage = normalized.isNotEmpty &&
        normalized != 'no image' &&
        normalized != 'null' &&
        normalized != 'undefined';
    if (!hasImage) {
      return const _LocationImagePlaceholder();
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => openProductImageViewer(context, raw),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            ShowNetImage.getThumbnailPhoto(raw),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Image.network(
              ShowNetImage.getPhoto(raw),
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                width: 44,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFEFF2F5)),
                  child: Icon(Icons.image_not_supported_outlined, size: 18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationImagePlaceholder extends StatelessWidget {
  const _LocationImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 44,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Color(0xFFEFF2F5)),
        child: Center(
          child: Icon(Icons.image_not_supported_outlined, size: 18),
        ),
      ),
    );
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
    this.compact = false,
  });

  final AllStockProductsModel product;
  final String field;
  final String value;
  final double width;
  final bool numeric;
  final int maxLines;
  final bool compact;

  @override
  State<_EditablePriceCell> createState() => _EditablePriceCellState();
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: widget.compact ? 10 : 11.sp,
                fontWeight: FontWeight.w700,
              ),
          keyboardType:
              widget.numeric ? TextInputType.number : TextInputType.text,
          inputFormatters: widget.numeric
              ? [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  LengthLimitingTextInputFormatter(5),
                ]
              : null,
          minLines: 1,
          maxLines: widget.maxLines,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 5 : 6.w,
              vertical: widget.compact ? 6 : 8.h,
            ),
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

class _LocationChoiceChip extends StatelessWidget {
  const _LocationChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.compact,
    this.avatar,
  });

  final Widget label;
  final Widget? avatar;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: avatar,
      label: label,
      selected: selected,
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
