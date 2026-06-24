import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/sales_order_model.dart';
import '../controllers/sales_orders_controller.dart';

/// تحذير الكمية المحجوزة — خلفية رمادية فاتحة ونص داكن.
Future<bool> showSalesOrderReservedStockDialog({
  required BuildContext context,
  required String message,
  String? details,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => AlertDialog(
      backgroundColor: SalesOrdersController.cardGray,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      title: Text(
        'salesOrderReservedStockTitle'.tr,
        style: TextStyle(
          color: SalesOrdersController.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 16.sp,
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          details == null || details.isEmpty ? message : '$message\n\n$details',
          style: TextStyle(
            color: SalesOrdersController.textSecondary,
            fontSize: 13.sp,
            height: 1.45,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(
            foregroundColor: SalesOrdersController.textSecondary,
          ),
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: SalesOrdersController.textPrimary,
          ),
          child: Text(
            'confirm'.tr,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

String formatReservedStockConflictLines(
  List<SalesOrderStockConflictModel> conflicts,
) {
  return conflicts.map(formatReservedStockConflictDetail).join('\n\n');
}

String formatReservedStockConflictDetail(SalesOrderStockConflictModel conflict) {
  final buffer = StringBuffer();
  buffer.writeln(
    '• ${conflict.productName}: '
    '${'salesOrderReservedQtyLine'.trParams({
      'reserved': '${conflict.reservedByOthers}',
      'available': '${conflict.available}',
      'requested': '${conflict.requestedQty}',
      'deficit': '${conflict.deficit}',
    })}',
  );

  if (conflict.reservingOrders.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('salesOrderReservedByOrdersTitle'.tr);
    for (final order in conflict.reservingOrders) {
      buffer.writeln(formatReservingOrderLine(order));
    }
  }

  return buffer.toString().trim();
}

String formatReservingOrderLine(SalesOrderReservingOrderModel order) {
  final serial = order.serialNumber?.trim();
  final serialLabel =
      (serial != null && serial.isNotEmpty) ? serial : '#${order.orderId}';
  final party = order.customerName?.trim();
  final String partyLabel;
  if (party != null && party.isNotEmpty) {
    final typeLabel = order.partyType == 'trader'
        ? 'buyerTrader'.tr
        : 'buyerCustomer'.tr;
    partyLabel = '$typeLabel: $party';
  } else {
    partyLabel = 'salesOrderReservedPartyUnknown'.tr;
  }

  return '  - ${'salesOrderReservedByOrderLine'.trParams({
    'serial': serialLabel,
    'party': partyLabel,
    'qty': '${order.reservedQty}',
  })}';
}
