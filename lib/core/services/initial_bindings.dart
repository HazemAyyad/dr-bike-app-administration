import 'package:dio/dio.dart';
import 'package:doctorbike/features/admin/--/data/datasources/admin_remote_datasource.dart';
import 'package:doctorbike/features/admin/--/data/repositories/admin_implement.dart';
import 'package:doctorbike/features/admin/general_data_list/presentation/controllers/general_data_serves.dart';
import 'package:doctorbike/features/admin/sales/data/datasources/sales_datasources.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../features/admin/boxes/data/datasources/boxes_datasource.dart';
import '../../features/admin/boxes/data/repositories/boxes_implement.dart';
import '../../features/admin/checks/data/datasources/checks_datasource.dart';
import '../../features/admin/checks/data/repositories/checks_implement.dart';
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
import '../../features/admin/general_data_list/data/datasources/general_data_list_datasource.dart';
import '../../features/admin/general_data_list/data/repositories/general_data_list_implement.dart';
import '../../features/admin/sales/data/repositories/sales_implement.dart';
import '../../features/admin/special_tasks/data/datasources/special_tasks_datasource.dart';
import '../../features/admin/special_tasks/data/repositories/special_tasks_implement.dart';
import '../../features/admin/special_tasks/presentation/controllers/special_tasks_service.dart';
import '../../features/admin/stock/data/datasources/stock_datasource.dart';
import '../../features/admin/stock/data/repositories/stock_implement.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repo_impl.dart';
import '../../features/common_feature/data/datasources/common_datasource.dart';
import '../../features/common_feature/data/repositories/common_repo_impl.dart';
import '../../features/employee/employee_dashbord/data/datasources/employee_dashbord_datasource.dart';
import '../../features/employee/employee_dashbord/data/repositories/employee_dashbord_implement.dart';
import '../../features/employee/scan_qrcode/data/datasources/scan_qrcode_datasource.dart';
import '../../features/employee/scan_qrcode/data/repositories/scan_qrcode_implement.dart';
import '../../firebase_options.dart';
import '../connection/network_info.dart';
import '../databases/api/dio_consumer.dart';
import 'notification_firebase_service.dart';
import 'user_data.dart';

String userType = '';

// list of permissions
List<int> employeePermissions = [];
String userName = '';

class InitialBindings implements Bindings {
  @override
  void dependencies() async {
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
    Get.lazyPut<DioConsumer>(() => DioConsumer(dio: Dio()), fenix: true);

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
    Get.lazyPut<EmployeeService>(
      () => EmployeeService(),
      fenix: true,
    );

    // auth feature
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<AuthImplement>(
      () => AuthImplement(
        networkInfo: Get.find<NetworkInfo>(),
        remoteDataSource: Get.find<AuthRemoteDataSource>(),
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
    // admin feature
    Get.lazyPut<AdminRemoteDataSource>(
      () => AdminRemoteDataSource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<AdminImplement>(
      () => AdminImplement(
        networkInfo: Get.find<NetworkInfo>(),
        adminRemoteDataSource: Get.find<AdminRemoteDataSource>(),
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
    Get.lazyPut<CreateEmployeeTasksDataSource>(
      () => CreateEmployeeTasksDataSource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<CreateEmployeeTasksImplement>(
      () => CreateEmployeeTasksImplement(
        networkInfo: Get.find<NetworkInfo>(),
        employeeTasksDataSource: Get.find<CreateEmployeeTasksDataSource>(),
      ),
      fenix: true,
    );

    // مهام الموظفين
    Get.lazyPut<EmployeeTasksDataSource>(
      () => EmployeeTasksDataSource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<EmployeeTasksImplement>(
      () => EmployeeTasksImplement(
        networkInfo: Get.find<NetworkInfo>(),
        employeeTasksDataSource: Get.find<EmployeeTasksDataSource>(),
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
    Get.lazyPut<SpecialTasksService>(
      () => SpecialTasksService(),
      fenix: true,
    );

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
    Get.lazyPut<StockDataSource>(
      () => StockDataSource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<StockImplement>(
      () => StockImplement(
        networkInfo: Get.find<NetworkInfo>(),
        stockDataSource: Get.find<StockDataSource>(),
      ),
      fenix: true,
    );
  }
}
