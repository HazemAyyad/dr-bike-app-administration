import 'package:doctorbike/features/admin/sales/data/models/instant_sales_model.dart';

import '../repositories/sales_repositores.dart';

class GetInstantSalesUsecase {
  final SalesRepository salesRepository;

  GetInstantSalesUsecase({required this.salesRepository});

  Future<List<InstantSalesModel>> call() async {
    return await salesRepository.getInstantSales();
  }
}
