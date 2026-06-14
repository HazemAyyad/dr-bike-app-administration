import 'package:flutter/material.dart';

import '../../../../../core/services/app_dependency_registry.dart';
import '../../../sales/data/models/instant_sales_model.dart';
import '../../../sales/presentation/widgets/instant_sale_lines_modal.dart';

Future<void> openInstantSaleInvoiceFromStock({
  required BuildContext context,
  required String saleId,
}) async {
  final id = int.tryParse(saleId);
  if (id == null || id <= 0) return;

  AppDependencyRegistry.ensureSales();

  final sale = InstantSalesModel(
    id: id,
    product: '',
    cost: '0',
    totalCost: '0',
    quantity: '0',
    date: DateTime.now(),
    notes: '',
  );

  showInstantSaleLinesModal(context, sale);
}
