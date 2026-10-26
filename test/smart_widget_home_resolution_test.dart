import 'package:doctorbike/features/smart_home/data/smart_home_api_service.dart';
import 'package:doctorbike/features/smart_home/data/smart_home_native_service.dart';
import 'package:doctorbike/features/smart_home/presentation/controllers/smart_home_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SmartHomeController controller() => SmartHomeController(
        apiService: SmartHomeApiService(),
        nativeService: SmartHomeNativeService(),
      );

  test('unassigned widgets keep the Tuya home stored in device metadata', () {
    final state = controller();
    final device = SmartDeviceModel.fromJson({
      'id': 1,
      'smart_home_id': null,
      'raw_metadata': {
        'device': {'tuya_home_id': '501'}
      },
    });
    expect(state.tuyaHomeIdForDevice(device), '501');
  });

  test('each widget resolves its own home without switching the selected home',
      () {
    final state = controller();
    state.homes.addAll([
      SmartHomeModel.fromJson({'id': 1, 'tuya_home_id': '501'}),
      SmartHomeModel.fromJson({'id': 2, 'tuya_home_id': '502'}),
    ]);
    state.selectedLocationKey.value = 'home:1';
    expect(
        state.tuyaHomeIdForDevice(SmartDeviceModel.fromJson({
          'id': 1,
          'smart_home_id': 1,
        })),
        '501');
    expect(
        state.tuyaHomeIdForDevice(SmartDeviceModel.fromJson({
          'id': 2,
          'smart_home_id': 2,
        })),
        '502');
    expect(state.selectedLocationKey.value, 'home:1');
  });
}
