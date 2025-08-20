

class SpecialTasksService {

  // final RxList<SpecialTaskModel> specialTaskList = <SpecialTaskModel>[].obs;

  // final RxList<FinancialDuesModel> financialDuesList =
  //     <FinancialDuesModel>[].obs;

  // Rxn<QrGenerationModel> qrGeneration = Rxn<QrGenerationModel>();

  // Rxn<EmployeeDetailsModel> employeeDetails = Rxn<EmployeeDetailsModel>();

  // singleton pattern
  static final SpecialTasksService _instance = SpecialTasksService._internal();
  factory SpecialTasksService() => _instance;
  SpecialTasksService._internal();
}
