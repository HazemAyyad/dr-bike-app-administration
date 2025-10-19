import '../../data/models/box_details_model.dart';
import '../repositories/boxes_repository.dart';

class BoxDetailsUesecase {
  BoxesRepository boxesRepository;
  BoxDetailsUesecase({required this.boxesRepository});

  Future<BoxDetailsModel> call({required String boxId}) {
    return boxesRepository.boxDetails(boxId: boxId);
  }
}
