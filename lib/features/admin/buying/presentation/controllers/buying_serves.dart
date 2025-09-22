import 'package:get/get.dart';

import '../../data/models/bills_models/bills_model.dart';
import '../../data/models/return_purchases_models/return_products_model.dart';

class BuyingServes {
  // final List<BillDataModel> allBills = <BillDataModel>[].obs;
  // final List<BillDataModel> allBillsArchive = <BillDataModel>[].obs;

  final allBillsTasks = <String, List<BillDataModel>>{}.obs;
  final allBillsArchiveTasks = <String, List<BillDataModel>>{}.obs;

  final unprocessedTasks = <String, List<BillDataModel>>{}.obs;
  final notMatchedTasks = <String, List<BillDataModel>>{}.obs;
  final completedTasks = <String, List<BillDataModel>>{}.obs;
  final depositsTasks = <String, List<BillDataModel>>{}.obs;

  final returnPurchasesListTasks = <String, List<ReturnProduct>>{}.obs;
  final deliveredPurchasesTasks = <String, List<ReturnProduct>>{}.obs;

  // singleton pattern
  static final BuyingServes _instance = BuyingServes._internal();
  factory BuyingServes() => _instance;
  BuyingServes._internal();
}
