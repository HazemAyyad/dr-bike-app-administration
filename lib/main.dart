import 'dart:io';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'core/services/desktop_window_service.dart';
import 'core/services/fcm_background_handler.dart';
import 'core/services/languague_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/translations_service.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'core/services/initial_bindings.dart';
import 'core/theme/themes.dart';
import 'core/utils/screen_util_new.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    DesktopWindowService.debugLog(
      'FlutterError ${details.exceptionAsString()}\n${details.stack}',
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    DesktopWindowService.debugLog('PlatformError $error\n$stack');
    return false;
  };
  DesktopWindowService.debugLog(
    'main start exe="${!kIsWeb ? Platform.resolvedExecutable : 'web'}" '
    'cwd="${!kIsWeb ? Directory.current.path : 'web'}" args=$args',
  );
  if (!kIsWeb && !DesktopWindowService.isSupported) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // FCM يُهيّأ بعد أول إطار (Splash) — تجنّب شاشة بيضاء قبل runApp
  }
  await GetStorage.init();
  final desktopLaunch = DesktopWindowService.parseLaunchArgs(args);
  DesktopWindowService.setInitialLaunch(desktopLaunch);
  DesktopWindowService.debugLog(
    'main launch route="${desktopLaunch?.route}" title="${desktopLaunch?.title}"',
  );

  final binding = WidgetsFlutterBinding.ensureInitialized();
  // ignore: deprecated_member_use
  final window = binding.window;
  final physical = window.physicalSize;
  final dpr = window.devicePixelRatio > 0 ? window.devicePixelRatio : 1.0;
  final rawW = physical.width / dpr;
  final rawH = physical.height / dpr;
  // Cold start on some devices reports 0×0 — breaks ScreenUtil (.w → 0) and layout.
  final width = rawW > 0 ? rawW : 390.0;
  final height = rawH > 0 ? rawH : 844.0;

  runApp(
    // DevicePreview(
    // enabled: kDebugMode,
    // builder: (_) =>
    MyApp(designSize: Size(width, height)),
    // ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.designSize,
  }) : super(key: key);

  final Size designSize;
  @override
  Widget build(BuildContext context) {
    ScreenUtilNew.init(context);

    return ScreenUtilInit(
      builder: (_, __) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
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
          defaultTransition: Transition.noTransition,
          transitionDuration: Duration.zero,
          builder: (context, child) {
            final media = MediaQuery.maybeOf(context);
            if (media == null) return child!;
            return MediaQuery(
              data: media.copyWith(
                accessibleNavigation: true,
                disableAnimations: true,
              ),
              child: child!,
            );
          },
        );
      },
      minTextAdapt: true,
      splitScreenMode: true,
      designSize: designSize,
    );
  }
}
