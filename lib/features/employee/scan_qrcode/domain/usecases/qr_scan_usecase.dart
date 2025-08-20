import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/scan_qrcode_repository.dart';

class QrScanUsecase {
  final ScanQrCodeRepository scanQrCodeRepository;

  QrScanUsecase({required this.scanQrCodeRepository});

  Future<Either<Failure, String>> call({required String qrData}) {
    return scanQrCodeRepository.qrScan(qrData: qrData);
  }
}
