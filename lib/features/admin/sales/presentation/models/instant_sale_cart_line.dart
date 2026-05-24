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
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final RxBool isProjectSale;
  final RxnString projectId;
  final RxDouble lineTotal;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  InstantSaleCartLine({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.stock,
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
  }) {
    final price = unitPrice ??
        (product.unitPrice > 0
            ? _formatUnitPrice(product.unitPrice)
            : '');
    return InstantSaleCartLine(
      productId: product.id,
      productName: product.nameAr,
      imageUrl: product.imageUrl,
      stock: int.tryParse(product.stock) ?? 0,
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
