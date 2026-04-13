import 'package:doctorbike/features/admin/financial_affairs/data/models/assets_models/assets_data_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/assets_models/assets_log_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/expenses_models/destruction_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/expenses_models/expense_data_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/official_papers_models/file_data_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/official_papers_models/files_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/official_papers_models/papers_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/official_papers_models/pictures_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/official_papers_models/safes_model.dart';
import 'package:get/get.dart';

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

  /// Backing store is always a Dart growable list (never a JSArray from GetX/assignAll).
  final List<FilesModel> _filesData = <FilesModel>[];

  /// Web-safe: returns a fresh `List<FilesModel>` so callers never see `JSArray<…>`.
  List<FilesModel> get filesData => List<FilesModel>.from(_filesData);

  /// Replaces file rows from API; normalizes through [List.from] to avoid JSArray backing.
  void updateFilesData(Iterable<FilesModel> items) {
    _filesData
      ..clear()
      ..addAll(List<FilesModel>.from(items));
  }

  List<SafesModel> safes = [];

  List<FilePapersModel> filesPapers = [];

  // singleton pattern
  static final FinacialService _instance = FinacialService._internal();
  factory FinacialService() => _instance;
  FinacialService._internal();
}
