import '../../../data/models/assets_models/assets_log_model.dart';
import '../../repositories/financial_affairs_repository.dart';

class GetAssetsLogsUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  GetAssetsLogsUsecase({required this.financialAffairsRepository});

  Future<List<AssetLogModel>> call() {
    return financialAffairsRepository.getAssetsLogs();
  }
}
