import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../databases/api/dio_consumer.dart';
import '../databases/api/end_points.dart';
import 'final_classes.dart';
import 'initial_bindings.dart';

class EmployeeWifiPresenceService {
  EmployeeWifiPresenceService._();

  static final EmployeeWifiPresenceService instance =
      EmployeeWifiPresenceService._();

  static const Duration _interval = Duration(seconds: 45);
  static const MethodChannel _nativeChannel =
      MethodChannel('dr_bike/employee_wifi_presence');

  final NetworkInfo _networkInfo = NetworkInfo();
  Timer? _timer;
  bool _running = false;
  bool _sending = false;

  Future<WifiPresencePermissionState> checkRequiredPermissions({
    bool request = false,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return const WifiPresencePermissionState.ready();
    }

    var location = await Permission.locationWhenInUse.status;
    if (request &&
        !location.isGranted &&
        !location.isLimited &&
        !location.isPermanentlyDenied) {
      location = await Permission.locationWhenInUse.request();
    }

    var notification = PermissionStatus.granted;
    if (Platform.isAndroid) {
      notification = await Permission.notification.status;
      if (request &&
          !notification.isGranted &&
          !notification.isPermanentlyDenied) {
        notification = await Permission.notification.request();
      }
    }

    final locationService = await Permission.locationWhenInUse.serviceStatus;
    return WifiPresencePermissionState(
      locationGranted: location.isGranted || location.isLimited,
      notificationGranted: notification.isGranted,
      locationServiceEnabled: !Platform.isAndroid || locationService.isEnabled,
      locationPermanentlyDenied: location.isPermanentlyDenied,
      notificationPermanentlyDenied: notification.isPermanentlyDenied,
    );
  }

  Future<void> openPermissionSettings() => openAppSettings();

  void start() {
    if (userType != 'employee' || _running) return;
    _running = true;
    _startAfterInitialSend();
    _timer = Timer.periodic(_interval, (_) {
      sendOnce();
    });
  }

  Future<void> _startAfterInitialSend() async {
    await sendOnce();
    await _startNativeForegroundService();
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> stopNative() async {
    stop();
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _nativeChannel.invokeMethod<bool>('stop');
    } catch (_) {}
  }

  Future<void> _startNativeForegroundService() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final token = await _readToken();
      if (token.isEmpty) return;
      await _nativeChannel.invokeMethod<bool>('start', {
        'baseUrl': EndPoints.baserUrl,
        'token': token,
      });
    } catch (_) {}
  }

  Future<String> _readToken() async {
    var token = await FinalClasses.secureStorage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      token =
          FinalClasses.getStorage.read('auth_token_backup')?.toString() ?? '';
    }
    return token;
  }

  Future<void> sendOnce() async {
    if (userType != 'employee' || _sending) return;
    _sending = true;
    try {
      final status = await _readWifiStatus();
      if (!Get.isRegistered<DioConsumer>()) return;
      await Get.find<DioConsumer>().post(
        EndPoints.employeeWifiPresence,
        data: {
          'connected': status.connected,
          'network_connected': status.networkConnected,
          'connection_type': status.connectionType,
          if (status.ssid != null) 'ssid': status.ssid,
        },
      );
    } catch (_) {
      // Presence is best-effort; UI will turn stale/red if heartbeats stop.
    } finally {
      _sending = false;
    }
  }

  Future<_WifiPresencePayload> _readWifiStatus() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return const _WifiPresencePayload(
        connected: false,
        networkConnected: false,
        connectionType: 'none',
      );
    }

    final connectivity = await Connectivity().checkConnectivity();
    final hasNetwork = connectivity.any(
      (result) => result != ConnectivityResult.none,
    );
    final isWifi = connectivity.contains(ConnectivityResult.wifi);
    if (!isWifi) {
      return _WifiPresencePayload(
        connected: false,
        networkConnected: hasNetwork,
        connectionType: hasNetwork ? 'mobile' : 'none',
      );
    }

    if (Platform.isAndroid) {
      final granted = await _ensureLocationPermission();
      if (!granted) {
        return _WifiPresencePayload(
          connected: false,
          networkConnected: hasNetwork,
          connectionType: hasNetwork ? 'wifi' : 'none',
        );
      }
    }

    final rawSsid = await _networkInfo.getWifiName();
    final ssid = _normalizeSsid(rawSsid);
    return _WifiPresencePayload(
      connected: ssid != null,
      networkConnected: hasNetwork,
      connectionType: hasNetwork ? 'wifi' : 'none',
      ssid: ssid,
    );
  }

  Future<bool> _ensureLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted || status.isLimited) return true;
    final requested = await Permission.locationWhenInUse.request();
    return requested.isGranted || requested.isLimited;
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
}

class WifiPresencePermissionState {
  const WifiPresencePermissionState({
    required this.locationGranted,
    required this.notificationGranted,
    required this.locationServiceEnabled,
    this.locationPermanentlyDenied = false,
    this.notificationPermanentlyDenied = false,
  });

  const WifiPresencePermissionState.ready()
      : locationGranted = true,
        notificationGranted = true,
        locationServiceEnabled = true,
        locationPermanentlyDenied = false,
        notificationPermanentlyDenied = false;

  final bool locationGranted;
  final bool notificationGranted;
  final bool locationServiceEnabled;
  final bool locationPermanentlyDenied;
  final bool notificationPermanentlyDenied;

  bool get ready =>
      locationGranted && notificationGranted && locationServiceEnabled;

  bool get needsSettings =>
      locationPermanentlyDenied ||
      notificationPermanentlyDenied ||
      !locationServiceEnabled;
}

class _WifiPresencePayload {
  const _WifiPresencePayload({
    required this.connected,
    required this.networkConnected,
    required this.connectionType,
    this.ssid,
  });

  final bool connected;
  final bool networkConnected;
  final String connectionType;
  final String? ssid;
}
