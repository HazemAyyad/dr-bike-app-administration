import 'package:dio/dio.dart';
import 'package:doctorbike/features/admin/--/data/datasources/admin_remote_datasource.dart';
import 'package:doctorbike/features/admin/--/data/repositories/admin_implement.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../features/admin/debts/data/datasources/debet_datasource.dart';
import '../../features/admin/debts/data/repositories/debts_implement.dart';
import '../../features/admin/debts/presentation/controllers/debts_data_service.dart';
import '../../features/admin/employee_section/data/datasources/employee_section_remote_datasource.dart';
import '../../features/admin/employee_section/data/repositorie_imp/employee_section_implement.dart';
import '../../features/admin/employee_section/presentation/controllers/employee_service.dart';
import '../../features/admin/employee_tasks/data/datasources/employee_tasks_remote_datasource.dart';
import '../../features/admin/employee_tasks/data/repositories/employee_tasks_implement.dart';
import '../../features/admin/employee_tasks/presentation/controllers/employee_task_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repo_impl.dart';
import '../../features/common_feature/data/datasources/common_datasource.dart';
import '../../features/common_feature/data/repositories/common_repo_impl.dart';
import '../../firebase_options.dart';
import '../connection/network_info.dart';
import '../databases/api/dio_consumer.dart';
import 'notification_firebase_service.dart';
import 'user_data.dart';

String test = '';
List<int> employeePermissions = [];

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
      test = userdata.user.type;
      print('User Type: $test');
      print('User Type: $employeePermissions');
    }
    print('User Token: $userToken');
    Get.lazyPut<NetworkInfo>(() => NetworkInfo(), fenix: true);
    Get.lazyPut<DioConsumer>(() => DioConsumer(dio: Dio()), fenix: true);

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
    Get.lazyPut<DebtsDataService>(
      () => DebtsDataService(),
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
    Get.lazyPut<EmployeeTaskService>(
      () => EmployeeTaskService(),
      fenix: true,
    );
  }
}
