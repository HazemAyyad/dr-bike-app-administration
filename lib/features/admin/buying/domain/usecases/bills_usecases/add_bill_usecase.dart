import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../../presentation/controllers/bills_controller.dart';
import '../../repositories/bills_repository.dart';

class AddBillUsecase {
  final BillsRepository billsRepository;

  AddBillUsecase({required this.billsRepository});

  Future<Either<Failure, String>> call({
    required String sellerId,
    required List<BillModel> products,
    required String total,
    required String page,
  }) {
    return billsRepository.addBill(
      page: page,
      sellerId: sellerId,
      products: products,
      total: total,
    );
  }
}
