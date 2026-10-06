import 'package:get/get.dart';

import '../../../../../../core/databases/api/end_points.dart';
import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';

class OnlineStoreSettingsController extends GetxController {
  OnlineStoreSettingsController(this.repository);
  final OnlineStoreRepository repository;
  final values = <String, dynamic>{}.obs;
  final loading = false.obs;
  final saving = false.obs;
  final error = RxnString();
  final operatingState = ''.obs;

  String get effectiveOperatingState {
    if (values['store_enabled'] == false) return 'disabled';
    if (values['maintenance_mode'] == true) return 'maintenance';
    if (values['checkout_enabled'] == false) return 'browse_only';
    return 'open';
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      final json = await repository.get(EndPoints.onlineStoreSettings);
      values.assignAll(onlineStoreMap(json['data']).isEmpty
          ? json
          : onlineStoreMap(json['data']));
      operatingState.value =
          '${onlineStoreMap(json['meta'])['operating_state'] ?? ''}';
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> save() async {
    saving.value = true;
    try {
      final payload = Map<String, dynamic>.of(values)
        ..['out_of_stock_behavior'] = 'visible_non_purchasable'
        ..removeWhere((key, _) => {
              'id',
              'created_at',
              'updated_at',
              'updated_by',
            }.contains(key));
      await repository.put(EndPoints.onlineStoreSettings, data: payload);
      await load();
    } catch (e) {
      error.value = e.toString();
    } finally {
      saving.value = false;
    }
  }
}
