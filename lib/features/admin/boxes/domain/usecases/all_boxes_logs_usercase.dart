import '../../data/models/all_boxes_logs_model.dart';
import '../repositories/boxes_repository.dart';

class AllBoxesLogsUsercase {
  BoxesRepository boxesRepository;
  AllBoxesLogsUsercase({required this.boxesRepository});

  Future<List<BoxLogModel>> call() {
    return boxesRepository.getAllBoxesLogs();
  }
}
