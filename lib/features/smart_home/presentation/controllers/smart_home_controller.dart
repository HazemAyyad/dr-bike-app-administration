import 'dart:async';

import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/final_classes.dart';
import '../../../../core/services/initial_bindings.dart';
import '../../data/smart_home_api_service.dart';
import '../../data/smart_home_native_service.dart';
import '../../data/tuya_device_capability_resolver.dart';

const Duration _smartHomePairingTimeout = Duration(seconds: 150);
const String _smartHomeWifiSsidKey = 'smart_home_wifi_ssid';
const String _smartHomeWifiPasswordKey = 'smart_home_wifi_password';
const String smartHomeUnassignedLocationKey = 'unassigned';

class SmartHomeWifiCredentials {
  const SmartHomeWifiCredentials({required this.ssid, required this.password});

  final String ssid;
  final String password;
}

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
  final owners = <SmartHomeOwnerModel>[].obs;
  final selectedOwnerId = RxnInt();
  final selectedLocationKey = ''.obs;
  final selectedRoomId = RxnInt();
  final homes = <SmartHomeModel>[].obs;
  final rooms = <SmartRoomModel>[].obs;
  final devices = <SmartDeviceModel>[].obs;
  final tuyaUser = Rxn<SmartHomeTuyaUserModel>();
  final isLinkingTuyaUser = false.obs;
  final isPairingDevice = false.obs;
  final isScanningBluetooth = false.obs;
  final bluetoothDevices = <SmartHomeBleScanDevice>[].obs;
  final selectedBluetoothDevice = Rxn<SmartHomeBleScanDevice>();
  final deviceControlBusyIds = <int>{}.obs;
  final deviceDetailsBusyIds = <int>{}.obs;
  final Map<int, Map<String, dynamic>> _deviceRefreshFailures = {};
  String _activeNativeTuyaUid = '';

  SmartHomeModel? get selectedHome {
    final key = selectedLocationKey.value;
    if (key.startsWith('home:')) {
      final id = int.tryParse(key.substring(5));
      final selected = homes.firstWhereOrNull((home) => home.id == id);
      if (selected != null) return selected;
    }
    return homes.firstWhereOrNull((home) => home.isDefault) ??
        (homes.isNotEmpty ? homes.first : null);
  }

  bool get isUnassignedSelected =>
      selectedLocationKey.value == smartHomeUnassignedLocationKey;

  List<SmartDeviceModel> get visibleDevices {
    if (isUnassignedSelected) {
      return devices
          .where((device) => device.smartHomeId == null)
          .toList(growable: false);
    }
    final roomId = selectedRoomId.value;
    if (roomId == null) return devices.toList(growable: false);
    return devices
        .where((device) => device.smartRoomId == roomId)
        .toList(growable: false);
  }

  int get devicesCount => selectedHome?.devicesCount ?? devices.length;
  int get onlineDevicesCount =>
      selectedHome?.onlineDevicesCount ??
      devices.where((device) => device.online).length;
  int get offlineDevicesCount =>
      selectedHome?.offlineDevicesCount ??
      devices.where((device) => !device.online).length;
  bool get isTuyaUserLinked => tuyaUser.value?.linked == true;
  bool get canViewSmartHomeOwners => userType == 'admin';
  SmartHomeOwnerModel? get selectedOwner => selectedOwnerId.value == null
      ? null
      : owners.firstWhereOrNull((owner) => owner.id == selectedOwnerId.value);

  String formatVisibleError(String fallback, {String? code, String? message}) {
    final parts = <String>[fallback];
    if (code != null && code.isNotEmpty) parts.add('[$code]');
    if (message != null && message.isNotEmpty) parts.add(message);
    return parts.join(' ');
  }

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
      if (canViewSmartHomeOwners) {
        final loadedOwners = await apiService.getOwners();
        owners.assignAll(loadedOwners);
        final selectedStillExists =
            loadedOwners.any((owner) => owner.id == selectedOwnerId.value);
        if (loadedOwners.isEmpty) {
          selectedOwnerId.value = null;
        } else if (selectedOwnerId.value == null || !selectedStillExists) {
          selectedOwnerId.value = loadedOwners.first.id;
        }
      } else {
        owners.clear();
        selectedOwnerId.value = null;
      }

      tuyaUser.value = await apiService.getTuyaUser(
        userId: selectedOwnerId.value,
      );
      await ensureTuyaUserLinked();

      final loadedHomes =
          await apiService.getHomes(userId: selectedOwnerId.value);
      if (loadedHomes.isEmpty) {
        if (selectedOwnerId.value == null) {
          final created =
              await apiService.createHome('smartHomeDefaultName'.tr);
          homes.assignAll([created]);
        } else {
          homes.clear();
        }
      } else {
        homes.assignAll(loadedHomes);
      }
      _ensureSelectedLocation();
      await _loadSelectedHomeData();
      await refreshLoadedDeviceStatuses();
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

  Future<void> selectOwner(int? ownerId) async {
    if (!canViewSmartHomeOwners || selectedOwnerId.value == ownerId) return;
    selectedOwnerId.value = ownerId;
    selectedLocationKey.value = '';
    selectedRoomId.value = null;
    await refreshData();
  }

  Future<void> selectLocationKey(String key) async {
    isRefreshing(true);
    try {
      if (selectedLocationKey.value != key) {
        selectedLocationKey.value = key;
        selectedRoomId.value = null;
      }
      await _loadSelectedHomeData();
      _refreshLoadedDeviceStatusesInBackground();
    } finally {
      isRefreshing(false);
    }
  }

  void selectRoom(int? roomId) {
    selectedRoomId.value = roomId;
    selectedRoomId.refresh();
  }

  Future<bool> createLocation({
    required String name,
    required String type,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;
    isRefreshing(true);
    try {
      final created = await apiService.createHome(
        cleanName,
        type: type,
        userId: selectedOwnerId.value,
      );
      homes.add(created);
      selectedLocationKey.value = 'home:${created.id}';
      selectedRoomId.value = null;
      await _loadSelectedHomeData();
      return true;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isRefreshing(false);
    }
  }

  Future<bool> createRoom(String name) async {
    final home = selectedHome;
    final cleanName = name.trim();
    if (home == null || cleanName.isEmpty || isUnassignedSelected) {
      return false;
    }
    isRefreshing(true);
    try {
      final room = await apiService.createRoom(
        homeId: home.id,
        name: cleanName,
        userId: selectedOwnerId.value,
      );
      rooms.add(room);
      selectedRoomId.value = room.id;
      return true;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isRefreshing(false);
    }
  }

  Future<bool> renameRoom({
    required SmartRoomModel room,
    required String name,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName == room.name) return false;
    isRefreshing(true);
    try {
      final updated = await apiService.updateRoom(
        id: room.id,
        name: cleanName,
        userId: selectedOwnerId.value,
      );
      final index = rooms.indexWhere((item) => item.id == updated.id);
      if (index >= 0) rooms[index] = updated;
      return true;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isRefreshing(false);
    }
  }

  Future<bool> deleteRoom(SmartRoomModel room) async {
    isRefreshing(true);
    try {
      await apiService.deleteRoom(id: room.id, userId: selectedOwnerId.value);
      rooms.removeWhere((item) => item.id == room.id);
      if (selectedRoomId.value == room.id) selectedRoomId.value = null;
      devices.assignAll(devices
          .map((device) => device.smartRoomId == room.id
              ? device.copyWith(smartRoomId: null)
              : device)
          .toList(growable: false));
      return true;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isRefreshing(false);
    }
  }

  Future<SmartHomeWifiCredentials> savedWifiCredentials() async {
    final ssid = await FinalClasses.secureStorage.read(
          key: _smartHomeWifiSsidKey,
        ) ??
        '';
    final password = await FinalClasses.secureStorage.read(
          key: _smartHomeWifiPasswordKey,
        ) ??
        '';
    return SmartHomeWifiCredentials(ssid: ssid, password: password);
  }

  Future<String> currentWifiSsid() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted && !status.isLimited) return '';

    final raw = await NetworkInfo().getWifiName();
    return _normalizeSsid(raw) ?? '';
  }

  String? _normalizeSsid(String? value) {
    var ssid = value?.trim();
    if (ssid == null || ssid.isEmpty || ssid == '<unknown ssid>') {
      return null;
    }
    if ((ssid.startsWith('"') && ssid.endsWith('"')) ||
        (ssid.startsWith("'") && ssid.endsWith("'"))) {
      ssid = ssid.substring(1, ssid.length - 1).trim();
    }
    return ssid.isEmpty ? null : ssid;
  }

  Future<void> saveWifiCredentials({
    required String ssid,
    required String password,
  }) async {
    final cleanSsid = ssid.trim();
    if (cleanSsid.isEmpty) return;

    await FinalClasses.secureStorage.write(
      key: _smartHomeWifiSsidKey,
      value: cleanSsid,
    );
    await FinalClasses.secureStorage.write(
      key: _smartHomeWifiPasswordKey,
      value: password,
    );
  }

  Future<void> ensureTuyaUserLinked() async {
    if (!nativeStatus.value.initialized) return;

    final credentials = tuyaUser.value?.uidLogin;
    if (credentials == null ||
        credentials.uid.isEmpty ||
        credentials.password.isEmpty) {
      return;
    }
    if (_activeNativeTuyaUid == credentials.uid) return;

    isLinkingTuyaUser(true);
    try {
      final result = await nativeService.loginWithUid(
        countryCode: credentials.countryCode,
        uid: credentials.uid,
        password: credentials.password,
      );
      if (!result.success) {
        final visible = formatVisibleError(
          'tuyaUserLinkFailed'.tr,
          code: result.code,
          message: result.message,
        );
        errorMessage(visible);
        await _logEvent(
          event: 'tuya_uid_login',
          success: false,
          errorCode: result.code,
          message: result.message,
        );
        return;
      }
      _activeNativeTuyaUid =
          result.uid.isNotEmpty ? result.uid : credentials.uid;
      tuyaUser.value = await apiService.updateTuyaUser(
        tuyaUid: result.uid.isNotEmpty ? result.uid : credentials.uid,
        region: tuyaUser.value?.region,
        userId: selectedOwnerId.value,
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

  Future<SmartHomeModel?> _ensureActiveTuyaHome(SmartHomeModel home) async {
    var activeHome = home;
    var tuyaHomeId = activeHome.tuyaHomeId;
    if (tuyaHomeId.isNotEmpty) return activeHome;

    final nativeHome = await nativeService.createHome(name: activeHome.name);
    if (!nativeHome.success || nativeHome.tuyaHomeId.isEmpty) {
      final visible =
          nativeHome.message.isNotEmpty ? nativeHome.message : nativeHome.code;
      errorMessage(visible);
      await _logEvent(
        smartHomeId: activeHome.id,
        event: 'tuya_home_create',
        success: false,
        errorCode: nativeHome.code,
        message: visible,
      );
      return null;
    }

    activeHome = await apiService.updateHomeTuyaId(
      homeId: activeHome.id,
      tuyaHomeId: nativeHome.tuyaHomeId,
      userId: selectedOwnerId.value,
    );
    final index = homes.indexWhere((item) => item.id == activeHome.id);
    if (index >= 0) {
      homes[index] = activeHome;
    } else {
      homes.add(activeHome);
    }
    await _logEvent(
      smartHomeId: activeHome.id,
      event: 'tuya_home_create',
      success: true,
      message: nativeHome.message,
      context: {'tuya_home_id': activeHome.tuyaHomeId},
    );
    return activeHome;
  }

  Future<bool> _ensureBluetoothPermissions() async {
    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];
    final statuses = await permissions.request();
    return statuses.values
        .every((status) => status.isGranted || status.isLimited);
  }

  Future<void> scanBluetoothDevices() async {
    if (!nativeStatus.value.initialized || !isTuyaUserLinked) {
      errorMessage('smartHomeTuyaNotReady'.tr);
      return;
    }
    final granted = await _ensureBluetoothPermissions();
    if (!granted) {
      errorMessage('smartHomeBluetoothPermissionRequired'.tr);
      return;
    }

    isScanningBluetooth(true);
    errorMessage('');
    selectedBluetoothDevice.value = null;
    try {
      final result = await nativeService.scanBluetoothDevices(timeoutMs: 10000);
      if (!result.success) {
        errorMessage(result.message.isNotEmpty
            ? result.message
            : 'smartHomeBluetoothScanFailed'.tr);
        await _logEvent(
          event: 'ble_scan',
          success: false,
          errorCode: result.code,
          message: result.message,
        );
        return;
      }
      bluetoothDevices.assignAll(result.devices);
      if (result.devices.isEmpty) {
        errorMessage('smartHomeBluetoothNoDevices'.tr);
      }
      await _logEvent(
        event: 'ble_scan',
        success: true,
        message: result.message,
        context: {'count': result.devices.length},
      );
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isScanningBluetooth(false);
    }
  }

  Future<bool> startBluetoothDevicePairing({
    required SmartHomeBleScanDevice scanDevice,
    required String ssid,
    required String password,
  }) async {
    final home = selectedHome;
    if (home == null) {
      errorMessage('smartHomeMissingHome'.tr);
      return false;
    }
    if (!nativeStatus.value.initialized || !isTuyaUserLinked) {
      errorMessage('smartHomeTuyaNotReady'.tr);
      return false;
    }
    if (scanDevice.isWifiCombo && ssid.trim().isEmpty) {
      errorMessage('smartHomeWifiNameRequired'.tr);
      return false;
    }

    await saveWifiCredentials(ssid: ssid, password: password);
    isPairingDevice(true);
    errorMessage('');
    try {
      final activeHome = await _ensureActiveTuyaHome(home);
      if (activeHome == null) return false;

      final pairing = await nativeService
          .startBluetoothPairing(
        tuyaHomeId: activeHome.tuyaHomeId,
        scanDevice: scanDevice,
        ssid: ssid.trim(),
        password: password,
      )
          .timeout(
        _smartHomePairingTimeout,
        onTimeout: () async {
          await nativeService.stopPairing();
          return SmartHomeNativePairingResult(
            success: false,
            code: 'ble_pairing_timeout',
            message: 'smartHomePairingTimedOut'.tr,
            device: const <String, dynamic>{},
          );
        },
      );
      if (!pairing.success) {
        final visible = pairing.message.isNotEmpty
            ? pairing.message
            : 'smartHomePairingFailed'.tr;
        errorMessage(visible);
        await _logEvent(
          smartHomeId: activeHome.id,
          event: 'ble_pairing',
          success: false,
          errorCode: pairing.code,
          message: visible,
          context: {
            'ssid': ssid.trim(),
            'scan_device': scanDevice.raw,
          },
        );
        return false;
      }
      final registered = await apiService.registerDevice(
        smartHomeId: activeHome.id,
        device: pairing.device,
        userId: selectedOwnerId.value,
      );
      final existing = devices.indexWhere((item) => item.id == registered.id);
      if (existing >= 0) {
        devices[existing] = registered;
      } else {
        devices.add(registered);
      }
      await refreshData();
      await _logEvent(
        smartHomeId: activeHome.id,
        event: 'ble_pairing',
        success: true,
        message: pairing.message,
        context: pairing.device,
      );
      Get.snackbar('addDevice'.tr, 'smartHomeDevicePaired'.tr);
      return true;
    } catch (e) {
      final visible = e.toString();
      errorMessage(visible);
      await _logEvent(
        smartHomeId: selectedHome?.id,
        event: 'ble_pairing',
        success: false,
        errorCode: 'ble_pairing_exception',
        message: visible,
        context: {
          'ssid': ssid.trim(),
          'scan_device': scanDevice.raw,
        },
      );
      return false;
    } finally {
      isPairingDevice(false);
    }
  }

  Future<bool> startDevicePairing({
    required String ssid,
    required String password,
  }) async {
    final home = selectedHome;
    if (home == null) {
      errorMessage('smartHomeMissingHome'.tr);
      await _logEvent(
          event: 'pairing_validation',
          success: false,
          message: 'Missing selected home');
      return false;
    }
    if (!nativeStatus.value.initialized || !isTuyaUserLinked) {
      errorMessage('smartHomeTuyaNotReady'.tr);
      await _logEvent(
          event: 'pairing_validation',
          success: false,
          message: 'Tuya not ready');
      return false;
    }
    if (ssid.trim().isEmpty) {
      errorMessage('smartHomeWifiNameRequired'.tr);
      await _logEvent(
          event: 'pairing_validation',
          success: false,
          message: 'Missing WiFi SSID');
      return false;
    }

    await saveWifiCredentials(ssid: ssid, password: password);

    isPairingDevice(true);
    errorMessage('');
    try {
      var activeHome = home;
      var tuyaHomeId = activeHome.tuyaHomeId;
      if (tuyaHomeId.isEmpty) {
        final nativeHome =
            await nativeService.createHome(name: activeHome.name);
        if (!nativeHome.success || nativeHome.tuyaHomeId.isEmpty) {
          final visible = nativeHome.message.isNotEmpty
              ? nativeHome.message
              : nativeHome.code;
          errorMessage(visible);
          await _logEvent(
            smartHomeId: activeHome.id,
            event: 'tuya_home_create',
            success: false,
            errorCode: nativeHome.code,
            message: visible,
          );
          return false;
        }
        activeHome = await apiService.updateHomeTuyaId(
          homeId: activeHome.id,
          tuyaHomeId: nativeHome.tuyaHomeId,
          userId: selectedOwnerId.value,
        );
        final index = homes.indexWhere((item) => item.id == activeHome.id);
        if (index >= 0) {
          homes[index] = activeHome;
        } else {
          homes.add(activeHome);
        }
        tuyaHomeId = activeHome.tuyaHomeId;
        await _logEvent(
          smartHomeId: activeHome.id,
          event: 'tuya_home_create',
          success: true,
          message: nativeHome.message,
          context: {'tuya_home_id': tuyaHomeId},
        );
      }

      final pairing = await nativeService
          .startWifiPairing(
        tuyaHomeId: tuyaHomeId,
        ssid: ssid.trim(),
        password: password,
      )
          .timeout(
        _smartHomePairingTimeout,
        onTimeout: () async {
          await nativeService.stopPairing();
          return SmartHomeNativePairingResult(
            success: false,
            code: 'pairing_timeout',
            message: 'smartHomePairingTimedOut'.tr,
            device: const <String, dynamic>{},
          );
        },
      );
      if (!pairing.success) {
        final visible = pairing.message.isNotEmpty
            ? pairing.message
            : 'smartHomePairingFailed'.tr;
        errorMessage(visible);
        await _logEvent(
          smartHomeId: activeHome.id,
          event: 'wifi_pairing',
          success: false,
          errorCode: pairing.code,
          message: visible,
          context: {'ssid': ssid.trim()},
        );
        return false;
      }
      final registered = await apiService.registerDevice(
        smartHomeId: activeHome.id,
        device: pairing.device,
        userId: selectedOwnerId.value,
      );
      final existing = devices.indexWhere((item) => item.id == registered.id);
      if (existing >= 0) {
        devices[existing] = registered;
      } else {
        devices.add(registered);
      }
      await refreshData();
      await _logEvent(
        smartHomeId: activeHome.id,
        event: 'wifi_pairing',
        success: true,
        message: pairing.message,
        context: pairing.device,
      );
      Get.snackbar('addDevice'.tr, 'smartHomeDevicePaired'.tr);
      return true;
    } catch (e) {
      final visible = e.toString();
      errorMessage(visible);
      await _logEvent(
        smartHomeId: selectedHome?.id,
        event: 'wifi_pairing',
        success: false,
        errorCode: 'pairing_exception',
        message: visible,
        context: {'ssid': ssid.trim()},
      );
      return false;
    } finally {
      isPairingDevice(false);
    }
  }

  Future<SmartDeviceModel> loadDeviceDetails(SmartDeviceModel device) async {
    deviceDetailsBusyIds.add(device.id);
    try {
      final loaded = await apiService.getDevice(
        device.id,
        userId: selectedOwnerId.value,
      );
      final native = await nativeService.getDeviceStatus(
        tuyaDeviceId: loaded.tuyaDeviceId,
        tuyaHomeId: _tuyaHomeIdForDevice(loaded),
      );
      var merged = loaded;
      if (native.success) {
        final nextStatus =
            native.dps.isNotEmpty ? native.dps : loaded.lastStatus;
        final nextMetadata =
            native.device.isNotEmpty ? native.device : loaded.rawMetadata;
        merged = loaded.copyWith(
          online: native.online,
          lastStatus: nextStatus,
          rawMetadata: nextMetadata,
          primaryPowerDp: _powerDpFromStatus(nextStatus),
          powerOn: _powerStateFromStatus(nextStatus),
        );
        final saved = await apiService.updateDeviceStatus(
          id: loaded.id,
          online: native.online,
          lastStatus: nextStatus,
          rawMetadata: nextMetadata,
          userId: selectedOwnerId.value,
        );
        merged = saved.copyWith(
          rawMetadata:
              saved.rawMetadata.isNotEmpty ? saved.rawMetadata : nextMetadata,
        );
        _deviceRefreshFailures.remove(loaded.id);
      }
      _upsertDevice(merged);
      if (!native.success) {
        _deviceRefreshFailures[loaded.id] = {
          'code': native.code,
          'message': native.message,
          'tuya_home_id': _tuyaHomeIdForDevice(loaded),
        };
        await _logDeviceControl(
          device: loaded,
          commandCode: 'status_refresh',
          commandValue: const <String, dynamic>{},
          success: false,
          errorCode: native.code,
          errorMessage: native.message,
        );
      }
      return merged;
    } finally {
      deviceDetailsBusyIds.remove(device.id);
    }
  }

  Future<bool> renameSmartDevice({
    required SmartDeviceModel device,
    required String name,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName == device.name) return false;

    deviceControlBusyIds.add(device.id);
    try {
      final native = await nativeService.renameDevice(
        tuyaDeviceId: device.tuyaDeviceId,
        name: cleanName,
      );
      if (!native.success) {
        await _logDeviceControl(
          device: device,
          commandCode: 'rename',
          commandValue: {'name': cleanName},
          success: false,
          errorCode: native.code,
          errorMessage: native.message,
        );
        errorMessage(formatVisibleError(
          'smartHomeRenameFailed'.tr,
          code: native.code,
          message: native.message,
        ));
        return false;
      }

      final updated = await apiService.renameDevice(
        id: device.id,
        name: cleanName,
        userId: selectedOwnerId.value,
      );
      _upsertDevice(updated);
      Get.snackbar('smartHomeRenameDevice'.tr, 'smartHomeDeviceRenamed'.tr);
      return true;
    } catch (e) {
      await _logDeviceControl(
        device: device,
        commandCode: 'rename',
        commandValue: {'name': cleanName},
        success: false,
        errorCode: 'rename_exception',
        errorMessage: e.toString(),
      );
      errorMessage(e.toString());
      return false;
    } finally {
      deviceControlBusyIds.remove(device.id);
    }
  }

  Future<bool> renameDeviceFunction({
    required SmartDeviceModel device,
    required SmartDeviceFunctionModel function,
    required String displayName,
  }) async {
    final cleanName = displayName.trim();
    if (cleanName.isEmpty || cleanName == function.displayName.trim()) {
      return false;
    }

    deviceControlBusyIds.add(device.id);
    try {
      final updated = await apiService.updateDeviceFunction(
        deviceId: device.id,
        functionId: function.id,
        displayName: cleanName,
        userId: selectedOwnerId.value,
      );
      _upsertDevice(_mergeDevicePreservingRuntimeData(device, updated));
      Get.snackbar(
        'smartHomeEditSwitchName'.tr,
        'smartHomeSwitchNameUpdated'.tr,
      );
      return true;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      deviceControlBusyIds.remove(device.id);
    }
  }

  Future<bool> updateDeviceFunctionSettings({
    required SmartDeviceModel device,
    required SmartDeviceFunctionModel function,
    String? displayName,
    int? sortOrder,
    bool? isVisible,
  }) async {
    deviceControlBusyIds.add(device.id);
    try {
      final updated = await apiService.updateDeviceFunction(
        deviceId: device.id,
        functionId: function.id,
        displayName: displayName?.trim(),
        sortOrder: sortOrder,
        isVisible: isVisible,
        userId: selectedOwnerId.value,
      );
      _upsertDevice(_mergeDevicePreservingRuntimeData(device, updated));
      return true;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      deviceControlBusyIds.remove(device.id);
    }
  }

  Future<bool> moveSmartDevice({
    required SmartDeviceModel device,
    required int? smartHomeId,
    required int? smartRoomId,
  }) async {
    deviceControlBusyIds.add(device.id);
    isRefreshing(true);
    try {
      final updated = await apiService.moveDevice(
        id: device.id,
        smartHomeId: smartHomeId,
        smartRoomId: smartRoomId,
        userId: selectedOwnerId.value,
      );
      _upsertDevice(updated);
      selectedLocationKey.value = smartHomeId == null
          ? smartHomeUnassignedLocationKey
          : 'home:$smartHomeId';
      selectedRoomId.value = smartRoomId;
      await _loadSelectedHomeData();
      _refreshLoadedDeviceStatusesInBackground();
      Get.snackbar('smartHomeMoveDevice'.tr, 'smartHomeDeviceMoved'.tr);
      return true;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      deviceControlBusyIds.remove(device.id);
      isRefreshing(false);
    }
  }

  Future<bool> deleteSmartDevice({
    required SmartDeviceModel device,
  }) async {
    deviceControlBusyIds.add(device.id);
    errorMessage('');
    try {
      final native = await nativeService.removeDevice(
        tuyaDeviceId: device.tuyaDeviceId,
        tuyaHomeId: _tuyaHomeIdForDevice(device),
      );
      final tuyaAlreadyGone =
          native.code == 'device_not_found' || native.code == '11002';
      if (!native.success && !tuyaAlreadyGone) {
        await _logDeviceControl(
          device: device,
          commandCode: 'delete_device',
          commandValue: {
            'device_id': device.tuyaDeviceId,
            'native_code': native.code,
            'native_message': native.message,
          },
          success: false,
          errorCode: native.code,
          errorMessage: native.message,
        );
        errorMessage(formatVisibleError(
          'smartHomeDeleteFailed'.tr,
          code: native.code,
          message: native.message,
        ));
        return false;
      }

      await _logDeviceControl(
        device: device,
        commandCode: 'delete_device',
        commandValue: {
          'device_id': device.tuyaDeviceId,
          'tuya_removed': native.success,
          'tuya_already_gone': tuyaAlreadyGone,
          'native_code': native.code,
          'native_message': native.message,
        },
        success: true,
      );
      await apiService.deleteDevice(
        id: device.id,
        userId: selectedOwnerId.value,
      );
      devices.removeWhere((item) => item.id == device.id);
      Get.snackbar('smartHomeDeleteDevice'.tr, 'smartHomeDeviceDeleted'.tr);
      return true;
    } catch (e) {
      await _logDeviceControl(
        device: device,
        commandCode: 'delete_device',
        commandValue: {
          'device_id': device.tuyaDeviceId,
          'exception_type': e.runtimeType.toString(),
        },
        success: false,
        errorCode: 'delete_exception',
        errorMessage: e.toString(),
      );
      errorMessage(e.toString());
      return false;
    } finally {
      deviceControlBusyIds.remove(device.id);
    }
  }

  Future<bool> setDeviceDps({
    required SmartDeviceModel device,
    required String commandCode,
    required dynamic value,
  }) async {
    if (commandCode.trim().isEmpty) {
      errorMessage('smartHomeNoPowerDps'.tr);
      return false;
    }

    deviceControlBusyIds.add(device.id);
    errorMessage('');
    try {
      final controlDevice = await _deviceWithFunctionMetadata(device);
      final function = DeviceCapabilityResolver.resolve(
        controlDevice,
        commandCode,
      );
      if (function == null) {
        final context = _controlErrorContext(
          device: controlDevice,
          requestedCode: commandCode,
          submittedValue: value,
        );
        await _logDeviceControl(
          device: controlDevice,
          commandCode: commandCode,
          commandValue: context,
          success: false,
          errorCode: 'unsupported_or_read_only_dp',
          errorMessage:
              'No writable Tuya function matched the requested capability.',
        );
        errorMessage(formatVisibleError(
          'smartHomeControlFailed'.tr,
          code: 'unsupported_or_read_only_dp',
          message: 'No writable Tuya function matched $commandCode',
        ));
        return false;
      }

      final validation = DeviceCapabilityResolver.validate(function, value);
      if (!validation.valid) {
        await _logDeviceControl(
          device: controlDevice,
          commandCode: function.code,
          commandValue: _controlErrorContext(
            device: controlDevice,
            requestedCode: commandCode,
            function: function,
            submittedValue: value,
          ),
          success: false,
          errorCode: 'invalid_dp_value',
          errorMessage: validation.message,
        );
        errorMessage(formatVisibleError(
          'smartHomeControlFailed'.tr,
          code: 'invalid_dp_value',
          message: validation.message,
        ));
        return false;
      }

      final command = TuyaValidatedCommand(
        function: function,
        value: validation.value,
      );
      final native = await nativeService.publishDps(
        tuyaDeviceId: controlDevice.tuyaDeviceId,
        tuyaHomeId: _tuyaHomeIdForDevice(controlDevice),
        dpId: function.dpId,
        code: function.code,
        type: function.type,
        value: command.value,
      );
      if (!native.success) {
        await _logDeviceControl(
          device: controlDevice,
          commandCode: function.code,
          commandValue: {
            ...command.toLogValue(),
            'native_code': native.code,
            'native_message': native.message,
          },
          success: false,
          errorCode: native.code,
          errorMessage: native.message,
        );
        errorMessage(formatVisibleError(
          'smartHomeControlFailed'.tr,
          code: native.code,
          message: native.message,
        ));
        return false;
      }

      final nextStatus =
          Map<String, dynamic>.from(DeviceCapabilityResolver.statusMap(
        controlDevice,
      ))
            ..addAll(native.dps.isNotEmpty ? native.dps : command.dps);
      final loggedDevice = await apiService.storeControlLog(
        id: controlDevice.id,
        commandCode: function.code,
        commandValue: command.toLogValue(),
        success: true,
        lastStatus: nextStatus,
        online: native.online || controlDevice.online,
        userId: selectedOwnerId.value,
      );
      final updated = (loggedDevice ?? controlDevice).copyWith(
        online: native.online || controlDevice.online,
        lastStatus: loggedDevice?.lastStatus.isNotEmpty == true
            ? loggedDevice!.lastStatus
            : nextStatus,
        rawMetadata: loggedDevice?.rawMetadata.isNotEmpty == true
            ? loggedDevice!.rawMetadata
            : (native.device.isNotEmpty
                ? native.device
                : controlDevice.rawMetadata),
        primaryPowerDp: function.dpId,
        powerOn: _powerStateFromStatus(nextStatus),
      );
      _upsertDevice(updated);
      return true;
    } catch (e) {
      await _logDeviceControl(
        device: device,
        commandCode: commandCode,
        commandValue: _controlErrorContext(
          device: device,
          requestedCode: commandCode,
          submittedValue: value,
          exception: e,
        ),
        success: false,
        errorCode: 'control_exception',
        errorMessage: e.toString(),
      );
      errorMessage(e.toString());
      return false;
    } finally {
      deviceControlBusyIds.remove(device.id);
    }
  }

  Future<bool> setDevicePower({
    required SmartDeviceModel device,
    required bool powerOn,
  }) async {
    final controlDevice = await _deviceWithFunctionMetadata(device);
    final function = DeviceCapabilityResolver.resolvePower(controlDevice);
    if (function == null) {
      final refreshFailure = _deviceRefreshFailures[controlDevice.id];
      errorMessage('smartHomeNoPowerDps'.tr);
      await _logDeviceControl(
        device: controlDevice,
        commandCode: 'power',
        commandValue: _controlErrorContext(
          device: controlDevice,
          requestedCode: 'power',
          submittedValue: powerOn,
          refreshFailure: refreshFailure,
        ),
        success: false,
        errorCode: refreshFailure == null
            ? 'missing_writable_power_function'
            : 'missing_writable_power_function_after_refresh_failure',
        errorMessage: refreshFailure == null
            ? 'No writable boolean Tuya function was found for power control.'
            : 'No writable boolean Tuya function was found because device schema refresh failed.',
      );
      return false;
    }

    return setDeviceDps(
      device: controlDevice,
      commandCode: function.code,
      value: powerOn,
    );
  }

  Future<SmartDeviceModel> _deviceWithFunctionMetadata(
    SmartDeviceModel device,
  ) async {
    if (DeviceCapabilityResolver.functions(device).isNotEmpty) return device;
    return loadDeviceDetails(device);
  }

  Future<void> refreshLoadedDeviceStatuses() async {
    if (!nativeStatus.value.initialized || !isTuyaUserLinked) return;
    final snapshot = devices.toList(growable: false);
    for (final device in snapshot) {
      if (device.tuyaDeviceId.trim().isEmpty) continue;
      final tuyaHomeId = _tuyaHomeIdForDevice(device);
      if (tuyaHomeId.trim().isEmpty) continue;
      try {
        final native = await nativeService.getDeviceStatus(
          tuyaDeviceId: device.tuyaDeviceId,
          tuyaHomeId: tuyaHomeId,
        );
        if (!native.success) {
          _deviceRefreshFailures[device.id] = {
            'code': native.code,
            'message': native.message,
            'tuya_home_id': tuyaHomeId,
          };
          continue;
        }

        final nextStatus =
            native.dps.isNotEmpty ? native.dps : device.lastStatus;
        final nextMetadata =
            native.device.isNotEmpty ? native.device : device.rawMetadata;
        final saved = await apiService.updateDeviceStatus(
          id: device.id,
          online: native.online,
          lastStatus: nextStatus,
          rawMetadata: nextMetadata,
          userId: selectedOwnerId.value,
        );
        _upsertDevice(saved.copyWith(
          online: native.online,
          lastStatus:
              saved.lastStatus.isNotEmpty ? saved.lastStatus : nextStatus,
          rawMetadata:
              saved.rawMetadata.isNotEmpty ? saved.rawMetadata : nextMetadata,
          primaryPowerDp: _powerDpFromStatus(nextStatus),
          powerOn: _powerStateFromStatus(nextStatus),
        ));
        _deviceRefreshFailures.remove(device.id);
      } catch (_) {
        // Dashboard loading should stay responsive if one device cannot refresh.
      }
    }
  }

  void _refreshLoadedDeviceStatusesInBackground() {
    refreshLoadedDeviceStatuses().catchError((_) {
      // Native status refresh is best-effort and must not block UI updates.
    });
  }

  String _tuyaHomeIdForDevice(SmartDeviceModel device) {
    final home =
        homes.firstWhereOrNull((item) => item.id == device.smartHomeId);
    return home?.tuyaHomeId ?? selectedHome?.tuyaHomeId ?? '';
  }

  Map<String, dynamic> _controlErrorContext({
    required SmartDeviceModel device,
    required String requestedCode,
    required dynamic submittedValue,
    TuyaDeviceFunction? function,
    Object? exception,
    Map<String, dynamic>? refreshFailure,
  }) {
    return {
      'device_id': device.tuyaDeviceId,
      'product_id': device.tuyaProductId,
      'category': device.category,
      'requested_code': requestedCode,
      'submitted_value': submittedValue,
      'submitted_value_type': submittedValue.runtimeType.toString(),
      if (function != null) ...function.toLogValue(submittedValue),
      if (exception != null) 'exception_type': exception.runtimeType.toString(),
      if (refreshFailure != null) 'last_status_refresh_error': refreshFailure,
      'functions': DeviceCapabilityResolver.debugSummary(device)['functions'],
    };
  }

  Future<void> _logDeviceControl({
    required SmartDeviceModel device,
    required String commandCode,
    required Map<String, dynamic> commandValue,
    required bool success,
    String? errorCode,
    String? errorMessage,
  }) async {
    try {
      await apiService.storeControlLog(
        id: device.id,
        commandCode: commandCode,
        commandValue: commandValue,
        success: success,
        errorCode: errorCode,
        errorMessage: errorMessage,
        userId: selectedOwnerId.value,
      );
    } catch (_) {
      // Logging must not block the customer flow.
    }
  }

  void _upsertDevice(SmartDeviceModel device) {
    final index = devices.indexWhere((item) => item.id == device.id);
    if (index >= 0) {
      devices[index] = device;
    } else {
      devices.add(device);
    }
  }

  SmartDeviceModel _mergeDevicePreservingRuntimeData(
    SmartDeviceModel current,
    SmartDeviceModel updated,
  ) {
    final existing = devices.firstWhereOrNull((item) => item.id == updated.id);
    final fallback = existing ?? current;
    final updatedHasSchema =
        DeviceCapabilityResolver.functions(updated).isNotEmpty;
    return updated.copyWith(
      lastStatus: updated.lastStatus.isNotEmpty
          ? updated.lastStatus
          : fallback.lastStatus,
      rawMetadata:
          updatedHasSchema ? updated.rawMetadata : fallback.rawMetadata,
      functions:
          updated.functions.isNotEmpty ? updated.functions : fallback.functions,
      primaryPowerDp: updated.primaryPowerDp.isNotEmpty
          ? updated.primaryPowerDp
          : fallback.primaryPowerDp,
      powerOn: updated.powerOn ?? fallback.powerOn,
    );
  }

  String _powerDpFromStatus(Map<String, dynamic> status) {
    for (final key in const ['switch_led', 'switch', 'power', '1']) {
      if (status.containsKey(key)) return key;
    }
    for (final entry in status.entries) {
      if (entry.value is bool) return entry.key;
    }
    return '';
  }

  bool? _powerStateFromStatus(Map<String, dynamic> status) {
    final dp = _powerDpFromStatus(status);
    final value = dp.isEmpty ? null : status[dp];
    return value is bool ? value : null;
  }

  Future<void> _logEvent({
    int? smartHomeId,
    required String event,
    required bool success,
    String? errorCode,
    String? message,
    Map<String, dynamic>? context,
  }) async {
    try {
      await apiService.storeEventLog(
        smartHomeId: smartHomeId,
        event: event,
        success: success,
        errorCode: errorCode,
        message: message,
        context: context,
      );
    } catch (_) {
      // Logging must not block the customer flow.
    }
  }

  Future<void> _loadSelectedHomeData() async {
    if (isUnassignedSelected) {
      rooms.clear();
      final loadedDevices = await apiService.getDevices(
        unassigned: true,
        userId: selectedOwnerId.value,
      );
      devices.assignAll(loadedDevices);
      return;
    }

    final home = selectedHome;
    if (home == null) {
      rooms.clear();
      devices.clear();
      return;
    }
    final loadedRooms = await apiService.getRooms(
      home.id,
      userId: selectedOwnerId.value,
    );
    final loadedDevices = await apiService.getDevices(
      homeId: home.id,
      userId: selectedOwnerId.value,
    );
    rooms.assignAll(loadedRooms);
    devices.assignAll(loadedDevices);
  }

  void _ensureSelectedLocation() {
    if (selectedLocationKey.value == smartHomeUnassignedLocationKey) return;
    final selectedId = selectedLocationKey.value.startsWith('home:')
        ? int.tryParse(selectedLocationKey.value.substring(5))
        : null;
    final stillExists =
        selectedId != null && homes.any((home) => home.id == selectedId);
    if (stillExists) return;
    final next = homes.firstWhereOrNull((home) => home.isDefault) ??
        (homes.isNotEmpty ? homes.first : null);
    selectedLocationKey.value =
        next == null ? smartHomeUnassignedLocationKey : 'home:${next.id}';
    selectedRoomId.value = null;
  }
}
