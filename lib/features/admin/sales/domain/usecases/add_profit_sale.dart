import 'package:dartz/dartz.dart';
import 'package:doctorbike/core/errors/failure.dart';
import 'package:image_picker/image_picker.dart';

import '../repositories/sales_repositores.dart';

class AddProfitSaleUsecase {
  final SalesRepository salesRepository;

  AddProfitSaleUsecase({required this.salesRepository});

  Future<Either<Failure, String>> call(
      {required String notes,
      required String totalCost,
      String? buyerType,
      String? buyerId,
      String? sellerId,
      String? buyerName,
      String? paymentBoxId,
      String? paymentBoxName,
      String? paymentBoxValue,
      XFile? image,
      XFile? video}) async {
    return await salesRepository.addProfitSales(
      notes: notes,
      totalCost: totalCost,
      buyerType: buyerType,
      buyerId: buyerId,
      sellerId: sellerId,
      buyerName: buyerName,
      paymentBoxId: paymentBoxId,
      paymentBoxName: paymentBoxName,
      paymentBoxValue: paymentBoxValue,
      image: image,
      video: video,
    );
  }
}
