import 'package:doctorbike/features/admin/general_data_list/data/models/employee_data_model.dart';

import '../repositories/general_data_list_repository.dart';

class GetCustomersUseCase {
  final GeneralDataListRepository generalDataListRepository;
  GetCustomersUseCase({required this.generalDataListRepository});

  Future<List<GeneralDataModel>> call({required int tab}) {
    return generalDataListRepository.getGeneralList(tab: tab);
  }
}
