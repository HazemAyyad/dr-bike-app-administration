import '../../../data/models/assets_models/assets_detials_model.dart';
import '../../repositories/financial_affairs_repository.dart';

class AssetsDetialsUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  AssetsDetialsUsecase({required this.financialAffairsRepository});

  Future<AssetDetailsModel> call({required String assetId}) {
    return financialAffairsRepository.assetsDetails(assetId: assetId);
  }
}
