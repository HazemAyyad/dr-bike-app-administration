import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';
import 'sales_order_shiply_address_fields.dart';

/// Shiply city + village + street + delivery fee on checkout / edit.
class SalesOrderShiplyAddressSection extends GetView<SalesOrdersController> {
  const SalesOrderShiplyAddressSection({
    Key? key,
    this.parcelPriceForFee = 0,
  }) : super(key: key);

  final double parcelPriceForFee;

  @override
  Widget build(BuildContext context) {
    return SalesOrderShiplyAddressFields(
      controller: controller,
      parcelPriceForFee: parcelPriceForFee,
    );
  }
}
