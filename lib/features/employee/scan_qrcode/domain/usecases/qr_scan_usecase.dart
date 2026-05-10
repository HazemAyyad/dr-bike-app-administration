import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/scan_qrcode_repository.dart';
import '../../data/models/qr_scan_result.dart';

class QrScanUsecase {
  final ScanQrCodeRepository scanQrCodeRepository;

  QrScanUsecase({required this.scanQrCodeRepository});

  Future<Either<Failure, QrScanResult>> call({required String qrData}) {
    return scanQrCodeRepository.qrScan(qrData: qrData);
  }
}
