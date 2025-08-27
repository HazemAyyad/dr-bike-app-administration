import '../repositories/checks_repository.dart';

class GeneralOutgoingDataUsecase {
  final ChecksRepository checksRepository;

  GeneralOutgoingDataUsecase({required this.checksRepository});

  Future<dynamic> call({required bool isInComing}) {
    return checksRepository.generalOutgoingData(isInComing: isInComing);
  }
}
