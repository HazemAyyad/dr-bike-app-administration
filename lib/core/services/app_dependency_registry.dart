import 'package:dio/dio.dart';
import 'package:doctorbike/features/admin/general_data_list/presentation/controllers/general_data_serves.dart';
import 'package:doctorbike/features/admin/sales/data/datasources/sales_datasources.dart';
import 'package:get/get.dart';

import '../../features/admin/admin_dashbord/data/datasources/admin_dashboard_datasource.dart';
import '../../features/admin/admin_dashbord/data/repositories/admin_dashboard_implement.dart';
import '../../features/admin/boxes/data/datasources/boxes_datasource.dart';
import '../../features/admin/boxes/data/repositories/boxes_implement.dart';
import '../../features/admin/buying/data/datasources/bills_datasource.dart';
import '../../features/admin/buying/data/repositories/bills_implement.dart';
import '../../features/admin/checks/data/datasources/checks_datasource.dart';
import '../../features/admin/checks/data/repositories/checks_implement.dart';
import '../../features/admin/counters/data/datasources/countrers_datasource.dart';
import '../../features/admin/counters/data/repositories/countrers_implement.dart';
import '../../features/admin/create_tasks/data/datasources/employee_tasks_remote_datasource.dart';
import '../../features/admin/create_tasks/data/repositories/employee_tasks_implement.dart';
import '../../features/admin/debts/data/datasources/debet_datasource.dart';
import '../../features/admin/debts/data/datasources/debt_ledger_datasource.dart';
import '../../features/admin/debts/data/repositories/debt_ledger_implement.dart';
import '../../features/admin/debts/data/repositories/debts_implement.dart';
import '../../features/admin/debts/presentation/controllers/debts_data_service.dart';
import '../../features/admin/employee_section/data/datasources/employee_datasource.dart';
import '../../features/admin/employee_section/data/repositorie_imp/employee_implement.dart';
import '../../features/admin/employee_section/presentation/controllers/employee_service.dart';
import '../../features/admin/employee_tasks/data/datasources/employee_tasks_datasource.dart';
import '../../features/admin/employee_tasks/data/repositories/employee_tasks_implement.dart';
import '../../features/admin/employee_tasks/presentation/controllers/employee_task_service.dart';
import '../../features/admin/financial_affairs/data/datasources/financial_affairs_datasource.dart';
import '../../features/admin/financial_affairs/data/repositories/financial_affairs_implement.dart';
import '../../features/admin/follow_up/data/datasources/followup_datasource.dart';
import '../../features/admin/follow_up/data/repositories/followup_implement.dart';
import '../../features/admin/general_data_list/data/datasources/general_data_list_datasource.dart';
import '../../features/admin/general_data_list/data/repositories/general_data_list_implement.dart';
import '../../features/admin/goals_section/data/datasources/goals_datasource.dart';
import '../../features/admin/goals_section/data/repositories/goals_implement.dart';
import '../../features/admin/maintenance/data/datasources/maintenance_datasource.dart';
import '../../features/admin/maintenance/data/repositories/maintenance_implement.dart';
import '../../features/admin/payment_method/data/datasources/payment_datasource.dart';
import '../../features/admin/payment_method/data/repositories/payment_implement.dart';
import '../../features/admin/product_management/data/datasources/product_management_datasource.dart';
import '../../features/admin/product_management/data/repositories/product_management_implement.dart';
import '../../features/admin/projects/data/datasources/project_datasource.dart';
import '../../features/admin/projects/data/repositories/project_implement.dart';
import '../../features/admin/sales/data/repositories/sales_implement.dart';
import '../../features/admin/special_tasks/data/datasources/special_tasks_datasource.dart';
import '../../features/admin/special_tasks/data/repositories/special_tasks_implement.dart';
import '../../features/admin/special_tasks/presentation/controllers/special_tasks_service.dart';
import '../../features/admin/stock/data/datasources/stock_datasource.dart';
import '../../features/admin/stock/data/repositories/stock_implement.dart';
import '../../features/admin/categories/data/datasources/category_datasource.dart';
import '../../features/admin/categories/data/repositories/category_implement.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repo_impl.dart';
import '../../features/common_feature/data/datasources/common_datasource.dart';
import '../../features/common_feature/data/repositories/common_repo_impl.dart';
import '../../features/employee/employee_dashbord/data/datasources/employee_dashbord_datasource.dart';
import '../../features/employee/employee_dashbord/data/repositories/employee_dashbord_implement.dart';
import '../../features/employee/my_orders/data/datasources/my_orders_datasource.dart';
import '../../features/employee/my_orders/data/repositories/common_repo_impl.dart';
import '../../features/employee/scan_qrcode/data/datasources/scan_qrcode_datasource.dart';
import '../../features/employee/scan_qrcode/data/repositories/scan_qrcode_implement.dart';
import '../connection/network_info.dart';
import '../databases/api/dio_consumer.dart';

/// Registers GetX dependencies synchronously so routes work before async startup finishes.
class AppDependencyRegistry {
  AppDependencyRegistry._();

  static void _lazy<T extends Object>(T Function() builder) {
    if (!Get.isRegistered<T>() && !Get.isPrepared<T>()) {
      Get.lazyPut<T>(builder, fenix: true);
    }
  }

  static void ensureNetworkAndApi() {
    _lazy<NetworkInfo>(() => NetworkInfo());
    _lazy<DioConsumer>(() => DioConsumer(dio: Dio()));
  }

  static void ensureAuth() {
    ensureNetworkAndApi();
    _lazy<AuthRemoteDatasource>(
      () => AuthRemoteDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<AuthImplement>(
      () => AuthImplement(
        networkInfo: Get.find<NetworkInfo>(),
        remoteDataSource: Get.find<AuthRemoteDatasource>(),
      ),
    );
  }

  static void ensureEmployeeDashbord() {
    ensureNetworkAndApi();
    _lazy<EmployeeDashbordDatasource>(
      () => EmployeeDashbordDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<EmployeeDashbordImplement>(
      () => EmployeeDashbordImplement(
        networkInfo: Get.find<NetworkInfo>(),
        employeeDashbordDatasource: Get.find<EmployeeDashbordDatasource>(),
      ),
    );
  }

  static void ensureAdminDashboard() {
    ensureNetworkAndApi();
    _lazy<AdminDashboardDatasource>(
      () => AdminDashboardDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<AdminDashboardImplement>(
      () => AdminDashboardImplement(
        networkInfo: Get.find<NetworkInfo>(),
        adminDashboardDataSource: Get.find<AdminDashboardDatasource>(),
      ),
    );
  }

  static void ensureDebts() {
    ensureNetworkAndApi();
    _lazy<DebetDatasource>(() => DebetDatasource(api: Get.find<DioConsumer>()));
    _lazy<DebtsImplement>(
      () => DebtsImplement(
        networkInfo: Get.find<NetworkInfo>(),
        debetDatasource: Get.find<DebetDatasource>(),
      ),
    );
    _lazy<DebtsDataService>(() => DebtsDataService());
  }

  static void ensureChecks() {
    ensureNetworkAndApi();
    _lazy<ChecksDatasource>(
      () => ChecksDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<ChecksImplement>(
      () => ChecksImplement(
        networkInfo: Get.find<NetworkInfo>(),
        checksDatasource: Get.find<ChecksDatasource>(),
      ),
    );
  }

  static void ensureBoxes() {
    ensureNetworkAndApi();
    _lazy<BoxesDatasource>(() => BoxesDatasource(api: Get.find<DioConsumer>()));
    _lazy<BoxesImplement>(
      () => BoxesImplement(
        networkInfo: Get.find<NetworkInfo>(),
        boxesDatasource: Get.find<BoxesDatasource>(),
      ),
    );
  }

  /// Debts screen needs Checks + Boxes for AllCustomersSellers and payment boxes.
  static void ensureDebtsModule() {
    ensureDebts();
    ensureChecks();
    ensureBoxes();
  }

  static void ensureDebtsLedger() {
    ensureNetworkAndApi();
    _lazy<DebtLedgerDatasource>(
      () => DebtLedgerDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<DebtLedgerImplement>(
      () => DebtLedgerImplement(
        networkInfo: Get.find<NetworkInfo>(),
        datasource: Get.find<DebtLedgerDatasource>(),
      ),
    );
  }

  static void ensureDebtsLedgerModule() {
    ensureDebtsLedger();
  }

  static void ensureEmployeeSection() {
    ensureNetworkAndApi();
    _lazy<EmployeeDatasource>(
      () => EmployeeDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<EmployeeImplement>(
      () => EmployeeImplement(
        networkInfo: Get.find<NetworkInfo>(),
        employeeDatasource: Get.find<EmployeeDatasource>(),
      ),
    );
    _lazy<EmployeeService>(() => EmployeeService());
  }

  static void ensureCounters() {
    ensureNetworkAndApi();
    _lazy<CountrersDatasource>(
      () => CountrersDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<CountrersImplement>(
      () => CountrersImplement(
        networkInfo: Get.find<NetworkInfo>(),
        countrersDataSource: Get.find<CountrersDatasource>(),
      ),
    );
  }

  static void ensureEmployeeTasks() {
    ensureNetworkAndApi();
    _lazy<CreateEmployeeTasksDatasource>(
      () => CreateEmployeeTasksDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<CreateEmployeeTasksImplement>(
      () => CreateEmployeeTasksImplement(
        networkInfo: Get.find<NetworkInfo>(),
        employeeTasksDataSource: Get.find<CreateEmployeeTasksDatasource>(),
      ),
    );
    _lazy<EmployeeTasksDatasource>(
      () => EmployeeTasksDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<EmployeeTasksImplement>(
      () => EmployeeTasksImplement(
        networkInfo: Get.find<NetworkInfo>(),
        employeeTasksDataSource: Get.find<EmployeeTasksDatasource>(),
      ),
    );
    _lazy<EmployeeTaskService>(() => EmployeeTaskService());
  }

  static void ensureSpecialTasks() {
    ensureNetworkAndApi();
    _lazy<SpecialTasksDatasource>(
      () => SpecialTasksDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<SpecialTasksImplement>(
      () => SpecialTasksImplement(
        networkInfo: Get.find<NetworkInfo>(),
        specialTasksDatasource: Get.find<SpecialTasksDatasource>(),
      ),
    );
    _lazy<SpecialTasksService>(() => SpecialTasksService());
  }

  static void ensureSales() {
    ensureNetworkAndApi();
    _lazy<SalesDatasource>(() => SalesDatasource(api: Get.find<DioConsumer>()));
    _lazy<SalesImplement>(
      () => SalesImplement(
        networkInfo: Get.find<NetworkInfo>(),
        salesDatasource: Get.find<SalesDatasource>(),
      ),
    );
  }

  static void ensureGeneralDataList() {
    ensureNetworkAndApi();
    ensureDebtsLedger();
    _lazy<GeneralDataListDatasource>(
      () => GeneralDataListDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<GeneralDataListImplement>(
      () => GeneralDataListImplement(
        networkInfo: Get.find<NetworkInfo>(),
        generalDataListDatasource: Get.find<GeneralDataListDatasource>(),
      ),
    );
    _lazy<GeneralDataServes>(() => GeneralDataServes());
  }

  static void ensureProjects() {
    ensureNetworkAndApi();
    ensureSales();
    ensureChecks();
    _lazy<ProjectDatasource>(
      () => ProjectDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<ProjectImplement>(
      () => ProjectImplement(
        networkInfo: Get.find<NetworkInfo>(),
        projectDataSource: Get.find<ProjectDatasource>(),
      ),
    );
  }

  static void ensureGoals() {
    ensureNetworkAndApi();
    _lazy<GoalsDatasource>(() => GoalsDatasource(api: Get.find<DioConsumer>()));
    _lazy<GoalsImplement>(
      () => GoalsImplement(
        networkInfo: Get.find<NetworkInfo>(),
        goalsDatasource: Get.find<GoalsDatasource>(),
      ),
    );
  }

  static void ensureFollowUp() {
    ensureNetworkAndApi();
    _lazy<FollowupDatasource>(
      () => FollowupDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<FollowupImplement>(
      () => FollowupImplement(
        networkInfo: Get.find<NetworkInfo>(),
        followupDataSource: Get.find<FollowupDatasource>(),
      ),
    );
  }

  static void ensureCommon() {
    ensureNetworkAndApi();
    _lazy<CommonDatasource>(
      () => CommonDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<CommonImplement>(
      () => CommonImplement(
        networkInfo: Get.find<NetworkInfo>(),
        commonDatasource: Get.find<CommonDatasource>(),
      ),
    );
  }

  static void ensureScanQr() {
    ensureNetworkAndApi();
    _lazy<ScanQrCodeDatasource>(
      () => ScanQrCodeDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<ScanQrCodeImplement>(
      () => ScanQrCodeImplement(
        networkInfo: Get.find<NetworkInfo>(),
        scanQrcodeDatasource: Get.find<ScanQrCodeDatasource>(),
      ),
    );
  }

  static void ensureStock() {
    ensureNetworkAndApi();
    _lazy<StockDatasource>(() => StockDatasource(api: Get.find<DioConsumer>()));
    _lazy<StockImplement>(
      () => StockImplement(
        networkInfo: Get.find<NetworkInfo>(),
        stockDataSource: Get.find<StockDatasource>(),
      ),
    );
  }

  static void ensureFinancialAffairs() {
    ensureNetworkAndApi();
    _lazy<FinancialAffairsDatasource>(
      () => FinancialAffairsDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<FinancialAffairsImplement>(
      () => FinancialAffairsImplement(
        networkInfo: Get.find<NetworkInfo>(),
        financialAffairsDatasource: Get.find<FinancialAffairsDatasource>(),
      ),
    );
  }

  static void ensurePayment() {
    ensureNetworkAndApi();
    _lazy<PaymentDatasource>(
      () => PaymentDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<PaymentImplement>(
      () => PaymentImplement(
        networkInfo: Get.find<NetworkInfo>(),
        paymentDataSource: Get.find<PaymentDatasource>(),
      ),
    );
  }

  static void ensureMaintenance() {
    ensureNetworkAndApi();
    _lazy<MaintenanceDatasource>(
      () => MaintenanceDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<MaintenanceImplement>(
      () => MaintenanceImplement(
        networkInfo: Get.find<NetworkInfo>(),
        maintenanceDatasource: Get.find<MaintenanceDatasource>(),
      ),
    );
  }

  static void ensureMyOrders() {
    ensureNetworkAndApi();
    _lazy<MyOrdersDatasource>(
      () => MyOrdersDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<MyOrdersImplement>(
      () => MyOrdersImplement(
        networkInfo: Get.find<NetworkInfo>(),
        myOrdersDatasource: Get.find<MyOrdersDatasource>(),
      ),
    );
  }

  static void ensureBills() {
    ensureNetworkAndApi();
    _lazy<BillsDatasource>(() => BillsDatasource(api: Get.find<DioConsumer>()));
    _lazy<BillsImplement>(
      () => BillsImplement(
        networkInfo: Get.find<NetworkInfo>(),
        billsDataSource: Get.find<BillsDatasource>(),
      ),
    );
  }

  static void ensureCategories() {
    ensureNetworkAndApi();
    _lazy<CategoryDatasource>(
      () => CategoryDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<CategoryImplement>(
      () => CategoryImplement(
        networkInfo: Get.find<NetworkInfo>(),
        categoryDatasource: Get.find<CategoryDatasource>(),
      ),
    );
  }

  static void ensureProductManagement() {
    ensureNetworkAndApi();
    _lazy<ProductManagementDatasource>(
      () => ProductManagementDatasource(api: Get.find<DioConsumer>()),
    );
    _lazy<ProductManagementImplement>(
      () => ProductManagementImplement(
        networkInfo: Get.find<NetworkInfo>(),
        productManagementDatasource: Get.find<ProductManagementDatasource>(),
      ),
    );
  }

  /// Call once at app start before any async work (GetX does not await Bindings).
  static void registerAll() {
    ensureNetworkAndApi();
    ensureAuth();
    ensureEmployeeDashbord();
    ensureAdminDashboard();
    ensureDebtsModule();
    ensureEmployeeSection();
    ensureCounters();
    ensureCommon();
    ensureEmployeeTasks();
    ensureSpecialTasks();
    ensureScanQr();
    ensureSales();
    ensureGeneralDataList();
    ensureStock();
    ensureFinancialAffairs();
    ensureProjects();
    ensurePayment();
    ensureMaintenance();
    ensureGoals();
    ensureFollowUp();
    ensureMyOrders();
    ensureBills();
    ensureCategories();
    ensureProductManagement();
  }
}
