import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../data/models/product_stock_movement_model.dart';
import '../../domain/stock_movements_filters.dart';
import '../controllers/stock_controller.dart';
import '../widgets/product_stock_movements_widgets.dart';
import '../widgets/stock_movements_filter_sheet.dart';
import '../widgets/stock_quick_adjust_sheet.dart';
import '../widgets/stock_skeleton_widgets.dart';
import '../widgets/stock_variant_adjust_sheet.dart';

class ProductStockMovementsArgs {
  const ProductStockMovementsArgs({
    required this.productId,
    required this.productName,
    required this.currentStock,
    this.hasVariants = false,
  });

  final String productId;
  final String productName;
  final int currentStock;
  final bool hasVariants;

  factory ProductStockMovementsArgs.fromDynamic(dynamic raw) {
    if (raw is ProductStockMovementsArgs) return raw;
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return ProductStockMovementsArgs(
        productId: '${m['productId'] ?? ''}',
        productName: '${m['productName'] ?? ''}',
        currentStock: int.tryParse('${m['currentStock'] ?? 0}') ?? 0,
        hasVariants: m['hasVariants'] == true,
      );
    }
    return const ProductStockMovementsArgs(
      productId: '',
      productName: '',
      currentStock: 0,
    );
  }
}

class ProductStockMovementsScreen extends StatefulWidget {
  const ProductStockMovementsScreen({Key? key}) : super(key: key);

  @override
  State<ProductStockMovementsScreen> createState() =>
      _ProductStockMovementsScreenState();
}

class _ProductStockMovementsScreenState extends State<ProductStockMovementsScreen> {
  late final ProductStockMovementsArgs args;
  StockMovementsPageResult? data;
  var loading = true;
  var pageLoading = false;
  var exporting = false;
  int page = 1;
  StockMovementsFilters filters = const StockMovementsFilters();
  static const _perPage = 50;

  StockController get c => Get.find<StockController>();

  @override
  void initState() {
    super.initState();
    args = ProductStockMovementsArgs.fromDynamic(Get.arguments);
    _load(pageNum: 1);
  }

  Future<void> _load({int pageNum = 1, bool refresh = false}) async {
    if (args.productId.isEmpty) {
      setState(() {
        loading = false;
        data = null;
      });
      return;
    }
    setState(() {
      if (refresh || data == null) {
        loading = true;
      } else {
        pageLoading = true;
      }
    });
    final result = await c.loadStockMovements(
      productId: args.productId,
      page: pageNum,
      perPage: _perPage,
      dateFrom: filters.apiDateFrom,
      dateTo: filters.apiDateTo,
      type: filters.type,
    );
    if (!mounted) return;
    setState(() {
      loading = false;
      pageLoading = false;
      data = result;
      page = pageNum;
    });
  }

  Future<void> _openFilter() async {
    final picked = await showStockMovementsFilterSheet(
      context: context,
      initial: filters,
    );
    if (picked == null) return;
    setState(() => filters = picked);
    await _load(pageNum: 1, refresh: true);
  }

  Future<List<ProductStockMovementModel>> _loadAllForExport() async {
    final all = <ProductStockMovementModel>[];
    var currentPage = 1;
    var lastPage = 1;
    do {
      final chunk = await c.loadStockMovements(
        productId: args.productId,
        page: currentPage,
        perPage: 100,
        dateFrom: filters.apiDateFrom,
        dateTo: filters.apiDateTo,
        type: filters.type,
      );
      if (chunk == null) break;
      all.addAll(chunk.movements);
      lastPage = chunk.lastPage;
      currentPage++;
    } while (currentPage <= lastPage);
    return all;
  }

  Future<void> _exportPdf() async {
    if (data == null || exporting) return;
    setState(() => exporting = true);
    try {
      final movements = await _loadAllForExport();
      if (!mounted) return;
      await exportStockMovementsPdf(
        context: context,
        productName: args.productName,
        summary: data!.summary,
        movements: movements,
        filters: filters,
      );
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> _openQuickAdjust() async {
    if (args.hasVariants) {
      await c.getProductDetails(productId: args.productId);
      final product = c.productDetails.value;
      if (product == null || !mounted) return;
      final target = await showStockVariantAdjustSheet(
        context: context,
        product: product,
      );
      if (target == null || !mounted) return;
      final pick = await showStockQuickAdjustSheet(
        context: context,
        title: args.productName,
        subtitle: target.subtitle,
        currentStock: target.currentStock,
      );
      if (pick == null) return;
      final ok = await c.adjustProductStock(
        productId: args.productId,
        sizeColorId: target.sizeColorId,
        quantity: pick.quantity,
        note: pick.note,
      );
      if (ok) await _load(pageNum: 1, refresh: true);
      return;
    }

    final pick = await showStockQuickAdjustSheet(
      context: context,
      title: args.productName,
      currentStock: data?.summary.currentStock ?? args.currentStock,
    );
    if (pick == null) return;
    final ok = await c.adjustProductStock(
      productId: args.productId,
      quantity: pick.quantity,
      note: pick.note,
    );
    if (ok) await _load(pageNum: 1, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final summary = data?.summary;
    final movements = data?.movements ?? [];

    return Scaffold(
      backgroundColor: AdminUiColors.scaffoldBackground(context),
      appBar: CustomAppBar(
        title: 'stockMovements',
        action: false,
        actions: [
          if (exporting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'stockMovementsPdf'.tr,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: data == null ? null : _exportPdf,
            ),
          IconButton(
            tooltip: 'addStockQuick'.tr,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _openQuickAdjust,
          ),
        ],
      ),
      body: loading && data == null
          ? const SingleChildScrollView(
              child: ProductStockMovementsPageSkeleton(),
            )
          : data == null
              ? const Center(child: ShowNoData())
              : RefreshIndicator(
                  onRefresh: () => _load(pageNum: 1, refresh: true),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    children: [
                      if (args.productName.trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: Text(
                            args.productName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      if (summary != null) ...[
                        StockMovementSummaryBar(summary: summary),
                        StockMovementsToolbar(
                          filters: filters,
                          total: data!.total,
                          onFilter: _openFilter,
                          onPrint: _exportPdf,
                          onQuickAdjust: _openQuickAdjust,
                        ),
                      ],
                      if (pageLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: ProductStockMovementsPageSkeleton(),
                        )
                      else if (movements.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.h),
                          child: Text(
                            'noData'.tr,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                          ),
                        )
                      else
                        StockMovementsTable(movements: movements),
                      if (data != null && data!.lastPage > 1 && !pageLoading)
                        Padding(
                          padding: EdgeInsets.only(top: 12.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: page > 1
                                    ? () => _load(pageNum: page - 1)
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                              Text(
                                '$page / ${data!.lastPage} (${data!.total})',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              IconButton(
                                onPressed: page < data!.lastPage
                                    ? () => _load(pageNum: page + 1)
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
