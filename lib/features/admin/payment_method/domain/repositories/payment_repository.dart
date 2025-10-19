import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../presentation/controllers/payment_controller.dart';

abstract class PaymentRepository {
  Future<Either<Failure, String>> addPayment({
    required String type,
    required String customerId,
    required String sellerId,
    required String boxId,
    required String boxValue,
    required List<PaymentModel> checks,
  });
}
