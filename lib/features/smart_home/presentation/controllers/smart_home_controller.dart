import 'package:get/get.dart';

import '../../data/smart_home_api_service.dart';
import '../../data/smart_home_native_service.dart';

class SmartHomeController extends GetxController {
  SmartHomeController({
    required this.apiService,
    required this.nativeService,
  });

  final SmartHomeApiService apiService;
  final SmartHomeNativeService nativeService;

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;
  final nativeStatus = const SmartHomeNativeStatus(
    initialized: false,
    platform: '',
    message: '',
  ).obs;
  final homes = <SmartHomeModel>[].obs;
  final rooms = <SmartRoomModel>[].obs;
  final devices = <SmartDeviceModel>[].obs;
  final tuyaUser = Rxn<SmartHomeTuyaUserModel>();
  final isLinkingTuyaUser = false.obs;
  final isPairingDevice = false.obs;

  SmartHomeModel? get selectedHome =>
      homes.firstWhereOrNull((home) => home.isDefault) ??
      (homes.isNotEmpty ? homes.first : null);

  int get devicesCount => selectedHome?.devicesCount ?? devices.length;
  int get onlineDevicesCount =>
      selectedHome?.onlineDevicesCount ??
      devices.where((device) => device.online).length;
  int get offlineDevicesCount =>
      selectedHome?.offlineDevicesCount ??
      devices.where((device) => !device.online).length;
  bool get isTuyaUserLinked => tuyaUser.value?.linked == true;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading(true);
    errorMessage('');
    try {
      nativeStatus.value = await nativeService.getStatus();
      tuyaUser.value = await apiService.getTuyaUser();
      await ensureTuyaUserLinked();

      final loadedHomes = await apiService.getHomes();
      if (loadedHomes.isEmpty) {
        final created = await apiService.createHome('smartHomeDefaultName'.tr);
        homes.assignAll([created]);
      } else {
        homes.assignAll(loadedHomes);
      }
      await _loadSelectedHomeData();
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> refreshData() async {
    isRefreshing(true);
    try {
      await load();
    } finally {
      isRefreshing(false);
    }
  }

  Future<void> ensureTuyaUserLinked() async {
    if (!nativeStatus.value.initialized || isTuyaUserLinked) return;

    final credentials = tuyaUser.value?.uidLogin;
    if (credentials == null ||
        credentials.uid.isEmpty ||
        credentials.password.isEmpty) {
      return;
    }

    isLinkingTuyaUser(true);
    try {
      final result = await nativeService.loginWithUid(
        countryCode: credentials.countryCode,
        uid: credentials.uid,
        password: credentials.password,
      );
      if (!result.success) {
        errorMessage(result.message.isNotEmpty ? result.message : result.code);
        return;
      }
      tuyaUser.value = await apiService.updateTuyaUser(
        tuyaUid: result.uid.isNotEmpty ? result.uid : credentials.uid,
        region: tuyaUser.value?.region,
        rawMetadata: {
          'login_type': 'uid',
          'native_message': result.message,
        },
      );
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLinkingTuyaUser(false);
    }
  }

  Future<void> startDevicePairing({
    required String ssid,
    required String password,
  }) async {
    final home = selectedHome;
    if (home == null) {
      errorMessage('smartHomeMissingHome'.tr);
      return;
    }
    if (!nativeStatus.value.initialized || !isTuyaUserLinked) {
      errorMessage('smartHomeTuyaNotReady'.tr);
      return;
    }
    if (ssid.trim().isEmpty) {
      errorMessage('smartHomeWifiNameRequired'.tr);
      return;
    }

    isPairingDevice(true);
    errorMessage('');
    try {
      var activeHome = home;
      var tuyaHomeId = activeHome.tuyaHomeId;
      if (tuyaHomeId.isEmpty) {
        final nativeHome =
            await nativeService.createHome(name: activeHome.name);
        if (!nativeHome.success || nativeHome.tuyaHomeId.isEmpty) {
          errorMessage(
            nativeHome.message.isNotEmpty
                ? nativeHome.message
                : nativeHome.code,
          );
          return;
        }
        activeHome = await apiService.updateHomeTuyaId(
          homeId: activeHome.id,
          tuyaHomeId: nativeHome.tuyaHomeId,
        );
        final index = homes.indexWhere((item) => item.id == activeHome.id);
        if (index >= 0) {
          homes[index] = activeHome;
        } else {
          homes.add(activeHome);
        }
        tuyaHomeId = activeHome.tuyaHomeId;
      }

      final pairing = await nativeService.startWifiPairing(
        tuyaHomeId: tuyaHomeId,
        ssid: ssid.trim(),
        password: password,
      );
      if (!pairing.success) {
        errorMessage(
            pairing.message.isNotEmpty ? pairing.message : pairing.code);
        return;
      }
      final registered = await apiService.registerDevice(
        smartHomeId: activeHome.id,
        device: pairing.device,
      );
      final existing = devices.indexWhere((item) => item.id == registered.id);
      if (existing >= 0) {
        devices[existing] = registered;
      } else {
        devices.add(registered);
      }
      await refreshData();
      Get.snackbar('addDevice'.tr, 'smartHomeDevicePaired'.tr);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isPairingDevice(false);
    }
  }

  Future<void> _loadSelectedHomeData() async {
    final home = selectedHome;
    if (home == null) {
      rooms.clear();
      devices.clear();
      return;
    }
    final loadedRooms = await apiService.getRooms(home.id);
    final loadedDevices = await apiService.getDevices(homeId: home.id);
    rooms.assignAll(loadedRooms);
    devices.assignAll(loadedDevices);
  }
}
