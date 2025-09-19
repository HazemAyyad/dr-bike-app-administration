import '../../data/models/followup_modle.dart';
import '../repositories/followup_repository.dart';

class GetFollowupUsecase {
  final FollowupRepository followupRepository;

  GetFollowupUsecase({required this.followupRepository});

  Future<List<FollowupModel>> call() {
    return followupRepository.getFollowup();
  }
}
