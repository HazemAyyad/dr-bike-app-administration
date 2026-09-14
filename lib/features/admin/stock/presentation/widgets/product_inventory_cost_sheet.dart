import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/app_failure_notice.dart';
import '../../../../../core/helpers/app_success_notice.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../data/datasources/stock_datasource.dart';
import '../../data/models/product_details_model.dart';
import 'inventory_cost_revaluation_sheet.dart';
import 'stock_variant_adjust_sheet.dart';

Future<void> showProductInventoryCostSheet({
  required BuildContext context,
  required String productId,
  required String productName,
  Future<void> Function()? onCostChanged,
}) async {
  if (!canViewCostPrice) return;
  AppDependencyRegistry.ensureStock();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProductInventoryCostSheet(
      productId: productId,
      productName: productName,
      onCostChanged: onCostChanged,
    ),
  );
}

class _ProductInventoryCostSheet extends StatefulWidget {
  const _ProductInventoryCostSheet({
    required this.productId,
    required this.productName,
    this.onCostChanged,
  });

  final String productId;
  final String productName;
  final Future<void> Function()? onCostChanged;

  @override
  State<_ProductInventoryCostSheet> createState() =>
      _ProductInventoryCostSheetState();
}

class _ProductInventoryCostSheetState
    extends State<_ProductInventoryCostSheet> {
  late final StockDatasource datasource;
  ProductDetailsModel? product;
  String? error;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    datasource = Get.find<StockDatasource>();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      final result =
          await datasource.getProductDetails(productId: widget.productId);
      if (!mounted) return;
      setState(() {
        product = result;
        error = null;
        loading = false;
      });
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.errorModel.errorMessage;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'تعذر تحميل تفاصيل تكلفة المخزون.';
        loading = false;
      });
    }
  }

  String _money(double? value, String currency) =>
      value == null ? '—' : '${value.toStringAsFixed(2)} $currency';

  String _qty(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  Future<void> _initializeMissingCost() async {
    final currentProduct = product;
    final inventory = currentProduct?.inventory;
    if (currentProduct == null || inventory == null || saving) return;

    String? sizeColorId;
    String? subtitle;
    var currency = inventory.currency;
    var missingQuantity = inventory.missingCostQuantity;

    if (inventory.hasVariants) {
      final target = await showStockVariantAdjustSheet(
        context: context,
        product: currentProduct,
      );
      if (target == null || !mounted) return;
      final identity = inventory.variants.firstWhereOrNull(
        (item) => item.sizeColorId == target.sizeColorId,
      );
      if (identity == null || identity.missingCostQuantity <= 0.0001) {
        AppFailureNotice.show(
          title: 'تنبيه',
          message: 'هذا المتغير مغطى بالتكلفة؛ اختر متغيرًا ناقص التكلفة.',
        );
        return;
      }
      sizeColorId = target.sizeColorId;
      subtitle = target.subtitle;
      currency = identity.currency;
      missingQuantity = identity.missingCostQuantity;
    }

    final result = await showInventoryCostRevaluationSheet(
      context: context,
      title: currentProduct.nameAr,
      subtitle: [
        if (subtitle != null) subtitle,
        'الكمية الناقصة: ${_qty(missingQuantity)}',
      ].join(' • '),
      currency: currency,
      initializeMissingCost: true,
    );
    if (result == null || !mounted) return;

    try {
      setState(() => saving = true);
      await datasource.initializeProductInventoryCost(
        productId: currentProduct.id,
        sizeColorId: sizeColorId,
        unitCost: result.newUnitCost,
        reason: result.reason,
        notes: result.notes,
        currency: currency,
      );
      await _load();
      await widget.onCostChanged?.call();
      AppSuccessNotice.show(
        title: 'success'.tr,
        message: 'تم تسجيل تكلفة المخزون الناقصة بنجاح.',
      );
    } on ServerException catch (e) {
      AppFailureNotice.show(
        title: 'error'.tr,
        message: e.errorModel.errorMessage,
      );
    } catch (_) {
      AppFailureNotice.show(
        title: 'error'.tr,
        message: 'تعذر تسجيل تكلفة المخزون.',
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = product?.inventory;
    final method = inventory?.costingMethod == 'moving_average'
        ? 'المتوسط المتحرك'
        : 'FIFO';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        padding: EdgeInsets.all(16.w),
        constraints: BoxConstraints(maxHeight: 0.78.sh),
        decoration: BoxDecoration(
          color: AdminUiColors.cardBackground(context),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'تكلفة المخزون — ${product?.nameAr ?? widget.productName}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    Text(error!, textAlign: TextAlign.center),
                    TextButton(
                        onPressed: _load, child: const Text('إعادة المحاولة')),
                  ],
                ),
              )
            else if (inventory == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'لا تملك صلاحية عرض تكلفة المخزون أو لا توجد بيانات تكلفة متاحة.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CostRow(
                          'الكمية الحالية', _qty(inventory.quantityOnHand)),
                      _CostRow('طريقة التكلفة', method),
                      _CostRow(
                        'قيمة المخزون',
                        _money(inventory.inventoryValue, inventory.currency),
                      ),
                      _CostRow(
                        'متوسط تكلفة الوحدة',
                        _money(inventory.averageUnitCost, inventory.currency),
                      ),
                      if (inventory.costingMethod == 'fifo')
                        _CostRow(
                          'تكلفة وحدة FIFO التالية',
                          _money(
                              inventory.nextFifoUnitCost, inventory.currency),
                        ),
                      if (!inventory.coverageComplete)
                        Container(
                          margin: EdgeInsets.only(top: 8.h),
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'يوجد ${_qty(inventory.missingCostQuantity)} وحدة بلا تغطية تكلفة.',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      if (inventory.variants.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        const Text(
                          'تكلفة المتغيرات',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        ...inventory.variants.map(
                          (variant) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${variant.sizeLabel} / ${variant.colorLabel}',
                            ),
                            subtitle: Text(
                              variant.coverageComplete
                                  ? 'مغطى بالكامل'
                                  : '${_qty(variant.missingCostQuantity)} وحدة بلا تكلفة',
                              style: TextStyle(
                                color: variant.coverageComplete
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            trailing: Text(
                              _money(variant.averageUnitCost, variant.currency),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                      if (!inventory.coverageComplete &&
                          canAdjustInventoryCost) ...[
                        SizedBox(height: 12.h),
                        FilledButton.icon(
                          onPressed: saving ? null : _initializeMissingCost,
                          icon: saving
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.price_change_outlined),
                          label: const Text('إدخال سعر التكلفة الناقص'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          SizedBox(width: 12.w),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
