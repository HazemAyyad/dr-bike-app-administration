import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';

abstract class ScanQrCodeRepository {
  Future<Either<Failure, String>> qrScan({required String qrData});
}
