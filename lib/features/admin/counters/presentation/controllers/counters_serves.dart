import 'package:get/get.dart';
import '../../data/models/report_information_model.dart';

class CountersServes {
  final Rxn<ReportInformationModel> reportInformationData =
      Rxn<ReportInformationModel>(null);

  // singleton pattern
  static final CountersServes _instance = CountersServes._internal();
  factory CountersServes() => _instance;
  CountersServes._internal();
}
