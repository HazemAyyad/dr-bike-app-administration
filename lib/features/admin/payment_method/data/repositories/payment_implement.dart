import 'package:dartz/dartz.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../presentation/controllers/payment_controller.dart';
import '../datasources/payment_datasource.dart';

class PaymentImplement implements PaymentRepository {
  final NetworkInfo networkInfo;
  final PaymentDatasource paymentDataSource;

  PaymentImplement(
      {required this.networkInfo, required this.paymentDataSource});

  @override
  Future<Either<Failure, String>> addPayment({
    required String type,
    required String customerId,
    required String sellerId,
    required String boxId,
    required String boxValue,
    required List<PaymentModel> checks,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await paymentDataSource.addPayment(
        type: type,
        customerId: customerId,
        sellerId: sellerId,
        boxId: boxId,
        boxValue: boxValue,
        checks: checks,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
