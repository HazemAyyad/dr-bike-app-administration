import 'package:dartz/dartz.dart';
import 'dart:typed_data';

import '../../../../../core/errors/failure.dart';
import '../../data/models/report_information_model.dart';

abstract class CountersRepository {
  Future<ReportInformationModel> getReportInformation();

  Future<Either<Failure, Uint8List>> getReportByType({
    required String type,
    String? employeeId,
    DateTime? fromDate,
    DateTime? toDate,
    String? boxId,
  });
}
