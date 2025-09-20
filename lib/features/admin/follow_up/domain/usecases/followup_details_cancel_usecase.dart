import '../repositories/followup_repository.dart';

class FollowupDetailsCancelUsecase {
  final FollowupRepository followupRepository;

  FollowupDetailsCancelUsecase({required this.followupRepository});

  Future<dynamic> call({
    required String followupId,
    required bool isCancel,
  }) {
    return followupRepository.getfollowupDetailsAndCancel(
      followupId: followupId,
      isCancel: isCancel,
    );
  }
}
