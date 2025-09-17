import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/counters/data/models/report_information_model.dart';
import 'package:flutter/services.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/counters_repository.dart';
import '../datasources/countrers_datasource.dart';

class CountrersImplement implements CountersRepository {
  final NetworkInfo networkInfo;
  final CountrersDatasource countrersDataSource;

  CountrersImplement(
      {required this.networkInfo, required this.countrersDataSource});

  @override
  Future<ReportInformationModel> getReportInformation() async {
    if (await networkInfo.isConnected) {
      try {
        final reportInformation =
            await countrersDataSource.getReportInformation();
        return reportInformation;
      } on ServerException catch (e) {
        throw ServerException(e.errorModel);
      }
    } else {
      throw ServerFailure('No internet connection', 500);
    }
  }

  // download report
  @override
  Future<Either<Failure, Uint8List>> getReportByType({
    required String type,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final reportInformation = await countrersDataSource.getReportByType(
          type: type,
          fromDate: fromDate,
          toDate: toDate,
        );
        return Right(reportInformation);
      } on ServerException catch (e) {
        throw ServerException(e.errorModel);
      }
    } else {
      throw ServerFailure('No internet connection', 500);
    }
  }
}
