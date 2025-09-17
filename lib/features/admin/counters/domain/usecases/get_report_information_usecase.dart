import '../../data/models/report_information_model.dart';
import '../repositories/counters_repository.dart';

class GetReportInformationUsecase {
  final CountersRepository countersRepository;

  GetReportInformationUsecase({required this.countersRepository});

  Future<ReportInformationModel> call() {
    return countersRepository.getReportInformation();
  }
}
