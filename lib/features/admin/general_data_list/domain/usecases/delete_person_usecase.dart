import 'package:dartz/dartz.dart';
import 'package:doctorbike/core/errors/failure.dart';

import '../repositories/general_data_list_repository.dart';

class DeletePersonUsecase {
  final GeneralDataListRepository generalDataListRepository;
  DeletePersonUsecase({required this.generalDataListRepository});

  Future<Either<Failure, String>> call({
    required String customerId,
    required String sellerId,
  }) {
    return generalDataListRepository.deletePerson(
      customerId: customerId,
      sellerId: sellerId,
    );
  }
}
