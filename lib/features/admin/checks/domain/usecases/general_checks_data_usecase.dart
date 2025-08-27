import '../../data/models/general_checks_data_model.dart';
import '../repositories/checks_repository.dart';

class GeneralChecksDataUsecase {
  final ChecksRepository checksRepository;

  GeneralChecksDataUsecase({required this.checksRepository});

  Future<GeneralChecksDataModel> call() {
    return checksRepository.generalChecksData();
  }
}
