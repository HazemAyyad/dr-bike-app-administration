import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/product_details_model.dart';
import '../controllers/stock_controller.dart';

class ProductSaleStatusCard extends StatefulWidget {
  const ProductSaleStatusCard({Key? key, required this.product})
      : super(key: key);

  final ProductDetailsModel product;

  @override
  State<ProductSaleStatusCard> createState() => _ProductSaleStatusCardState();
}

class _ProductSaleStatusCardState extends State<ProductSaleStatusCard> {
  bool _saving = false;

  Future<void> _change(bool blocked) async {
    setState(() => _saving = true);
    try {
      await Get.find<StockController>()
          .setProductSaleBlocked(widget.product, blocked);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = widget.product.isSaleBlocked;
    return Card(
      margin: EdgeInsets.zero,
      child: SwitchListTile.adaptive(
        value: blocked,
        onChanged: _saving ? null : _change,
        secondary: _saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(blocked ? Icons.block : Icons.shopping_cart_outlined,
                color: blocked ? Theme.of(context).colorScheme.error : null),
        title: const Text('ممنوع من البيع'),
        subtitle: Text(blocked
            ? 'موقوف عن المبيعات والطلبات الجديدة. الفواتير السابقة محفوظة.'
            : 'مسموح بالبيع. تغيير الحالة لا يغيّر المخزون أو التكلفة.'),
      ),
    );
  }
}
