import '../../../../../../core/databases/api/end_points.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';

class OnlineStoreAuditController extends OnlineStoreResourceController {
  OnlineStoreAuditController(OnlineStoreRepository repository)
      : super(repository, EndPoints.onlineStoreAuditEvents);

  final entityType = 'all'.obs;
  final actionFilter = 'all'.obs;
  final actorUserId = ''.obs;
  final from = ''.obs;
  final to = ''.obs;
  final fromController = TextEditingController();
  final toController = TextEditingController();

  Future<void> applyFilters() {
    from.value = fromController.text.trim();
    to.value = toController.text.trim();
    return load(query: {
      if (entityType.value != 'all') 'entity_type': entityType.value,
      if (actionFilter.value != 'all') 'action': actionFilter.value,
      if (int.tryParse(actorUserId.value) != null)
        'actor_user_id': int.parse(actorUserId.value),
      if (from.value.isNotEmpty) 'from': from.value,
      if (to.value.isNotEmpty) 'to': to.value,
    });
  }

  @override
  void onClose() {
    fromController.dispose();
    toController.dispose();
    super.onClose();
  }
}
