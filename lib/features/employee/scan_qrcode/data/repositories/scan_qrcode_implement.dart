import 'package:dartz/dartz.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/scan_qrcode_repository.dart';
import '../datasources/scan_qrcode_datasource.dart';
import '../models/qr_scan_result.dart';

class ScanQrCodeImplement implements ScanQrCodeRepository {
  final NetworkInfo networkInfo;
  final ScanQrCodeDatasource scanQrcodeDatasource;

  ScanQrCodeImplement(
      {required this.networkInfo, required this.scanQrcodeDatasource});

  // scan QR code
  @override
  Future<Either<Failure, QrScanResult>> qrScan({
    required String qrData,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await scanQrcodeDatasource.qrScan(qrData: qrData);
      if (result.status == 'success') {
        return Right(result);
      }
      return Left(
        ValidationFailure(
          result.message.isNotEmpty ? result.message : 'Unknown error',
          <String, dynamic>{'status': result.status, 'message': result.message},
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
