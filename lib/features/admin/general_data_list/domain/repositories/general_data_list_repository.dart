import 'package:doctorbike/features/admin/general_data_list/data/models/employee_data_model.dart';

abstract class GeneralDataListRepository {
  Future<List<GeneralDataModel>> getGeneralList({bool isSellers = false});
}
