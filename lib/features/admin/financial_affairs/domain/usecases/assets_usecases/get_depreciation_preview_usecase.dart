import '../../../data/models/assets_models/asset_depreciation_preview_model.dart';
import '../../repositories/financial_affairs_repository.dart';

class GetDepreciationPreviewUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  const GetDepreciationPreviewUsecase({
    required this.financialAffairsRepository,
  });

  Future<AssetDepreciationPreview> call() =>
      financialAffairsRepository.getDepreciationPreview();
}
