import 'package:dio/dio.dart';
import 'package:doctorbike/features/admin/--/data/datasources/admin_remote_datasource.dart';
import 'package:doctorbike/features/admin/--/data/repositories/admin_implement.dart';
import 'package:get/get.dart';

import '../../features/admin/debts/data/datasources/debet_datasource.dart';
import '../../features/admin/debts/data/repositories/debts_implement.dart';
import '../../features/admin/debts/presentation/controllers/debts_data_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repo_impl.dart';
import '../../features/common_feature/data/datasources/common_datasource.dart';
import '../../features/common_feature/data/repositories/common_repo_impl.dart';
import '../connection/network_info.dart';
import '../databases/api/dio_consumer.dart';

class InitialBindings implements Bindings {
  @override
  void dependencies() async {
    // firebase init

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
  }
}
