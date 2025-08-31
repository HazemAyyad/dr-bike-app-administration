import 'package:doctorbike/features/admin/general_data_list/data/models/person_data_model.dart';

import '../repositories/general_data_list_repository.dart';

class GetPersonDataUseCase {
  final GeneralDataListRepository generalDataListRepository;
  GetPersonDataUseCase({required this.generalDataListRepository});

  Future<PersonDataModel> call(
      {required String customerId, required String sellerId}) {
    return generalDataListRepository.getPersonData(
      customerId: customerId,
      sellerId: sellerId,
    );
  }
}
