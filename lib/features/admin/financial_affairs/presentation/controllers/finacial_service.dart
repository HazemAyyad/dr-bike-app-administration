import 'package:get/get.dart';

import '../../data/models/assets_models/assets_data_model.dart';
import '../../data/models/assets_models/assets_log_model.dart';
import '../../data/models/expenses_models/destruction_model.dart';
import '../../data/models/expenses_models/expense_data_model.dart';
import '../../data/models/official_papers_models/files_model.dart';
import '../../data/models/official_papers_models/papers_model.dart';
import '../../data/models/official_papers_models/pictures_model.dart';

class FinacialService {
  // assets
  final Rxn<AssetsModel> assets = Rxn();

  final Map<String, List<Asset>> assetsTasks = {};

  List<AssetLogModel> assetsLogs = [];

  // expenses
  List<ExpenseModel> expenses = [];

  final Map<String, List<ExpenseModel>> expensesTasks = {};

  List<DestructionModel> destructions = [];

  final Map<String, List<DestructionModel>> destructionsTasks = {};

  // papers
  List<PaperModel> papers = [];

  List<PictureModel> pictures = [];

  List<FilesModel> files = [];

  // singleton pattern
  static final FinacialService _instance = FinacialService._internal();
  factory FinacialService() => _instance;
  FinacialService._internal();
}
