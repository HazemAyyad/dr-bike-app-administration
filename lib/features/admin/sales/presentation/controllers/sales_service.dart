import 'package:doctorbike/features/admin/sales/data/models/instant_sales_model.dart';

class SalesService {
  // final Rxn<SpotsaleModel> spotsaleModel = Rxn<SpotsaleModel>();
  final List<InstantSalesModel> instantSalesTasks = [];

  // singleton pattern
  static final SalesService _instance = SalesService._internal();
  factory SalesService() => _instance;
  SalesService._internal();
}
