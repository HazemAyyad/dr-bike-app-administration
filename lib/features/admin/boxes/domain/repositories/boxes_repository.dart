import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/all_boxes_logs_model.dart';
import '../../data/models/box_details_model.dart';
import '../../data/models/get_shown_boxes_model.dart';

abstract class BoxesRepository {
  Future<Either<Failure, String>> addBox({
    required String boxName,
    required String total,
    required String currency,
  });

  Future<List<GetShownBoxesModel>> getShownBoxes({required int screen});

  Future<List<BoxLogModel>> getAllBoxesLogs();

  Future<Either<Failure, String>> transferBoxBalance({
    required String fromBoxId,
    required String toBoxId,
    required String total,
  });

  Future<BoxDetailsModel> boxDetails({required String boxId});

  Future<Either<Failure, String>> addBoxBalance({
    required String boxId,
    required String total,
  });

  Future<Either<Failure, String>> editBox({
    required String boxId,
    required String name,
    required String total,
    required String isShown,
    required String currency,
  });
}
