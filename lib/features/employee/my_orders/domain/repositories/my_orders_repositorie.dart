import '../../data/models/my_orders_model_model.dart';

abstract class MyOrdersRepository {
  Future<List<MyOrdersModel>> getMyOrders();
}
