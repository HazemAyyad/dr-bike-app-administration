import '../../data/models/followup_modle.dart';
import '../repositories/followup_repository.dart';

class GetFollowupUsecase {
  final FollowupRepository followupRepository;

  GetFollowupUsecase({required this.followupRepository});

  Future<List<FollowupModel>> call({required int page}) {
    return followupRepository.getFollowup(page: page);
  }
}
