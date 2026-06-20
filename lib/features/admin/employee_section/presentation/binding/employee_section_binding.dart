import 'package:doctorbike/core/services/app_dependency_registry.dart';
import 'package:doctorbike/features/admin/counters/data/repositories/countrers_implement.dart';
import 'package:doctorbike/features/admin/employee_section/domain/usecases/add_employee_usecase.dart';
import 'package:doctorbike/features/admin/employee_section/domain/usecases/get_all_employee.dart';
import 'package:get/get.dart';

import '../../../counters/domain/usecases/get_report_by_type_usecase.dart';
import '../../data/repositorie_imp/employee_implement.dart';
import '../../domain/usecases/add_points_usecase.dart';
import '../../domain/usecases/approve_employee_order_usecase.dart';
import '../../domain/usecases/cancel_log_usecase.dart';
import '../../domain/usecases/delete_employee_usecase.dart';
import '../../domain/usecases/employee_details_usecase.dart';
import '../../domain/usecases/employee_advances_usecase.dart';
import '../../domain/usecases/financial_details_usecase.dart';
import '../../domain/usecases/financial_dues.usecase.dart';
import '../../domain/usecases/get_logs_usecase.dart';
import '../../domain/usecases/overtime_and_loan_usecase.dart';
import '../../domain/usecases/pay_salary_to_employee_usecase.dart';
import '../../domain/usecases/qr_generation_usecase.dart';
import '../../domain/usecases/qr_history_usecase.dart';
import '../../domain/usecases/reject_order_usecase.dart';
import '../../domain/usecases/employee_points_usecases.dart';
import '../../domain/usecases/working_times_usecase.dart';
import '../../domain/usecases/admin_users_usecase.dart';
import '../controllers/add_employee_controller.dart';
import '../controllers/add_admin_controller.dart';
import '../controllers/employee_point_categories_controller.dart';
import '../controllers/employee_points_controller.dart';
import '../controllers/employee_points_report_controller.dart';
import '../controllers/employee_reward_rules_controller.dart';
import '../controllers/employee_section_controller.dart';
import '../controllers/employee_service.dart';
import '../controllers/global_employee_points_controller.dart';

class EmployeeSectionBinding extends Bindings {
  @override
  void dependencies() {
    AppDependencyRegistry.ensureEmployeeSection();
    AppDependencyRegistry.ensureCounters();

    Get.lazyPut(
      () => EmployeeSectionController(
        paySalaryEmployee: PaySalaryToEmployeeUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        getAllEmployeeUsecase: GetAllEmployeeUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        employeeService: Get.find<EmployeeService>(),
        workingTimesUsecase: WorkingTimesUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        financialDuesUsecase: FinancialDuesUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        financialDetailsUsecase: FinancialDetailsUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        employeeAdvancesUsecase: EmployeeAdvancesUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        employeeDetailsUsecase: EmployeeDetailsUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        qrGenerationUsecase: QrGenerationUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        qrHistoryUsecase: QrHistoryUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        overtimeAndLoanUsecase: OvertimeAndLoanUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        rejectOrderUsecase: RejectOrderUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        approveEmployeeOrderUsecase: ApproveEmployeeOrderUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        getLogsUsecase: GetLogsUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        cancelLogUsecase: CancelLogUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        deleteEmployeeUsecase: DeleteEmployeeUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        getAdminUsersUsecase: GetAdminUsersUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        manageAdminUserUsecase: ManageAdminUserUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        getReportByType: GetReportByTypeUsecase(
          countersRepository: Get.find<CountrersImplement>(),
        ),
      ),
    );
    Get.lazyPut(
      () => AddAdminController(
        manageAdminUserUsecase: ManageAdminUserUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        sectionController: Get.find<EmployeeSectionController>(),
      ),
    );
    Get.lazyPut(
      () => AddEmployeeController(
        employeeUsecase: AddEmployeeUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        addPointsUsecase: AddPointsUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        employeeService: Get.find<EmployeeService>(),
      ),
    );

    Get.lazyPut<EmployeePointsController>(
      () => EmployeePointsController(
        mutateUsecase: MutateEmployeePointsUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        logsUsecase: GetEmployeePointsLogsUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        summaryUsecase: GetEmployeePointsMonthlySummaryUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        categoriesUsecase: GetEmployeePointsCategoriesUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
      ),
      fenix: true,
    );

    Get.lazyPut<EmployeeRewardRulesController>(
      () => EmployeeRewardRulesController(
        fetchRulesUsecase: GetEmployeeRewardRulesUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        createRuleUsecase: CreateEmployeeRewardRuleUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        updateRuleUsecase: UpdateEmployeeRewardRuleUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        deleteRuleUsecase: DeleteEmployeeRewardRuleUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
      ),
      fenix: true,
    );

    Get.lazyPut<EmployeePointCategoriesController>(
      () => EmployeePointCategoriesController(
        fetchUsecase: GetEmployeePointCategoriesUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        createUsecase: CreateEmployeePointCategoryUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        updateUsecase: UpdateEmployeePointCategoryUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        deleteUsecase: DeleteEmployeePointCategoryUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
      ),
      fenix: true,
    );

    Get.lazyPut<GlobalEmployeePointsController>(
      () => GlobalEmployeePointsController(
        fetchGlobalUsecase: GetGlobalEmployeesPointsUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        fetchCategoriesUsecase: GetEmployeePointCategoriesUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        mutateUsecase: MutateEmployeePointsUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        summaryUsecase: GetEmployeePointsMonthlySummaryUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
      ),
      fenix: true,
    );

    Get.lazyPut<EmployeePointsReportController>(
      () => EmployeePointsReportController(
        fetchReportUsecase: GetGlobalPointsReportUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        fetchCategoriesUsecase: GetEmployeePointCategoriesUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
      ),
      fenix: true,
    );
  }
}
