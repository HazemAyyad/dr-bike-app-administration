import '../../data/models/get_shown_boxes_model.dart';
import '../repositories/boxes_repository.dart';

class GetShownBoxUsecase {
  BoxesRepository boxesRepository;
  GetShownBoxUsecase({required this.boxesRepository});

  Future<List<ShownBoxesModel>> call({required int screen}) {
    return boxesRepository.getShownBoxes(screen: screen);
  }
}
