import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  final Connectivity _connectivity = Connectivity();

  Future<bool> get isConnected async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    if (results.isEmpty) {
      return true;
    }
    return results.any((r) => r != ConnectivityResult.none);
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
