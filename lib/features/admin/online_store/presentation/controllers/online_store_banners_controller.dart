import '../../../../../../core/databases/api/end_points.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';
import 'package:image_picker/image_picker.dart';

class OnlineStoreBannersController extends OnlineStoreResourceController {
  OnlineStoreBannersController(OnlineStoreRepository repository)
      : super(repository, EndPoints.onlineStoreBanners);

  Future<void> reorderBanners(List<int> ids) => repository.reorderBanners(ids);

  Future<String> uploadImage(XFile file) => repository.uploadContentImage(file);
}
