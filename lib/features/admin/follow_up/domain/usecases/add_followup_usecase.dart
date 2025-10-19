import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/followup_repository.dart';

class AddFollowupUsecase {
  final FollowupRepository followupRepository;

  AddFollowupUsecase({required this.followupRepository});

  Future<Either<Failure, String>> call({
    required String followupId,
    required String customerId,
    required String sellerId,
    required String productId,
    required String status,
  }) {
    return followupRepository.addAndUpdateFollowup(
      followupId: followupId,
      customerId: customerId,
      sellerId: sellerId,
      productId: productId,
      status: status,
    );
  }
}
