import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../routes/app_routes.dart';

class DesktopWindowLaunch {
  const DesktopWindowLaunch({
    required this.route,
    this.title,
  });

  final String route;
  final String? title;
}

class DesktopWindowService {
  DesktopWindowService._();

  static const routeArg = '--desktop-route=';
  static const titleArg = '--desktop-title=';
  static DesktopWindowLaunch? _initialLaunch;
  static bool _startedAsSecondaryWindow = false;

  static String get debugLogPath {
    final temp = Directory.systemTemp.path;
    return '$temp${Platform.pathSeparator}doctorbike_desktop_windows.log';
  }

  static bool get isSupported {
    return !kIsWeb && Platform.isWindows;
  }

  static DesktopWindowLaunch? parseLaunchArgs(List<String> args) {
    String? route;
    String? title;
    for (final arg in args) {
      if (arg.startsWith(routeArg)) {
        route = Uri.decodeComponent(arg.substring(routeArg.length));
      } else if (arg.startsWith(titleArg)) {
        title = Uri.decodeComponent(arg.substring(titleArg.length));
      }
    }
    if (route == null || route.isEmpty) return null;
    return DesktopWindowLaunch(route: route, title: title);
  }

  static bool isSecondaryDesktopWindow(List<String> args) {
    return parseLaunchArgs(args) != null;
  }

  static void setInitialLaunch(DesktopWindowLaunch? launch) {
    _initialLaunch = launch;
    _startedAsSecondaryWindow = launch != null;
  }

  static bool get startedAsSecondaryWindow => _startedAsSecondaryWindow;

  static void debugLog(String message) {
    final line = '[${DateTime.now().toIso8601String()}] $message';
    debugPrint('[DesktopWindow] $message');
    try {
      File(debugLogPath).writeAsStringSync(
        '$line\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Best-effort diagnostic logging only.
    }
  }

  static DesktopWindowLaunch? consumeInitialLaunch() {
    final launch = _initialLaunch;
    _initialLaunch = null;
    return launch;
  }

  static Future<bool> openRoute({
    required String route,
    String? title,
  }) async {
    if (!isSupported || route.isEmpty || route == AppRoutes.SPLASHSCREEN) {
      debugLog('openRoute skipped route="$route" supported=$isSupported');
      return false;
    }

    final executable = Platform.resolvedExecutable;
    final workingDirectory = File(executable).parent.path;
    final arguments = [
      '$routeArg${Uri.encodeComponent(route)}',
      if (title != null && title.trim().isNotEmpty)
        '$titleArg${Uri.encodeComponent(title.trim())}',
    ];

    debugLog(
      'openRoute starting exe="$executable" cwd="$workingDirectory" args=$arguments',
    );

    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.inheritStdio,
    );
    debugLog('openRoute started pid=${process.pid}');
    return true;
  }
}
