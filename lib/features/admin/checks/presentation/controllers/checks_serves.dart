import 'package:get/get.dart';
import '../../data/models/general_checks_data_model.dart';

class ChecksServes {
  final Rxn<GeneralChecksDataModel> generalChecksData =
      Rxn<GeneralChecksDataModel>(null);

  // singleton pattern
  static final ChecksServes _instance = ChecksServes._internal();
  factory ChecksServes() => _instance;
  ChecksServes._internal();
}
