import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/admin/notifications/presentation/controllers/admin_notification_badge_controller.dart';
import '../../features/common_feature/data/repositories/common_repo_impl.dart';
import '../../features/common_feature/domain/usecases/get_user_data_usecase.dart';
import '../../features/common_feature/domain/usecases/user_profile_usecase.dart';
import '../../features/common_feature/presentation/personal_details/controllers/personal_details_controller.dart';
import '../../firebase_options.dart';
import '../connection/network_info.dart';
import 'app_dependency_registry.dart';
import 'notification_firebase_service.dart';
import 'user_data.dart';

String userType = '';
RxBool startApp = true.obs;
bool supabase = true;
List<int> employeePermissions = [];
String userName = '';

class InitialBindings implements Bindings {
  @override
  void dependencies() async {
    // Must run synchronously first — GetX does not wait for async bindings.
    AppDependencyRegistry.registerAll();

    final networkInfo = NetworkInfo();
    final connected = await networkInfo.isConnected;

    if (kIsWeb) {
      startApp.value = true;
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[FCM] Firebase initialized');
      await NotificationFirebaseService.instance.ensureInitialized();
      final doc =
          await FirebaseFirestore.instance.collection('Test').doc('Test').get();
      final bool? value = doc.data()?['Test'] as bool?;
      startApp.value = value ?? true;
    }

    await initializeDateFormatting();
    await Supabase.initialize(
      url: 'https://tigmezfjgepmzuefrogq.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpZ21lemZqZ2VwbXp1ZWZyb2dxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1MzMxNzMsImV4cCI6MjA3NTEwOTE3M30.xaocus3WHvIjcgJdocAdJYippiBFGwzr4zFymlsIDbE',
    );
    final supabaseClient = Supabase.instance.client;
    final response = await supabaseClient
        .from('doctor_bike')
        .select('status')
        .limit(1)
        .maybeSingle();
    supabase = response!['status'] == true;

    final userdata = await UserData.getSavedUser();
    if (userdata != null) {
      employeePermissions
        ..clear()
        ..addAll(userdata.employeePermissions.map((p) => p.permissionId));
      userType = userdata.user.type;
      userName = userdata.user.name;

      if (userdata.user.type == 'admin') {
        if (!Get.isRegistered<AdminNotificationBadgeController>()) {
          Get.put(AdminNotificationBadgeController(), permanent: true);
        }
        Get.find<AdminNotificationBadgeController>().refresh();
        await NotificationFirebaseService.instance
            .registerAdminDeviceTokenIfReady(source: 'app_resume');
      }
    }

    if (UserData.userToken.isNotEmpty) {
      if (!Get.isRegistered<PersonalDetailsController>()) {
        Get.put(
          PersonalDetailsController(
            userProfileUseCase: UserProfileUseCase(
              commonRepository: Get.find<CommonImplement>(),
            ),
            getUserDataUsecase: GetUserDataUsecase(
              commonRepository: Get.find<CommonImplement>(),
            ),
          ),
        ).getUserData();
      }
    }
  }
}
