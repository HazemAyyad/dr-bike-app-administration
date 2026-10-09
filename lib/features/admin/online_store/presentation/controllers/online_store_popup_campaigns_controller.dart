import 'package:image_picker/image_picker.dart';

import '../../../../../../core/databases/api/end_points.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';

class OnlineStorePopupCampaignsController
    extends OnlineStoreResourceController {
  OnlineStorePopupCampaignsController(OnlineStoreRepository repository)
      : super(repository, EndPoints.onlineStorePopupCampaigns);

  Future<String> uploadImage(XFile file) => repository.uploadContentImage(file);
}
