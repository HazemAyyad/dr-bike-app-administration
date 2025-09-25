import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:doctorbike/features/admin/general_data_list/presentation/controllers/general_data_serves.dart';
import 'package:doctorbike/features/admin/sales/data/datasources/sales_datasources.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

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
import '../../features/admin/goals_section/data/datasources/goals_datasource.dart';
import '../../features/admin/goals_section/data/repositories/goals_implement.dart';
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
import '../../firebase_options.dart';
import '../connection/network_info.dart';
import '../databases/api/dio_consumer.dart';
import 'notification_firebase_service.dart';
import 'user_data.dart';

String userType = '';
RxBool startApp = true.obs;
// list of permissions
List<int> employeePermissions = [];
String userName = '';

class InitialBindings implements Bindings {
  @override
  void dependencies() async {
    Firebase.initializeApp();
    NetworkInfo networkInfo = NetworkInfo();
    final connected = await networkInfo.isConnected;

    // firebase init
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    connected
        ? await NotificationFirebaseService.instance.intNotification()
        : null;
    await initializeDateFormatting();
    Stream<bool?> startAppStream() {
      return FirebaseFirestore.instance
          .collection('Test')
          .doc('Test')
          .snapshots()
          .map((doc) => doc.data()?['Test'] as bool?);
    }

    startAppStream().listen((value) {
      startApp.value = value!;
    });

    print('FCM Token: ${NotificationFirebaseService.instance.finalToken}');
    final userToken = await UserData.getUserToken();
    final userdata = await UserData.getSavedUser();
    if (userdata != null) {
      final permissionIds =
          userdata.employeePermissions.map((p) => p.permissionId).toList();
      employeePermissions.addAll(permissionIds);
      userType = userdata.user.type;
      userName = userdata.user.name;
      print('User Type: $userType');
      print('User Type: $employeePermissions');
    }
    print('User Token: $userToken');
    Get.lazyPut<NetworkInfo>(() => NetworkInfo(), fenix: true);
    startApp.value
        ? Get.lazyPut<DioConsumer>(() => DioConsumer(dio: Dio()), fenix: true)
        : null;

    // employee dashbord
    Get.lazyPut<EmployeeDashbordDatasource>(
      () => EmployeeDashbordDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<EmployeeDashbordImplement>(
      () => EmployeeDashbordImplement(
        networkInfo: Get.find<NetworkInfo>(),
        employeeDashbordDatasource: Get.find<EmployeeDashbordDatasource>(),
      ),
      fenix: true,
    );

    // admin dashbord
    Get.lazyPut<AdminDashboardDatasource>(
      () => AdminDashboardDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<AdminDashboardImplement>(
      () => AdminDashboardImplement(
        networkInfo: Get.find<NetworkInfo>(),
        adminDashboardDataSource: Get.find<AdminDashboardDatasource>(),
      ),
      fenix: true,
    );

    // قسم الموظين
    Get.lazyPut<EmployeeDatasource>(
      () => EmployeeDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<EmployeeImplement>(
      () => EmployeeImplement(
        networkInfo: Get.find<NetworkInfo>(),
        employeeDatasource: Get.find<EmployeeDatasource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<EmployeeService>(() => EmployeeService(), fenix: true);

    // auth feature
    Get.lazyPut<AuthRemoteDatasource>(
      () => AuthRemoteDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<AuthImplement>(
      () => AuthImplement(
        networkInfo: Get.find<NetworkInfo>(),
        remoteDataSource: Get.find<AuthRemoteDatasource>(),
      ),
      fenix: true,
    );
    // common feature
    Get.lazyPut<CommonDatasource>(
      () => CommonDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<CommonImplement>(
      () => CommonImplement(
        networkInfo: Get.find<NetworkInfo>(),
        commonDatasource: Get.find<CommonDatasource>(),
      ),
      fenix: true,
    );

    // debts feature
    Get.lazyPut<DebetDatasource>(
      () => DebetDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<DebtsImplement>(
      () => DebtsImplement(
        networkInfo: Get.find<NetworkInfo>(),
        debetDatasource: Get.find<DebetDatasource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<DebtsDataService>(() => DebtsDataService(), fenix: true);

    // انشاء مهام الموظفين
    Get.lazyPut<CreateEmployeeTasksDatasource>(
      () => CreateEmployeeTasksDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<CreateEmployeeTasksImplement>(
      () => CreateEmployeeTasksImplement(
        networkInfo: Get.find<NetworkInfo>(),
        employeeTasksDataSource: Get.find<CreateEmployeeTasksDatasource>(),
      ),
      fenix: true,
    );

    // مهام الموظفين
    Get.lazyPut<EmployeeTasksDatasource>(
      () => EmployeeTasksDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<EmployeeTasksImplement>(
      () => EmployeeTasksImplement(
        networkInfo: Get.find<NetworkInfo>(),
        employeeTasksDataSource: Get.find<EmployeeTasksDatasource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<EmployeeTaskService>(() => EmployeeTaskService(), fenix: true);

    // المهام الخاصة
    Get.lazyPut<SpecialTasksDatasource>(
      () => SpecialTasksDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<SpecialTasksImplement>(
      () => SpecialTasksImplement(
        networkInfo: Get.find<NetworkInfo>(),
        specialTasksDatasource: Get.find<SpecialTasksDatasource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<SpecialTasksService>(() => SpecialTasksService(), fenix: true);

    // scan qrcode
    Get.lazyPut<ScanQrCodeDatasource>(
      () => ScanQrCodeDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<ScanQrCodeImplement>(
      () => ScanQrCodeImplement(
        networkInfo: Get.find<NetworkInfo>(),
        scanQrcodeDatasource: Get.find<ScanQrCodeDatasource>(),
      ),
      fenix: true,
    );

    // boxes
    Get.lazyPut<BoxesDatasource>(
      () => BoxesDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<BoxesImplement>(
      () => BoxesImplement(
        networkInfo: Get.find<NetworkInfo>(),
        boxesDatasource: Get.find<BoxesDatasource>(),
      ),
      fenix: true,
    );

    // Checks
    Get.lazyPut<ChecksDatasource>(
      () => ChecksDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<ChecksImplement>(
      () => ChecksImplement(
        networkInfo: Get.find<NetworkInfo>(),
        checksDatasource: Get.find<ChecksDatasource>(),
      ),
      fenix: true,
    );

    // sales
    Get.lazyPut<SalesDatasource>(
      () => SalesDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<SalesImplement>(
      () => SalesImplement(
        networkInfo: Get.find<NetworkInfo>(),
        salesDatasource: Get.find<SalesDatasource>(),
      ),
      fenix: true,
    );

    // general data list
    Get.lazyPut<GeneralDataListDatasource>(
      () => GeneralDataListDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<GeneralDataListImplement>(
      () => GeneralDataListImplement(
        networkInfo: Get.find<NetworkInfo>(),
        generalDataListDatasource: Get.find<GeneralDataListDatasource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<GeneralDataServes>(() => GeneralDataServes(), fenix: true);

    // stock
    Get.lazyPut<StockDatasource>(
      () => StockDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<StockImplement>(
      () => StockImplement(
        networkInfo: Get.find<NetworkInfo>(),
        stockDataSource: Get.find<StockDatasource>(),
      ),
      fenix: true,
    );

    // financial affairs
    Get.lazyPut<FinancialAffairsDatasource>(
      () => FinancialAffairsDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<FinancialAffairsImplement>(
      () => FinancialAffairsImplement(
        networkInfo: Get.find<NetworkInfo>(),
        financialAffairsDatasource: Get.find<FinancialAffairsDatasource>(),
      ),
      fenix: true,
    );

    // projects
    Get.lazyPut<ProjectDatasource>(
      () => ProjectDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<ProjectImplement>(
      () => ProjectImplement(
        networkInfo: Get.find<NetworkInfo>(),
        projectDataSource: Get.find<ProjectDatasource>(),
      ),
      fenix: true,
    );

    // counters
    Get.lazyPut<CountrersDatasource>(
      () => CountrersDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<CountrersImplement>(
      () => CountrersImplement(
        networkInfo: Get.find<NetworkInfo>(),
        countrersDataSource: Get.find<CountrersDatasource>(),
      ),
      fenix: true,
    );

    // payment
    Get.lazyPut<PaymentDatasource>(
      () => PaymentDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<PaymentImplement>(
      () => PaymentImplement(
        networkInfo: Get.find<NetworkInfo>(),
        paymentDataSource: Get.find<PaymentDatasource>(),
      ),
      fenix: true,
    );

    // Maintenance
    Get.lazyPut<MaintenanceDatasource>(
      () => MaintenanceDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<MaintenanceImplement>(
      () => MaintenanceImplement(
        networkInfo: Get.find<NetworkInfo>(),
        maintenanceDatasource: Get.find<MaintenanceDatasource>(),
      ),
      fenix: true,
    );

    // goals
    Get.lazyPut<GoalsDatasource>(
      () => GoalsDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<GoalsImplement>(
      () => GoalsImplement(
        networkInfo: Get.find<NetworkInfo>(),
        goalsDatasource: Get.find<GoalsDatasource>(),
      ),
      fenix: true,
    );

    // FollowUp
    Get.lazyPut<FollowupDatasource>(
      () => FollowupDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<FollowupImplement>(
      () => FollowupImplement(
        networkInfo: Get.find<NetworkInfo>(),
        followupDataSource: Get.find<FollowupDatasource>(),
      ),
      fenix: true,
    );

    // my Orders
    Get.lazyPut<MyOrdersDatasource>(
      () => MyOrdersDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<MyOrdersImplement>(
      () => MyOrdersImplement(
        networkInfo: Get.find<NetworkInfo>(),
        myOrdersDatasource: Get.find<MyOrdersDatasource>(),
      ),
      fenix: true,
    );

    // bill
    Get.lazyPut<BillsDatasource>(
      () => BillsDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<BillsImplement>(
      () => BillsImplement(
        networkInfo: Get.find<NetworkInfo>(),
        billsDataSource: Get.find<BillsDatasource>(),
      ),
      fenix: true,
    );

    // Product Management
    Get.lazyPut<ProductManagementDatasource>(
      () => ProductManagementDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<ProductManagementImplement>(
      () => ProductManagementImplement(
        networkInfo: Get.find<NetworkInfo>(),
        productManagementDatasource: Get.find<ProductManagementDatasource>(),
      ),
      fenix: true,
    );
  }
}
