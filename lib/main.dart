import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'core/services/languague_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/translations_service.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'core/services/initial_bindings.dart';
import 'core/theme/themes.dart';
import 'core/utils/screen_util_new.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  final binding = WidgetsFlutterBinding.ensureInitialized();
  final window = binding.window;
  final width = window.physicalSize.width / window.devicePixelRatio;
  final height = window.physicalSize.height / window.devicePixelRatio;

  runApp(
    DevicePreview(
      enabled: kDebugMode,
      builder: (_) => MyApp(designSize: Size(width, height)),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.designSize}) : super(key: key);

  final Size designSize;
  @override
  Widget build(BuildContext context) {
    ScreenUtilNew.init(context);

    return ScreenUtilInit(
      builder: (_, __) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          translations: Translation(),
          locale: Locale(
            Get.put<LanguageController>(LanguageController()).getLang(),
          ),
          fallbackLocale: const Locale('en'),
          initialBinding: InitialBindings(),
          initialRoute: AppRoutes.SPLASHSCREEN,
          getPages: AppPages.pages,
          builder: (_, child) {
            return child!;
          },
        );
      },
      minTextAdapt: true,
      splitScreenMode: true,
      designSize: designSize,
    );
  }
}
