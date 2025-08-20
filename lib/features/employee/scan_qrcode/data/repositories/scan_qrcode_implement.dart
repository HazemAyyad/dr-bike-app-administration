import 'package:dartz/dartz.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/scan_qrcode_repository.dart';
import '../datasources/scan_qrcode_datasource.dart';

class ScanQrCodeImplement implements ScanQrCodeRepository {
  final NetworkInfo networkInfo;
  final ScanQrCodeDatasource scanQrcodeDatasource;

  ScanQrCodeImplement(
      {required this.networkInfo, required this.scanQrcodeDatasource});

  // scan QR code
  @override
  Future<Either<Failure, String>> qrScan({
    required String qrData,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await scanQrcodeDatasource.qrScan(qrData: qrData);
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
