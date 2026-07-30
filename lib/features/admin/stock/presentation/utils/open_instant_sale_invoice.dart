import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/app_dependency_registry.dart';
import '../../../sales/data/models/instant_sales_model.dart';
import '../../../sales/presentation/binding/sales_binding.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
import '../../../sales/presentation/widgets/instant_sale_lines_modal.dart';

Future<void> openInstantSaleInvoiceFromStock({
  required BuildContext context,
  required String saleId,
  String? invoiceNumber,
}) async {
  final id = int.tryParse(saleId);
  if (id == null || id <= 0) return;

  AppDependencyRegistry.ensureSales();
  if (!Get.isRegistered<SalesController>() &&
      !Get.isPrepared<SalesController>()) {
    SalesBinding().dependencies();
  }

  final sale = InstantSalesModel(
    id: id,
    invoiceNumberValue: invoiceNumber,
    serialNumber: invoiceNumber,
    product: '',
    cost: '0',
    totalCost: '0',
    quantity: '0',
    date: DateTime.now(),
    notes: '',
  );

  showInstantSaleLinesModal(context, sale);
}
