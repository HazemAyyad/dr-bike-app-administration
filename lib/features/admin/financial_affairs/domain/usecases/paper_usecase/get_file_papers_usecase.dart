import '../../../presentation/views/official_papers_screens/file_data_model.dart';
import '../../repositories/financial_affairs_repository.dart';

class GetFilePapersUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  GetFilePapersUsecase({required this.financialAffairsRepository});

  Future<List<FilePapersModel>> call({required String fileId}) {
    return financialAffairsRepository.getFilePapers(fileId: fileId);
  }
}
