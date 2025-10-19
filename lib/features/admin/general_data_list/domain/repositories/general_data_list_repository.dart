import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/general_data_list/data/models/employee_data_model.dart';
import 'package:doctorbike/features/admin/general_data_list/data/models/person_data_model.dart';

import '../../../../../core/errors/failure.dart';
import '../entity/add_person_entity.dart';

abstract class GeneralDataListRepository {
  /// Creates a new general data item
  /// Returns [Either] a [Failure] or the created [GeneralDataEntity]
  Future<Either<Failure, String>> addPerson({
    required AddPersonEntity data,
    required String customerId,
    required String sellerId,
  });
  Future<List<GeneralDataModel>> getGeneralList({required int tab});

  Future<PersonDataModel> getPersonData({
    required String customerId,
    required String sellerId,
  });

  Future<Either<Failure, String>> deletePerson({
    required String customerId,
    required String sellerId,
  });
}
