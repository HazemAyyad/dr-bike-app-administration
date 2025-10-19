import '../../data/models/my_orders_model_model.dart';
import '../repositories/my_orders_repositorie.dart';

class GetMyOrdersUsecase {
  final MyOrdersRepository myOrdersRepository;
  GetMyOrdersUsecase({required this.myOrdersRepository});

  Future<List<MyOrdersModel>> call() {
    return myOrdersRepository.getMyOrders();
  }
}
