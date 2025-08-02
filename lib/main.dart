import 'package:doctorbike/core/services/user_data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'core/services/languague_service.dart';
import 'core/services/notification_firebase_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/translations_service.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'core/services/initial_bindings.dart';
import 'core/theme/themes.dart';
import 'core/utils/screen_util_new.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationFirebaseService.instance.intNotification();
  await initializeDateFormatting(); // لجميع اللغات المدعومة
  print('FCM Token: ${NotificationFirebaseService.instance.finalToken}');
  final userToken = await UserData.getUserToken();
  print('User Token: $userToken');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ScreenUtilNew.init(context);

    return ScreenUtilInit(
      builder: (_, __) {
        return GetMaterialApp(
          title: 'Doctorbike',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          translations: Translation(),
          locale: Locale(
              Get.put<LanguageController>(LanguageController()).getLang()),
          fallbackLocale: const Locale('en'),
          initialBinding: InitialBindings(),
          initialRoute: AppRoutes.SPLASHSCREEN,
          getPages: AppPages.pages,
          builder: (_, child) {
            return child!;
          },
        );
      },
      designSize: const Size(430, 932),
    );
  }
}
