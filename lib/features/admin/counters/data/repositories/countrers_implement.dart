import 'package:dartz/dartz.dart';
import 'dart:typed_data';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/counters_repository.dart';
import '../datasources/countrers_datasource.dart';
import '../models/report_information_model.dart';

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
    String? employeeId,
    DateTime? fromDate,
    DateTime? toDate,
    String? boxId,
    String? direction,
    List<String>? movementTypes,
    String? search,
    double? minAmount,
    double? maxAmount,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final reportInformation = await countrersDataSource.getReportByType(
          type: type,
          employeeId: employeeId,
          fromDate: fromDate,
          toDate: toDate,
          boxId: boxId,
          direction: direction,
          movementTypes: movementTypes,
          search: search,
          minAmount: minAmount,
          maxAmount: maxAmount,
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
