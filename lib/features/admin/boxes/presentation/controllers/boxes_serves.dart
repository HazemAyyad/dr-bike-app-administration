import 'package:get/get.dart';

import '../../data/models/all_boxes_logs_model.dart';
import '../../data/models/get_shown_boxes_model.dart';

class BoxesServes {
  final RxList<GetShownBoxesModel> shownBoxes = <GetShownBoxesModel>[].obs;

  final RxList<BoxLogModel> allBoxesLogs = <BoxLogModel>[].obs;

  final RxList<GetShownBoxesModel> shownBoxesArchive =
      <GetShownBoxesModel>[].obs;

  // singleton pattern
  static final BoxesServes _instance = BoxesServes._internal();
  factory BoxesServes() => _instance;
  BoxesServes._internal();
}
