import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/my_orders_repositorie.dart';
import '../datasources/my_orders_datasource.dart';
import '../models/my_orders_model_model.dart';

class MyOrdersImplement implements MyOrdersRepository {
  final NetworkInfo networkInfo;
  final MyOrdersDatasource myOrdersDatasource;

  MyOrdersImplement({
    required this.networkInfo,
    required this.myOrdersDatasource,
  });

  @override
  Future<List<MyOrdersModel>> getMyOrders() async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await myOrdersDatasource.getMyOrders();

      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }
}
