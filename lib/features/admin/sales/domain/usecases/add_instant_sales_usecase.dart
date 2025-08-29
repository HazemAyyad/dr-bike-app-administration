import 'package:doctorbike/core/errors/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import '../repositories/sales_repositores.dart';

class AddInstantSalesUsecase {
  final SalesRepository salesRepository;

  AddInstantSalesUsecase({required this.salesRepository});

  Future<Either<Failure, String>> call({
    required String productId,
    required String quantity,
    required String cost,
    required String discount,
    required String totalCost,
    required String note,
    required String type,
    required String projectId,
    required RxList<ItemModel> otherProducts,
  }) async {
    return await salesRepository.addInstantSales(
      productId: productId,
      quantity: quantity,
      cost: cost,
      discount: discount,
      totalCost: totalCost,
      note: note,
      type: type,
      projectId: projectId,
      otherProducts: otherProducts,
    );
  }
}
