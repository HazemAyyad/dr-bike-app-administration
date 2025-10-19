import '../repositories/checks_repository.dart';

class GetChecksUsecase {
  final ChecksRepository checksRepository;

  GetChecksUsecase({required this.checksRepository});

  Future<dynamic> call({required String endPoint}) {
    return checksRepository.getChecks(endPoint: endPoint);
  }
}
