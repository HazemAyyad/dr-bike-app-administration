import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/qr_scan_result.dart';

abstract class ScanQrCodeRepository {
  Future<Either<Failure, QrScanResult>> qrScan({required String qrData});
}
