import 'package:get/get.dart';

import '../../data/models/my_orders_model_model.dart';

class MyOrdersService {
  final RxList<MyOrdersModel> loansList = <MyOrdersModel>[].obs;
  final RxList<MyOrdersModel> overtimeList = <MyOrdersModel>[].obs;

  // singleton pattern
  static final MyOrdersService _instance = MyOrdersService._internal();
  factory MyOrdersService() => _instance;
  MyOrdersService._internal();
}
