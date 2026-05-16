import 'package:doctorbike/features/admin/sales/data/models/instant_sales_model.dart';

import '../repositories/sales_repositores.dart';

class GetInstantSalesUsecase {
  final SalesRepository salesRepository;

  GetInstantSalesUsecase({required this.salesRepository});

  Future<List<InstantSalesModel>> call({
    String? search,
    String sortDirection = 'desc',
  }) async {
    return await salesRepository.getInstantSales(
      search: search,
      sortDirection: sortDirection,
    );
  }
}
