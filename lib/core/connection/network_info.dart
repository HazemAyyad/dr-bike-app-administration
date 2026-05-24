import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  final Connectivity _connectivity = Connectivity();

  Future<bool> get isConnected async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();

    if (results.isEmpty) {
      return _probeReachability();
    }

    if (results.any((r) => r != ConnectivityResult.none)) {
      return true;
    }

    // connectivity_plus often reports "none" while Wi‑Fi/data still works.
    return _probeReachability();
  }

  Future<bool> _probeReachability() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }
}


// تحديث حالة الاتصال بالانترنت بالوقت الحالي 

// class NetworkInfo {
//   final Connectivity _connectivity = Connectivity();
//   late StreamSubscription<List<ConnectivityResult>> subscription;

//   RxBool isOnline = false.obs;
//   RxString connectionStatus = 'جاري التحقق...'.obs;

//   NetworkInfo() {
//     subscription = _connectivity.onConnectivityChanged.listen((results) {
//       _onConnectivityChanged(results.first);
//     });
//     // تحقق أولي عند البداية
//     _checkInitialConnection();
//   }

//   void _onConnectivityChanged(ConnectivityResult result) {
//     final connected = result != ConnectivityResult.none;
//     isOnline.value = connected;
//     connectionStatus.value =
//         connected ? 'متصل بالإنترنت' : 'غير متصل بالإنترنت';
//   }

//   Future<void> _checkInitialConnection() async {
//     final results = await _connectivity.checkConnectivity();
//     _onConnectivityChanged(results.first);
//   }

//   void dispose() {
//     subscription.cancel();
//   }
// }
