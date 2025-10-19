import 'package:get/get.dart';

import '../../data/models/debts_we_owe_model.dart';
import '../../data/models/total_debts_owed_to_us_model.dart';
import '../../data/models/total_debts_we_owe_model.dart';
import '../../data/models/user_transactions_data_model.dart';

class DebtsDataService {
  final Rxn<TotalDebtsWeOweModel> totalDebtsWeOweModel =
      Rxn<TotalDebtsWeOweModel>();

  final Rxn<TotalDebtsOwedToUsModel> totalDebtsOwedToUsModel =
      Rxn<TotalDebtsOwedToUsModel>();

  final Rxn<DebtsWeOweModel> debtsWeOweModel = Rxn<DebtsWeOweModel>();

  final Rxn<DebtsWeOweModel> debtsOwedToUsModel = Rxn<DebtsWeOweModel>();

  String customerId = '';
  final Rxn<UserTransactionsDataModel> userTransactionsDataModel =
      Rxn<UserTransactionsDataModel>();

  // singleton pattern
  static final DebtsDataService _instance = DebtsDataService._internal();
  factory DebtsDataService() => _instance;
  DebtsDataService._internal();
}
