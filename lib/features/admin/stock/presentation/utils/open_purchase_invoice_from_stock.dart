import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../routes/app_routes.dart';
import '../../../buying/presentation/binding/buying_binding.dart';
import '../../../buying/presentation/controllers/bills_controller.dart';

Future<void> openPurchaseInvoiceFromStock({
  required BuildContext context,
  required String billId,
}) async {
  if (!Get.isRegistered<BillsController>()) {
    BuyingBinding().dependencies();
  }
  final controller = Get.find<BillsController>();
  await controller.getBillDetails(context: context, billId: billId);
  if (!context.mounted) return;
  await Get.toNamed(AppRoutes.BILLDETAILSSCREEN, arguments: '1');
}
