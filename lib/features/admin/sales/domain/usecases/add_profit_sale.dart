import 'package:dartz/dartz.dart';
import 'package:doctorbike/core/errors/failure.dart';

import '../repositories/sales_repositores.dart';

class AddProfitSaleUsecase {
  final SalesRepository salesRepository;

  AddProfitSaleUsecase({required this.salesRepository});

  Future<Either<Failure, String>> call(
      {required String notes, required String totalCost}) async {
    return await salesRepository.addProfitSales(
      notes: notes,
      totalCost: totalCost,
    );
  }
}
