import '../../data/models/employee_data_model.dart';

class GeneralDataServes {
  final List<GeneralDataModel> employeeDataList = [];
  final List<GeneralDataModel> sellersDataList = [];
  final List<GeneralDataModel> inCompleteDataList = [];

  // singleton pattern
  static final GeneralDataServes _instance = GeneralDataServes._internal();
  factory GeneralDataServes() => _instance;
  GeneralDataServes._internal();
}
