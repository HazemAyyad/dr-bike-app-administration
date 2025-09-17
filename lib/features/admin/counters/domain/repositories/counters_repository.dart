import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/report_information_model.dart';

abstract class CountersRepository {
  Future<ReportInformationModel> getReportInformation();

  Future<Either<Failure, Uint8List>> getReportByType({
    required String type,
    DateTime? fromDate,
    DateTime? toDate,
  });
}
