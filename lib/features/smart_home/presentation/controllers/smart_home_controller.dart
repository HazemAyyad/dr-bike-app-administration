import 'dart:async';

import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/final_classes.dart';
import '../../../../core/services/initial_bindings.dart';
import '../../data/smart_home_api_service.dart';
import '../../data/smart_home_native_service.dart';

const Duration _smartHomePairingTimeout = Duration(seconds: 150);
const String _smartHomeWifiSsidKey = 'smart_home_wifi_ssid';
const String _smartHomeWifiPasswordKey = 'smart_home_wifi_password';

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
  bool get canViewSmartHomeOwners => userType == 'admin';
  SmartHomeOwnerModel? get selectedOwner => selectedOwnerId.value == null
      ? null
      : owners.firstWhereOrNull((owner) => owner.id == selectedOwnerId.value);

  String formatVisibleError(String fallback, {String? code, String? message}) {
    final parts = <String>[fallback];
    if (code != null && code.isNotEmpty) parts.add('[]');
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
      tuyaUser.value = await apiService.getTuyaUser();
      await ensureTuyaUserLinked();

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

  Future<void> selectOwner(int? ownerId) async {
    if (!canViewSmartHomeOwners || selectedOwnerId.value == ownerId) return;
    selectedOwnerId.value = ownerId;
    await refreshData();
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
      final loaded = await apiService.getDevice(device.id);
      final native = await nativeService.getDeviceStatus(
        tuyaDeviceId: loaded.tuyaDeviceId,
      );
      final merged = native.success
          ? loaded.copyWith(
              online: native.online,
              lastStatus:
                  native.dps.isNotEmpty ? native.dps : loaded.lastStatus,
              rawMetadata:
                  native.device.isNotEmpty ? native.device : loaded.rawMetadata,
              primaryPowerDp: _powerDpFromStatus(
                native.dps.isNotEmpty ? native.dps : loaded.lastStatus,
              ),
              powerOn: _powerStateFromStatus(
                native.dps.isNotEmpty ? native.dps : loaded.lastStatus,
              ),
            )
          : loaded;
      _upsertDevice(merged);
      if (!native.success) {
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

      final updated =
          await apiService.renameDevice(id: device.id, name: cleanName);
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

  Future<bool> setDeviceDps({
    required SmartDeviceModel device,
    required String commandCode,
    required dynamic value,
  }) async {
    if (canViewSmartHomeOwners && selectedOwnerId.value != null) {
      errorMessage('smartHomeAdminReadOnly'.tr);
      return false;
    }
    if (commandCode.trim().isEmpty) {
      errorMessage('smartHomeNoPowerDps'.tr);
      return false;
    }

    final command = <String, dynamic>{commandCode: value};
    deviceControlBusyIds.add(device.id);
    errorMessage('');
    try {
      final native = await nativeService.publishDps(
        tuyaDeviceId: device.tuyaDeviceId,
        dps: command,
      );
      if (!native.success) {
        await _logDeviceControl(
          device: device,
          commandCode: commandCode,
          commandValue: command,
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

      final nextStatus = Map<String, dynamic>.from(device.lastStatus)
        ..addAll(native.dps.isNotEmpty ? native.dps : command);
      final loggedDevice = await apiService.storeControlLog(
        id: device.id,
        commandCode: commandCode,
        commandValue: command,
        success: true,
        lastStatus: nextStatus,
        online: native.online || device.online,
      );
      final updated = loggedDevice ??
          device.copyWith(
            online: native.online || device.online,
            lastStatus: nextStatus,
            primaryPowerDp: _powerDpFromStatus(nextStatus),
            powerOn: _powerStateFromStatus(nextStatus),
          );
      _upsertDevice(updated);
      return true;
    } catch (e) {
      await _logDeviceControl(
        device: device,
        commandCode: commandCode,
        commandValue: command,
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
    if (canViewSmartHomeOwners && selectedOwnerId.value != null) {
      errorMessage('smartHomeAdminReadOnly'.tr);
      return false;
    }

    final dp = device.primaryPowerDp.isNotEmpty
        ? device.primaryPowerDp
        : _powerDpFromStatus(device.lastStatus);
    if (dp.isEmpty) {
      errorMessage('smartHomeNoPowerDps'.tr);
      await _logDeviceControl(
        device: device,
        commandCode: 'power',
        commandValue: {'power': powerOn},
        success: false,
        errorCode: 'missing_power_dp',
        errorMessage: 'No boolean Tuya DPS was found for power control.',
      );
      return false;
    }

    final command = <String, dynamic>{dp: powerOn};
    deviceControlBusyIds.add(device.id);
    errorMessage('');
    try {
      final native = await nativeService.publishDps(
        tuyaDeviceId: device.tuyaDeviceId,
        dps: command,
      );
      if (!native.success) {
        await _logDeviceControl(
          device: device,
          commandCode: dp,
          commandValue: command,
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

      final nextStatus = Map<String, dynamic>.from(device.lastStatus)
        ..addAll(native.dps.isNotEmpty ? native.dps : command);
      final loggedDevice = await apiService.storeControlLog(
        id: device.id,
        commandCode: dp,
        commandValue: command,
        success: true,
        lastStatus: nextStatus,
        online: native.online || device.online,
      );
      final updated = loggedDevice ??
          device.copyWith(
            online: native.online || device.online,
            lastStatus: nextStatus,
            primaryPowerDp: dp,
            powerOn: powerOn,
          );
      _upsertDevice(updated);
      return true;
    } catch (e) {
      await _logDeviceControl(
        device: device,
        commandCode: dp,
        commandValue: command,
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
}
