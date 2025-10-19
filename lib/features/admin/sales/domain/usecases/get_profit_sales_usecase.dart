import 'package:doctorbike/features/admin/sales/data/models/profit_sale_model.dart';

import '../repositories/sales_repositores.dart';

class GetProfitSalesUsecase {
  final SalesRepository salesRepository;

  GetProfitSalesUsecase({required this.salesRepository});

  Future<List<ProfitSale>> call() async {
    return await salesRepository.getProfitSales();
  }
}
