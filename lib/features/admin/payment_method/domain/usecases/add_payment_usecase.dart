import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../presentation/controllers/payment_controller.dart';
import '../repositories/payment_repository.dart';

class AddPaymentUsecase {
  final PaymentRepository paymentRepository;

  AddPaymentUsecase({required this.paymentRepository});

  Future<Either<Failure, String>> call({
    required String type,
    required String customerId,
    required String sellerId,
    required String boxId,
    required String boxValue,
    required List<PaymentModel> checks,
  }) {
    return paymentRepository.addPayment(
      type: type,
      customerId: customerId,
      sellerId: sellerId,
      boxId: boxId,
      boxValue: boxValue,
      checks: checks,
    );
  }
}
