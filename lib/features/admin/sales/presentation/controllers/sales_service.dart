import 'package:doctorbike/features/admin/sales/data/models/instant_sales_model.dart';

import '../../data/models/profit_sale_model.dart';

class SalesService {
  // get profit sales
  final Map<String, List<ProfitSale>> profitSalesTasks = {};

  final Map<String, List<ProfitSale>> filterProfitSalesTasks = {};

  // get instant sales
  final Map<String, List<InstantSalesModel>> instantSalesTasks = {};

  final Map<String, List<InstantSalesModel>> filterInstantSalesTasks = {};

  // singleton pattern
  static final SalesService _instance = SalesService._internal();
  factory SalesService() => _instance;
  SalesService._internal();
}
