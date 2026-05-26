import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/followup_repository.dart';

class DeleteFollowupUsecase {
  final FollowupRepository followupRepository;

  DeleteFollowupUsecase({required this.followupRepository});

  Future<Either<Failure, String>> call({required String followupId}) {
    return followupRepository.deleteFollowup(followupId: followupId);
  }
}
