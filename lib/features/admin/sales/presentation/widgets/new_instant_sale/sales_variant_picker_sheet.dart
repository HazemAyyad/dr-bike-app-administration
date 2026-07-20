import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../../core/helpers/show_net_image.dart';
import '../../../data/models/customer_product_price_history_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_variant_model.dart';
import '../../controllers/sales_controller.dart';
import '../../models/instant_sale_cart_line.dart';
import '../../utils/product_image_viewer.dart';
import '../../../../sales_orders/data/models/sales_order_model.dart';
import '../../../../sales_orders/presentation/controllers/sales_orders_controller.dart';
import '../../../../sales_orders/presentation/utils/sales_order_stock_context.dart';
import '../../utils/sales_amount_format.dart';

class SalesVariantPickerResult {
  final ProductColorVariant variant;
  final ProductSizeVariant size;
  final int quantity;
  final double unitPrice;

  const SalesVariantPickerResult({
    required this.variant,
    required this.size,
    required this.quantity,
    required this.unitPrice,
  });
}

Future<List<SalesVariantPickerResult>?> showSalesVariantPickerSheet({
  required BuildContext context,
  required ProductModel product,
  List<InstantSaleCartLine> initialLines = const [],
}) {
  return showModalBottomSheet<List<SalesVariantPickerResult>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SalesVariantPickerSheet(
      product: product,
      initialLines: initialLines,
    ),
  );
}

class _VariantDraft {
  _VariantDraft({
    required this.size,
    required this.variant,
    required String price,
    InstantSaleCartLine? initialLine,
  })  : quantityController = TextEditingController(
          text: initialLine?.quantityText.isNotEmpty == true
              ? initialLine!.quantityText
              : '1',
        ),
        priceController = TextEditingController(
          text: initialLine?.priceText.isNotEmpty == true
              ? initialLine!.priceText
              : price,
        ),
        selected = initialLine != null,
        priceEdited = initialLine?.priceText.isNotEmpty == true;

  final ProductSizeVariant size;
  final ProductColorVariant variant;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  bool selected;
  bool priceEdited;
  bool loadingPrice = false;

  int get quantity => int.tryParse(quantityController.text.trim()) ?? 0;

  double get unitPrice => SalesAmountFormat.parse(priceController.text);

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
  }
}

class _SalesVariantPickerSheet extends StatefulWidget {
  const _SalesVariantPickerSheet({
    required this.product,
    required this.initialLines,
  });

  final ProductModel product;
  final List<InstantSaleCartLine> initialLines;

  @override
  State<_SalesVariantPickerSheet> createState() =>
      _SalesVariantPickerSheetState();
}

class _SalesVariantPickerSheetState extends State<_SalesVariantPickerSheet> {
  late final List<_VariantDraft> _drafts;

  bool get _isAdjustmentSale =>
      Get.find<SalesController>().isAdjustmentInstantSale;

  SalesController get _sales => Get.find<SalesController>();

  @override
  void initState() {
    super.initState();
    _drafts = [
      for (final size in widget.product.sizes)
        for (final variant in size.colorSizes)
          _VariantDraft(
            size: size,
            variant: variant,
            price: _formatUnitPrice(_defaultUnitPrice(variant)),
            initialLine: _initialLineFor(variant),
          ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDefaultPrices());
  }

  InstantSaleCartLine? _initialLineFor(ProductColorVariant variant) {
    for (final line in widget.initialLines) {
      if (!line.isDisposed && line.sizeColorId == variant.id) return line;
    }
    return null;
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  double _defaultUnitPrice(ProductColorVariant variant, {int quantity = 1}) {
    return _sales.catalogUnitPriceForProduct(
      widget.product,
      quantity: quantity,
      variantRetailPrice: variant.normailPrice,
      variantWholesalePrice: variant.wholesalePrice,
    );
  }

  static String _formatUnitPrice(double price) {
    if (price <= 0) return '';
    if (price == price.roundToDouble()) return price.toInt().toString();
    return price.toStringAsFixed(2);
  }

  int get _selectedCount => _drafts.where((draft) => draft.selected).length;

  Future<void> _loadDefaultPrices() async {
    for (final draft in _drafts) {
      await _refreshDraftAutoPrice(draft);
    }
  }

  Future<void> _refreshDraftAutoPrice(_VariantDraft draft) async {
    if (draft.priceEdited) return;
    setState(() => draft.loadingPrice = true);
    final price = await _sales.resolveDefaultUnitPrice(
      widget.product,
      quantity: draft.quantity < 1 ? 1 : draft.quantity,
      sizeColorId: draft.variant.id,
      variantRetailPrice: draft.variant.normailPrice,
      variantWholesalePrice: draft.variant.wholesalePrice,
    );
    if (!mounted || draft.priceEdited) return;
    setState(() {
      draft.loadingPrice = false;
      if (price != null && price.isNotEmpty) {
        draft.priceController.text = price;
      }
    });
  }

  String? _stockHintFor(_VariantDraft draft) =>
      SalesOrderStockContext.controller?.stockHintForProduct(
        widget.product.id,
        sizeColorId: int.tryParse(draft.variant.id),
      );

  ProductStockAvailabilityModel? _orderStockFor(_VariantDraft draft) {
    if (!SalesOrderStockContext.isActive) return null;
    return SalesOrderStockContext.controller?.availabilityForProduct(
      widget.product.id,
      sizeColorId: int.tryParse(draft.variant.id),
    );
  }

  String _stockLabelFor(_VariantDraft draft) {
    final orderStock = _orderStockFor(draft);
    if (orderStock != null && orderStock.hasReservation) {
      return 'salesOrderPickerVariantStock'.trParams({
        'available': '${orderStock.availableQty}',
        'reserved': '${orderStock.reservedQty}',
      });
    }
    return '${draft.variant.stock}';
  }

  Future<void> _confirm() async {
    final selected = _drafts.where((draft) => draft.selected).toList();
    if (selected.isEmpty) {
      Get.snackbar('error'.tr, 'selectSizeColor'.tr);
      return;
    }

    for (final draft in selected) {
      if (draft.quantity < 1) {
        Get.snackbar('error'.tr, 'invalidQuantity'.tr);
        return;
      }
      if (draft.unitPrice < 0) {
        Get.snackbar('error'.tr, 'priceRequired'.tr);
        return;
      }
      if (draft.quantity > draft.variant.stock && !_isAdjustmentSale) {
        if (_sales.salesOrderStockMode.value) {
          Get.snackbar('error'.tr, 'out_of_stock_products'.tr);
          return;
        }
        final ok = await _sales.confirmInstantSaleNegativeStockIfNeeded(
          context: context,
          productName:
              '${widget.product.nameAr} - ${draft.size.size} / ${draft.variant.colorAr}',
          stock: draft.variant.stock,
          requestedQty: draft.quantity,
        );
        if (!ok) return;
      }
    }

    if (SalesOrderStockContext.isActive) {
      final sales = Get.find<SalesController>();
      if (sales.shouldWarnReservedStock) {
        final orders = SalesOrderStockContext.controller ??
            Get.find<SalesOrdersController>();
        for (final draft in selected) {
          final ok = await orders.confirmReservedStockBeforeAdd(
            productId: widget.product.id,
            productName: widget.product.nameAr,
            sizeColorId: int.tryParse(draft.variant.id),
            requestedQty: draft.quantity,
          );
          if (!ok) return;
        }
      }
    }

    if (!mounted) return;
    if (!context.mounted) return;
    Navigator.of(context).pop(
      selected
          .map(
            (draft) => SalesVariantPickerResult(
              variant: draft.variant,
              size: draft.size,
              quantity: draft.quantity,
              unitPrice: draft.unitPrice,
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final cs = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight * 0.88),
        margin: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
        decoration: BoxDecoration(
          color: AdminUiColors.cardBackground(context),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 6.w, 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'selectSizeColor'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: cs.onSurface),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  widget.product.nameAr,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                itemCount: _drafts.length,
                separatorBuilder: (_, __) => SizedBox(height: 6.h),
                itemBuilder: (context, index) {
                  return _variantRow(context, _drafts[index]);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 12.h),
              child: FilledButton(
                onPressed: _selectedCount > 0 ? _confirm : null,
                style: FilledButton.styleFrom(
                  minimumSize: Size(double.infinity, 46.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  '${'addToCart'.tr} ($_selectedCount)',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 15.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _variantRow(BuildContext context, _VariantDraft draft) {
    final cs = Theme.of(context).colorScheme;
    final outOfStock = draft.variant.stock < 1 && !_isAdjustmentSale;
    final blockedOutOfStock = outOfStock && _sales.salesOrderStockMode.value;
    final selected = draft.selected;
    final hint = _stockHintFor(draft);

    return InkWell(
      onTap: blockedOutOfStock
          ? null
          : () => setState(() => draft.selected = !draft.selected),
      borderRadius: BorderRadius.circular(12.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.08)
              : AdminUiColors.subtleOverlay(context),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? cs.primary : Colors.grey.shade300,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _variantImage(context, draft),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '${draft.size.size} / ${draft.variant.colorAr}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: blockedOutOfStock
                                        ? Colors.grey
                                        : cs.onSurface,
                                  ),
                        ),
                      ),
                      Checkbox(
                        value: selected,
                        onChanged: blockedOutOfStock
                            ? null
                            : (value) => setState(
                                  () => draft.selected = value ?? false,
                                ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${'stock'.tr}: ${_stockLabelFor(draft)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: blockedOutOfStock
                                ? Colors.red.shade700
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showPriceHistory(draft),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 28.w,
                          minHeight: 24.h,
                        ),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'instantSaleLastPrices'.tr,
                        icon: Icon(Icons.history, size: 16.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  _priceSourceText(context, draft),
                  if (hint != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.deepOrange.shade800,
                        height: 1.2,
                      ),
                    ),
                  ],
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Expanded(
                        child: _numberField(
                          controller: draft.quantityController,
                          label: 'quantity'.tr,
                          enabled: !blockedOutOfStock,
                          onChanged: (_) {
                            if (!selected) {
                              setState(() => draft.selected = true);
                            }
                            _refreshDraftAutoPrice(draft);
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _numberField(
                          controller: draft.priceController,
                          label: 'price'.tr,
                          enabled: !blockedOutOfStock,
                          onChanged: (_) {
                            draft.priceEdited = true;
                            if (!selected) {
                              setState(() => draft.selected = true);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _variantImage(BuildContext context, _VariantDraft draft) {
    final imageUrl = draft.variant.imageUrl.trim().isNotEmpty
        ? draft.variant.imageUrl
        : widget.product.preferredImageUrl;
    final size = 74.w;

    return GestureDetector(
      onTap: imageUrl.isEmpty
          ? null
          : () => openProductImageViewer(context, imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: size,
          height: size,
          color: AdminUiColors.inputFill(context),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  ShowNetImage.getThumbnailPhoto(imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.palette_outlined,
                    size: 34.sp,
                    color: Colors.grey.shade600,
                  ),
                )
              : Icon(
                  Icons.palette_outlined,
                  size: 34.sp,
                  color: Colors.grey.shade600,
                ),
        ),
      ),
    );
  }

  Widget _priceSourceText(BuildContext context, _VariantDraft draft) {
    if (draft.loadingPrice) {
      return Text(
        'loading'.tr,
        style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
      );
    }
    final tierPrice = widget.product.tierPriceForQuantity(draft.quantity);
    if (tierPrice != null && tierPrice > 0) {
      return Text(
        '${'quantity'.tr}: ${draft.quantity} / ${SalesAmountFormat.displayShekel(tierPrice)}',
        style: TextStyle(fontSize: 11.sp, color: Colors.green.shade800),
      );
    }
    if (_sales.isWholesalePartner && draft.variant.wholesalePrice > 0) {
      return Text(
        '${'price'.tr}: ${SalesAmountFormat.displayShekel(draft.variant.wholesalePrice)}',
        style: TextStyle(fontSize: 11.sp, color: Colors.blueGrey.shade700),
      );
    }
    return Text(
      '${'price'.tr}: ${SalesAmountFormat.displayShekel(draft.variant.normailPrice)}',
      style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
    );
  }

  Future<void> _showPriceHistory(_VariantDraft draft) async {
    final history = await _sales.fetchLinePriceHistory(
      productId: widget.product.id,
      sizeColorId: draft.variant.id,
    );
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VariantPriceHistorySheet(
        title: '${draft.size.size} / ${draft.variant.colorAr}',
        history: history,
        onApply: (price) {
          setState(() {
            draft.selected = true;
            draft.priceEdited = true;
            draft.priceController.text = _formatUnitPrice(price);
          });
        },
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: AdminUiColors.inputFill(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }
}

class _VariantPriceHistorySheet extends StatelessWidget {
  const _VariantPriceHistorySheet({
    required this.title,
    required this.history,
    required this.onApply,
  });

  final String title;
  final CustomerProductPriceHistory? history;
  final ValueChanged<double> onApply;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();
    final entries = history?.entries ?? const <CustomerProductPriceEntry>[];
    final hasPartner = controller.hasPickerPartner;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        constraints: BoxConstraints(maxHeight: 0.55.sh),
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: AdminUiColors.cardBackground(context),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hasPartner
                  ? 'instantSaleLastPricesTitle'.tr
                  : 'instantSaleRecentSalesTitle'.tr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 10.h),
            if (entries.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 18.h),
                child: Text(
                  hasPartner
                      ? 'instantSaleNoPriceHistory'.tr
                      : 'instantSaleNoRecentSales'.tr,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => Divider(height: 1.h),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        SalesAmountFormat.displayShekel(entry.cost),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${'billNumber'.tr}: ${entry.invoiceId}'
                        '${entry.soldAt.isNotEmpty ? '\n${entry.soldAt}' : ''}',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      trailing: Icon(Icons.check_circle_outline, size: 20.sp),
                      onTap: () {
                        onApply(entry.cost);
                        Navigator.pop(context);
                        Get.snackbar(
                          'success'.tr,
                          'instantSalePriceApplied'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    );
                  },
                ),
              ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('close'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
