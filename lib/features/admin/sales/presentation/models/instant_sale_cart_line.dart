import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/product_model.dart';
import '../utils/sales_amount_format.dart';

/// One product line in the instant-sale cart (table + modal).
class InstantSaleCartLine {
  final String productId;
  final String productName;
  final String imageUrl;
  final int stock;
  final String? sizeColorId;
  final String? sizeId;
  final String? sizeLabel;
  final String? colorLabel;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final RxBool isProjectSale;
  final RxnString projectId;
  final RxDouble lineTotal;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  String get cartLineKey =>
      sizeColorId != null && sizeColorId!.isNotEmpty
          ? '$productId::$sizeColorId'
          : productId;

  String get displayName {
    if (sizeLabel != null &&
        sizeLabel!.isNotEmpty &&
        colorLabel != null &&
        colorLabel!.isNotEmpty) {
      return '$productName — $sizeLabel / $colorLabel';
    }
    return productName;
  }

  InstantSaleCartLine({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.stock,
    this.sizeColorId,
    this.sizeId,
    this.sizeLabel,
    this.colorLabel,
    String? initialQuantity,
    String? initialPrice,
    bool projectSale = false,
    String? initialProjectId,
  })  : quantityController = TextEditingController(text: initialQuantity ?? '1'),
        priceController = TextEditingController(text: initialPrice ?? ''),
        isProjectSale = projectSale.obs,
        projectId = RxnString(initialProjectId),
        lineTotal = 0.0.obs {
    quantityController.addListener(recalculateTotal);
    priceController.addListener(recalculateTotal);
    recalculateTotal();
  }

  factory InstantSaleCartLine.fromProduct(
    ProductModel product, {
    String? quantity,
    String? unitPrice,
    bool projectSale = false,
    String? projectId,
    String? sizeColorId,
    String? sizeId,
    String? sizeLabel,
    String? colorLabel,
    int? variantStock,
    String? variantImageUrl,
  }) {
    final price = unitPrice ??
        (product.unitPrice > 0
            ? _formatUnitPrice(product.unitPrice)
            : '');
    final resolvedStock = variantStock ?? (int.tryParse(product.stock) ?? 0);
    final resolvedImage = (variantImageUrl != null && variantImageUrl.isNotEmpty)
        ? variantImageUrl
        : product.imageUrl;

    return InstantSaleCartLine(
      productId: product.id,
      productName: product.nameAr,
      imageUrl: resolvedImage,
      stock: resolvedStock,
      sizeColorId: sizeColorId,
      sizeId: sizeId,
      sizeLabel: sizeLabel,
      colorLabel: colorLabel,
      initialQuantity: quantity ?? '1',
      initialPrice: price,
      projectSale: projectSale,
      initialProjectId: projectId,
    );
  }

  static String _formatUnitPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  void recalculateTotal() {
    if (_disposed) return;
    final qty = SalesAmountFormat.parse(quantityController.text);
    final unit = SalesAmountFormat.parse(priceController.text);
    lineTotal.value = qty * unit;
  }

  String get quantityText =>
      _disposed ? '' : quantityController.text.trim();

  String get priceText => _disposed ? '' : priceController.text.trim();

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    quantityController.removeListener(recalculateTotal);
    priceController.removeListener(recalculateTotal);
    quantityController.dispose();
    priceController.dispose();
  }
}
