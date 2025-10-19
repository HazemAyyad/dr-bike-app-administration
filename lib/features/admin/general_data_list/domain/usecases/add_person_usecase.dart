import 'package:dartz/dartz.dart';
import 'package:doctorbike/core/errors/failure.dart';

import '../entity/add_person_entity.dart';
import '../repositories/general_data_list_repository.dart';

class AddPersonUseCase {
  final GeneralDataListRepository generalDataListRepository;
  AddPersonUseCase({required this.generalDataListRepository});

  Future<Either<Failure, String>> call({
    required AddPersonEntity data,
    required String customerId,
    required String sellerId,
  }) {
    return generalDataListRepository.addPerson(
      data: data,
      customerId: customerId,
      sellerId: sellerId,
    );
  }
}
